-- Área 2 · Issue #47 · RN-A2-02, RN-A2-03
-- Qué hace: fn_recalcular_factura sobre detalle_factura. Al insertar, editar o borrar un renglón recalcula
-- subtotal, iva y valor_total de la factura afectada. Corre AFTER, así que si tg_salida_producto del área 3
-- rechaza el renglón por stock, la factura no cambia.

CREATE OR REPLACE FUNCTION fn_recalcular_factura() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_id INT; v_sub DECIMAL(14,2); v_iva DECIMAL(12,2);
BEGIN
    -- Recalcula la factura afectada. Si un UPDATE movió el renglón de factura, recalcula las dos.
    FOR v_id IN
        SELECT DISTINCT x FROM unnest(ARRAY[
            CASE WHEN TG_OP <> 'DELETE' THEN NEW.id_factura END,
            CASE WHEN TG_OP <> 'INSERT' THEN OLD.id_factura END
        ]) AS x WHERE x IS NOT NULL
    LOOP
        SELECT COALESCE(SUM(importe), 0) INTO v_sub FROM detalle_factura WHERE id_factura = v_id;
        v_iva := ROUND(v_sub * fn_tasa_iva(), 2);                                            -- RN-A2-03
        UPDATE facturas
           SET subtotal = v_sub, iva = v_iva, valor_total = v_sub + v_iva                    -- RN-A2-02
         WHERE id_factura = v_id;
    END LOOP;
    RETURN NULL;
END; $$;

CREATE TRIGGER tg_recalcular_factura
AFTER INSERT OR UPDATE OR DELETE ON detalle_factura
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_factura();
