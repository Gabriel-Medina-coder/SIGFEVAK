-- Área 1 · Issues #28, #29, #30 · RN-A1-06, RN-A1-09 a RN-A1-17
-- Qué hace: triggers de la vía B (manufactura): entrada de materia prima, almacén de insumos, orden con BOM,
-- máquina de estados de la orden, consumo con validación de stock, control de calidad y cierre de orden
-- que genera la entrada al inventario.

-- Entrada de materia prima: suma stock y guarda el último costo (única escritura de stock junto con el consumo, RN-A1-09)
CREATE OR REPLACE FUNCTION fn_entrada_materia()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE materias_primas
       SET stock          = stock + NEW.cantidad,
           costo_unitario = NEW.costo_unitario
     WHERE id_materia = NEW.id_materia;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_entrada_materia
AFTER INSERT ON entradas_materia_prima
FOR EACH ROW EXECUTE FUNCTION fn_entrada_materia();

-- RN-A1-06 para materias primas: su almacén debe ser INSUMOS
CREATE OR REPLACE FUNCTION fn_valida_almacen_materia()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_tipo tipo_almacen;
BEGIN
    SELECT tipo INTO v_tipo FROM almacenes WHERE id_almacen = NEW.id_almacen;
    IF v_tipo IS DISTINCT FROM 'INSUMOS' THEN
        RAISE EXCEPTION 'RN-A1-06: la materia prima % debe estar en un almacén de insumos', NEW.sku;
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_valida_almacen_materia
BEFORE INSERT OR UPDATE OF id_almacen ON materias_primas
FOR EACH ROW EXECUTE FUNCTION fn_valida_almacen_materia();

-- RN-A1-10: una orden requiere BOM
CREATE OR REPLACE FUNCTION fn_valida_orden()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bom WHERE id_producto_destino = NEW.id_producto_destino) THEN
        RAISE EXCEPTION 'RN-A1-10: el producto % no tiene BOM; no se puede crear la orden', NEW.id_producto_destino;
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_valida_orden
BEFORE INSERT ON ordenes_produccion
FOR EACH ROW EXECUTE FUNCTION fn_valida_orden();

-- RN-A1-11: la orden solo avanza PLANEADA → EN_PROCESO → EN_CALIDAD → TERMINADA; CANCELADA desde cualquier no final
CREATE OR REPLACE FUNCTION fn_transicion_orden()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.estado = NEW.estado THEN RETURN NEW; END IF;
    IF OLD.estado IN ('TERMINADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'RN-A1-11: la orden % está en estado final %', OLD.folio, OLD.estado;
    END IF;
    IF NEW.estado = 'CANCELADA' THEN RETURN NEW; END IF;
    IF NOT ((OLD.estado = 'PLANEADA'   AND NEW.estado = 'EN_PROCESO') OR
            (OLD.estado = 'EN_PROCESO' AND NEW.estado = 'EN_CALIDAD') OR
            (OLD.estado = 'EN_CALIDAD' AND NEW.estado = 'TERMINADA')) THEN
        RAISE EXCEPTION 'RN-A1-11: transición % a % no permitida', OLD.estado, NEW.estado;
    END IF;
    IF NEW.estado = 'EN_PROCESO' AND NEW.fecha_inicio_real IS NULL THEN
        NEW.fecha_inicio_real := CURRENT_DATE;
    END IF;
    IF NEW.estado = 'TERMINADA' THEN
        -- RN-A1-12: solo se termina con control de calidad y unidades aprobadas
        IF NOT EXISTS (SELECT 1 FROM control_calidad WHERE id_orden = NEW.id_orden AND aprobadas > 0) THEN
            RAISE EXCEPTION 'RN-A1-12: la orden % no tiene control de calidad con unidades aprobadas', NEW.folio;
        END IF;
        IF NEW.fecha_fin_real IS NULL THEN NEW.fecha_fin_real := CURRENT_DATE; END IF;
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_transicion_orden
BEFORE UPDATE OF estado ON ordenes_produccion
FOR EACH ROW EXECUTE FUNCTION fn_transicion_orden();

-- RN-A1-09, RN-A1-13, RN-A1-14: consumo de materia prima
CREATE OR REPLACE FUNCTION fn_consumo_materia()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_estado estado_orden;
    v_prod   INT;
    v_stock  DECIMAL;
    v_nombre VARCHAR;
BEGIN
    SELECT estado, id_producto_destino INTO v_estado, v_prod
      FROM ordenes_produccion WHERE id_orden = NEW.id_orden;
    IF v_estado IS DISTINCT FROM 'EN_PROCESO' THEN
        RAISE EXCEPTION 'RN-A1-13: la orden % no está EN_PROCESO', NEW.id_orden;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM bom WHERE id_producto_destino = v_prod AND id_materia = NEW.id_materia) THEN
        RAISE EXCEPTION 'RN-A1-14: la materia % no está en el BOM del producto %', NEW.id_materia, v_prod;
    END IF;
    SELECT stock, nombre INTO v_stock, v_nombre
      FROM materias_primas WHERE id_materia = NEW.id_materia FOR UPDATE;
    IF v_stock < NEW.cantidad_real THEN
        RAISE EXCEPTION 'RN-A1-09: stock insuficiente de "%" (disponible %, solicitado %)', v_nombre, v_stock, NEW.cantidad_real;
    END IF;
    UPDATE materias_primas SET stock = stock - NEW.cantidad_real WHERE id_materia = NEW.id_materia;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_consumo_materia
BEFORE INSERT ON consumo_produccion
FOR EACH ROW EXECUTE FUNCTION fn_consumo_materia();

-- RN-A1-15, RN-A1-16: control de calidad
CREATE OR REPLACE FUNCTION fn_valida_calidad()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_estado estado_orden;
    v_plan   INT;
    v_resp   VARCHAR;
BEGIN
    SELECT estado, cantidad_planeada, responsable INTO v_estado, v_plan, v_resp
      FROM ordenes_produccion WHERE id_orden = NEW.id_orden;
    IF v_estado IS DISTINCT FROM 'EN_CALIDAD' THEN
        RAISE EXCEPTION 'RN-A1-15: la orden % no está EN_CALIDAD', NEW.id_orden;
    END IF;
    IF NEW.aprobadas + NEW.rechazadas > v_plan THEN
        RAISE EXCEPTION 'RN-A1-15: aprobadas + rechazadas (%) supera la cantidad planeada (%)',
            NEW.aprobadas + NEW.rechazadas, v_plan;
    END IF;
    IF NEW.responsable = v_resp THEN
        RAISE EXCEPTION 'RN-A1-16: quien inspecciona no puede ser el responsable de la orden';
    END IF;
    NEW.resultado := CASE WHEN NEW.aprobadas > 0 THEN 'APROBADO' ELSE 'RECHAZADO' END;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_valida_calidad
BEFORE INSERT ON control_calidad
FOR EACH ROW EXECUTE FUNCTION fn_valida_calidad();

-- RN-A1-12, RN-A1-17: cierre de orden. Calcula el costo unitario de manufactura y genera la entrada al inventario;
-- el trigger del área 3 (fn_entrada_producto) hace el resto sobre productos.
CREATE OR REPLACE FUNCTION fn_cerrar_orden()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_aprobadas  INT;
    v_costo_mat  DECIMAL;
    v_costo_unit DECIMAL;
    v_almacen    INT;
    v_lote       INT;
BEGIN
    IF NEW.estado <> 'TERMINADA' OR OLD.estado = 'TERMINADA' THEN RETURN NEW; END IF;

    SELECT aprobadas INTO v_aprobadas FROM control_calidad WHERE id_orden = NEW.id_orden;
    SELECT COALESCE(SUM(c.cantidad_real * m.costo_unitario), 0) INTO v_costo_mat
      FROM consumo_produccion c JOIN materias_primas m USING (id_materia)
     WHERE c.id_orden = NEW.id_orden;

    -- RN-A1-17: la merma y las unidades rechazadas se reparten entre las aprobadas
    v_costo_unit := ROUND((v_costo_mat + NEW.costo_mano_obra + NEW.costos_indirectos) / v_aprobadas, 2);

    SELECT id_almacen INTO v_almacen FROM almacenes
     WHERE tipo = 'PRODUCTO_TERMINADO' AND activo ORDER BY id_almacen LIMIT 1;

    INSERT INTO lotes (id_producto, numero_lote, fecha_fabricacion, id_almacen)
    VALUES (NEW.id_producto_destino, NEW.folio, COALESCE(NEW.fecha_fin_real, CURRENT_DATE), v_almacen)
    RETURNING id_lote INTO v_lote;

    -- RN-A1-12: una sola entrada por orden (UNIQUE en id_orden_produccion)
    INSERT INTO entradas_producto (id_producto, fecha, cantidad, costo_unitario, proveedor, documento_ref,
                                   id_almacen, id_lote, id_orden_produccion, responsable_recepcion)
    VALUES (NEW.id_producto_destino, COALESCE(NEW.fecha_fin_real, CURRENT_DATE), v_aprobadas, v_costo_unit,
            'PRODUCCIÓN INTERNA', NEW.folio, v_almacen, v_lote, NEW.id_orden, NEW.responsable);

    UPDATE ordenes_produccion SET cantidad_terminada = v_aprobadas WHERE id_orden = NEW.id_orden;
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_cerrar_orden
AFTER UPDATE OF estado ON ordenes_produccion
FOR EACH ROW EXECUTE FUNCTION fn_cerrar_orden();
