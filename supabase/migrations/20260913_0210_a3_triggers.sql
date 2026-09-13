-- Área 3 · Issue #5 · RN-A3-01, RN-A3-05, RN-A3-06, RN-A3-07, RN-A3-08
-- Qué hace: los tres triggers que son los únicos que escriben productos.stock (RN-A3-06).
-- Cierra también #1 (I-01): la fórmula de capital ya incluye flete, impuestos y tipo de cambio.

-- ENTRADA: suma stock y volumen, acumula capital con la fórmula de D-03 y guarda el último costo (RN-A3-05, RN-A3-08)
CREATE OR REPLACE FUNCTION fn_entrada_producto()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productos
       SET stock             = stock + NEW.cantidad,
           volumen           = volumen + NEW.cantidad,
           capital_inversion = capital_inversion
                               + NEW.cantidad * (NEW.costo_unitario + NEW.flete_unitario + NEW.impuestos_unitarios) * NEW.tipo_cambio,
           valor_entrada     = (NEW.costo_unitario + NEW.flete_unitario + NEW.impuestos_unitarios) * NEW.tipo_cambio
     WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_entrada_producto
AFTER INSERT ON entradas_producto
FOR EACH ROW EXECUTE FUNCTION fn_entrada_producto();

-- SALIDA: valida existencia con bloqueo de fila y descuenta (RN-A3-01)
CREATE OR REPLACE FUNCTION fn_salida_producto()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_stock  INT;
    v_nombre VARCHAR;
BEGIN
    SELECT stock, nombre INTO v_stock, v_nombre
      FROM productos WHERE id_producto = NEW.id_producto FOR UPDATE;

    IF v_stock IS NULL THEN
        RAISE EXCEPTION 'RN-A3-02: el producto % no existe', NEW.id_producto;
    END IF;
    IF v_stock < NEW.cantidad THEN
        RAISE EXCEPTION 'RN-A3-01: stock insuficiente para "%" (disponible: %, solicitado: %)',
            v_nombre, v_stock, NEW.cantidad;
    END IF;

    UPDATE productos SET stock = stock - NEW.cantidad
     WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_salida_producto
BEFORE INSERT ON detalle_factura
FOR EACH ROW EXECUTE FUNCTION fn_salida_producto();

-- AJUSTE: alinea el stock al conteo físico dejando la evidencia en la fila (RN-A3-07)
CREATE OR REPLACE FUNCTION fn_ajuste_inventario()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productos SET stock = NEW.conteo_fisico
     WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_ajuste_inventario
AFTER INSERT ON ajustes_inventario
FOR EACH ROW EXECUTE FUNCTION fn_ajuste_inventario();

-- Congela stock_sistema al momento del conteo si el capturista no lo manda (RN-A3-07)
CREATE OR REPLACE FUNCTION fn_ajuste_stock_sistema()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.stock_sistema IS NULL THEN
        SELECT stock INTO NEW.stock_sistema FROM productos WHERE id_producto = NEW.id_producto;
    END IF;
    IF NEW.responsable IS NULL THEN
        NEW.responsable := fn_usuario_actual();
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_ajuste_stock_sistema
BEFORE INSERT ON ajustes_inventario
FOR EACH ROW EXECUTE FUNCTION fn_ajuste_stock_sistema();
