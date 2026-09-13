-- Área 2 · Issue #46 · RN-A2-03, RN-A2-09, RN-A2-10, RN-A2-11
-- Qué hace: fn_tasa_iva() como único lugar del 16 %, triggers de folio de cliente y de factura, y
-- fn_valida_factura (cliente activo y vencimiento por días de crédito) antes de insertar una factura.

-- RN-A2-03: tasa general de IVA. Cambiarla aquí cambia todos los cálculos. Pregunta abierta 1 del área.
CREATE OR REPLACE FUNCTION fn_tasa_iva() RETURNS DECIMAL(5,4)
LANGUAGE sql IMMUTABLE AS $$ SELECT 0.1600::DECIMAL(5,4); $$;

-- RN-A2-11: folio de comercializador COM-000001
CREATE OR REPLACE FUNCTION fn_folio_cliente() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.numero_comercializador IS NULL THEN
        NEW.numero_comercializador := 'COM-' || LPAD(nextval('seq_comercializador')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_folio_cliente BEFORE INSERT ON clientes
FOR EACH ROW EXECUTE FUNCTION fn_folio_cliente();

-- RN-A2-11: folio de factura FAC-000001
CREATE OR REPLACE FUNCTION fn_folio_factura() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.folio IS NULL THEN
        NEW.folio := 'FAC-' || LPAD(nextval('seq_folio_factura')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END; $$;

-- Dos triggers BEFORE INSERT en facturas; PostgreSQL los corre en orden alfabético, de ahí los prefijos a_ y b_.
CREATE TRIGGER a_tg_folio_factura BEFORE INSERT ON facturas
FOR EACH ROW EXECUTE FUNCTION fn_folio_factura();

-- RN-A2-09, RN-A2-10: cliente activo y fecha de vencimiento por días de crédito
CREATE OR REPLACE FUNCTION fn_valida_factura() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_activo BOOLEAN; v_dias INT;
BEGIN
    SELECT activo, dias_credito INTO v_activo, v_dias FROM clientes WHERE id_cliente = NEW.id_cliente;
    IF v_activo IS NOT TRUE THEN
        RAISE EXCEPTION 'RN-A2-10: el cliente % está dado de baja; no puede recibir facturas nuevas', NEW.id_cliente;
    END IF;
    IF NEW.fecha_vencimiento IS NULL THEN
        NEW.fecha_vencimiento := COALESCE(NEW.fecha, CURRENT_DATE) + v_dias;              -- RN-A2-09
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER b_tg_valida_factura BEFORE INSERT ON facturas
FOR EACH ROW EXECUTE FUNCTION fn_valida_factura();
