-- Área 2 · Issue #48 · RN-A2-04, RN-A2-08, RN-A2-12
-- Qué hace: fn_estado_pago_factura (fecha_cobro automática al pasar a PAGADO, bloqueo de PAGADO con total 0)
-- y fn_bloquea_detalle_cerrado (renglones inmutables en facturas PAGADO o CANCELADO).

CREATE OR REPLACE FUNCTION fn_estado_pago_factura() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.estado_pago = 'PAGADO' AND NEW.valor_total = 0 THEN
        RAISE EXCEPTION 'RN-A2-04: la factura % no tiene renglones; no puede marcarse como PAGADO', NEW.folio;
    END IF;
    IF NEW.estado_pago = 'PAGADO' AND (OLD.estado_pago IS DISTINCT FROM 'PAGADO') THEN
        NEW.fecha_cobro := COALESCE(NEW.fecha_cobro, CURRENT_DATE);                          -- RN-A2-08
    ELSIF NEW.estado_pago IN ('PENDIENTE', 'PARCIAL') THEN
        NEW.fecha_cobro := NULL;                                                             -- RN-A2-08
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_estado_pago_factura BEFORE UPDATE OF estado_pago ON facturas
FOR EACH ROW EXECUTE FUNCTION fn_estado_pago_factura();

-- RN-A2-12: los renglones de una factura cerrada no se tocan; cualquier corrección es una factura nueva
CREATE OR REPLACE FUNCTION fn_bloquea_detalle_cerrado() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_estado estado_pago; v_folio VARCHAR;
BEGIN
    SELECT estado_pago, folio INTO v_estado, v_folio
      FROM facturas WHERE id_factura = COALESCE(NEW.id_factura, OLD.id_factura);
    IF v_estado IN ('PAGADO', 'CANCELADO') THEN
        RAISE EXCEPTION 'RN-A2-12: la factura % está %; sus renglones no se modifican', v_folio, v_estado;
    END IF;
    RETURN COALESCE(NEW, OLD);
END; $$;
CREATE TRIGGER tg_bloquea_detalle_cerrado BEFORE INSERT OR UPDATE OR DELETE ON detalle_factura
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_detalle_cerrado();
