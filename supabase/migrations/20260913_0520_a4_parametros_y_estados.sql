-- Área 4 · Issues #67, #68 · RN-A4-01, RN-A4-13, RN-A4-14, RN-A4-15, RN-A4-18
-- Qué hace: fn_parametro y fn_parametro_tabla (valor legal vigente a una fecha), trigger de salario mínimo por
-- zona, máquina de estados del periodo con separación de funciones y bloqueo de periodos pagados o cerrados.

-- RN-A4-14: parámetro legal vigente a una fecha (valor simple)
CREATE OR REPLACE FUNCTION fn_parametro(p_clave VARCHAR, p_entidad VARCHAR, p_fecha DATE)
RETURNS DECIMAL LANGUAGE sql STABLE AS $$
    SELECT valor FROM parametros_legales
     WHERE clave = p_clave
       AND (entidad = p_entidad OR (entidad IS NULL AND p_entidad IS NULL))
       AND vigencia_inicio <= p_fecha
       AND (vigencia_fin IS NULL OR vigencia_fin >= p_fecha)
     ORDER BY vigencia_inicio DESC LIMIT 1;
$$;

-- RN-A4-14: parámetro legal vigente a una fecha (tarifa por rangos en JSONB)
CREATE OR REPLACE FUNCTION fn_parametro_tabla(p_clave VARCHAR, p_fecha DATE)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT tabla FROM parametros_legales
     WHERE clave = p_clave AND entidad IS NULL
       AND vigencia_inicio <= p_fecha
       AND (vigencia_fin IS NULL OR vigencia_fin >= p_fecha)
     ORDER BY vigencia_inicio DESC LIMIT 1;
$$;

-- RN-A4-01: salario diario >= salario mínimo de la zona salarial del agente
CREATE OR REPLACE FUNCTION fn_valida_salario_minimo() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_zona zona_salarial; v_sm DECIMAL;
BEGIN
    IF NEW.id_zona IS NULL OR NEW.salario_diario IS NULL THEN RETURN NEW; END IF;
    SELECT zona_salarial INTO v_zona FROM zonas WHERE id_zona = NEW.id_zona;
    v_sm := fn_parametro(CASE v_zona WHEN 'ZLFN' THEN 'SM_ZLFN' ELSE 'SM_GENERAL' END, NULL, CURRENT_DATE);
    IF v_sm IS NULL THEN
        RAISE EXCEPTION 'RN-A4-14: no hay salario mínimo vigente en parametros_legales para la zona %', v_zona;
    END IF;
    IF NEW.salario_diario < v_sm THEN
        RAISE EXCEPTION 'RN-A4-01: salario diario % menor al mínimo % de la zona %', NEW.salario_diario, v_sm, v_zona;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_salario_minimo BEFORE INSERT OR UPDATE OF salario_diario, id_zona ON agentes_ventas
FOR EACH ROW EXECUTE FUNCTION fn_valida_salario_minimo();

-- RN-A4-13, RN-A4-15, RN-A4-18: el periodo solo avanza ABIERTO → CALCULADO → REVISADO → AUTORIZADO → PAGADO → CERRADO;
-- único retroceso CALCULADO → ABIERTO con comentario; quien calcula no autoriza; PAGADO y CERRADO no cambian.
CREATE OR REPLACE FUNCTION fn_transicion_periodo() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_orden INT[]; v_de INT; v_a INT;
BEGIN
    IF OLD.estatus IN ('PAGADO', 'CERRADO') AND (NEW.estatus <> OLD.estatus OR NEW.fecha_pago IS DISTINCT FROM OLD.fecha_pago
        OR NEW.autorizado_por IS DISTINCT FROM OLD.autorizado_por OR NEW.calculado_por IS DISTINCT FROM OLD.calculado_por) THEN
        IF NOT (OLD.estatus = 'PAGADO' AND NEW.estatus = 'CERRADO') THEN
            RAISE EXCEPTION 'RN-A4-18: el periodo % está % y no se modifica', OLD.id_periodo, OLD.estatus;
        END IF;
    END IF;
    IF OLD.estatus = NEW.estatus THEN RETURN NEW; END IF;

    -- Retroceso permitido: CALCULADO → ABIERTO por rechazo con comentario
    IF OLD.estatus = 'CALCULADO' AND NEW.estatus = 'ABIERTO' THEN
        IF NEW.comentario IS NULL OR btrim(NEW.comentario) = '' THEN
            RAISE EXCEPTION 'RN-A4-13: regresar a ABIERTO exige un comentario de rechazo';
        END IF;
        INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_anterior, valor_nuevo)
        VALUES (COALESCE(NEW.revisado_por, NEW.autorizado_por, 'sistema'), 'periodos_nomina', 'RECHAZO',
                to_jsonb(OLD), to_jsonb(NEW));
        NEW.calculado_por := NULL;
        NEW.autorizado_por := NULL;
        RETURN NEW;
    END IF;

    v_de := array_position(ARRAY['ABIERTO','CALCULADO','REVISADO','AUTORIZADO','PAGADO','CERRADO'], OLD.estatus::TEXT);
    v_a  := array_position(ARRAY['ABIERTO','CALCULADO','REVISADO','AUTORIZADO','PAGADO','CERRADO'], NEW.estatus::TEXT);
    IF v_a <> v_de + 1 THEN
        RAISE EXCEPTION 'RN-A4-13: transición % a % no permitida', OLD.estatus, NEW.estatus;
    END IF;

    IF NEW.estatus = 'CALCULADO' AND NEW.calculado_por IS NULL THEN
        RAISE EXCEPTION 'RN-A4-13: CALCULADO requiere calculado_por';
    END IF;
    IF NEW.estatus = 'REVISADO' AND NEW.revisado_por IS NULL THEN
        RAISE EXCEPTION 'RN-A4-13: REVISADO requiere revisado_por';
    END IF;
    IF NEW.estatus = 'AUTORIZADO' THEN
        IF NEW.autorizado_por IS NULL THEN
            RAISE EXCEPTION 'RN-A4-15: AUTORIZADO requiere autorizado_por';
        END IF;
        IF NEW.autorizado_por = NEW.calculado_por THEN
            RAISE EXCEPTION 'RN-A4-15: % calculó el periodo y no puede autorizarlo', NEW.autorizado_por;
        END IF;
    END IF;
    IF NEW.estatus = 'PAGADO' AND NEW.fecha_pago IS NULL THEN
        NEW.fecha_pago := CURRENT_DATE;
    END IF;

    INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_anterior, valor_nuevo)
    VALUES (COALESCE(NEW.autorizado_por, NEW.revisado_por, NEW.calculado_por, 'sistema'), 'periodos_nomina',
            NEW.estatus::TEXT, jsonb_build_object('estatus', OLD.estatus), jsonb_build_object('estatus', NEW.estatus));
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_transicion_periodo BEFORE UPDATE ON periodos_nomina
FOR EACH ROW EXECUTE FUNCTION fn_transicion_periodo();

-- RN-A4-18: nada se escribe en la nómina ni en los bonos de un periodo PAGADO o CERRADO
CREATE OR REPLACE FUNCTION fn_bloquea_periodo_cerrado() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_estatus estatus_periodo; v_id INT;
BEGIN
    v_id := COALESCE(NEW.id_periodo, OLD.id_periodo);
    SELECT estatus INTO v_estatus FROM periodos_nomina WHERE id_periodo = v_id;
    IF v_estatus IN ('PAGADO', 'CERRADO') THEN
        RAISE EXCEPTION 'RN-A4-18: el periodo % está %; cualquier corrección es un ajuste en el siguiente periodo', v_id, v_estatus;
    END IF;
    RETURN COALESCE(NEW, OLD);
END; $$;
CREATE TRIGGER tg_bloquea_nomina_cerrada BEFORE INSERT OR UPDATE OR DELETE ON nomina_detalle
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_periodo_cerrado();
CREATE TRIGGER tg_bloquea_bonos_cerrados BEFORE INSERT OR UPDATE OR DELETE ON bonos_asignados
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_periodo_cerrado();
