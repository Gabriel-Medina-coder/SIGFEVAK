-- Área 1 · Issue #27 · RN-A1-04, RN-A1-05, RN-A1-06, RN-A1-18
-- Qué hace: fn_valida_entrada, que corre antes que el trigger del área 3 al insertar en entradas_producto:
-- almacén de producto terminado, lote del mismo producto, copia del nombre del proveedor y documento de respaldo.

CREATE OR REPLACE FUNCTION fn_valida_entrada()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_tipo        tipo_almacen;
    v_prod_lote   INT;
    v_nombre_prov VARCHAR;
BEGIN
    -- RN-A1-06: la entrada de producto terminado solo va a un almacén PRODUCTO_TERMINADO
    IF NEW.id_almacen IS NOT NULL THEN
        SELECT tipo INTO v_tipo FROM almacenes WHERE id_almacen = NEW.id_almacen;
        IF v_tipo IS DISTINCT FROM 'PRODUCTO_TERMINADO' THEN
            RAISE EXCEPTION 'RN-A1-06: el almacén % no es de producto terminado', NEW.id_almacen;
        END IF;
    END IF;

    -- RN-A1-05: el lote pertenece al mismo producto
    IF NEW.id_lote IS NOT NULL THEN
        SELECT id_producto INTO v_prod_lote FROM lotes WHERE id_lote = NEW.id_lote;
        IF v_prod_lote IS DISTINCT FROM NEW.id_producto THEN
            RAISE EXCEPTION 'RN-A1-05: el lote % no pertenece al producto %', NEW.id_lote, NEW.id_producto;
        END IF;
    END IF;

    -- RN-A1-04: copia el nombre del proveedor al texto que usa v_kardex del área 3
    IF NEW.id_proveedor IS NOT NULL THEN
        SELECT nombre INTO v_nombre_prov FROM proveedores WHERE id_proveedor = NEW.id_proveedor;
        NEW.proveedor := v_nombre_prov;
    END IF;

    -- RN-A1-18: solo para filas capturadas por el área 1 (las que traen almacén)
    IF NEW.id_almacen IS NOT NULL
       AND NEW.numero_factura_proveedor IS NULL
       AND NEW.numero_orden_compra IS NULL
       AND NEW.id_orden_produccion IS NULL THEN
        RAISE EXCEPTION 'RN-A1-18: la entrada requiere factura del proveedor, orden de compra u orden de producción';
    END IF;

    RETURN NEW;
END; $$;

CREATE TRIGGER tg_valida_entrada
BEFORE INSERT ON entradas_producto
FOR EACH ROW EXECUTE FUNCTION fn_valida_entrada();
