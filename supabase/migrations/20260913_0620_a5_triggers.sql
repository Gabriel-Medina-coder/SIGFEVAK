-- Área 5 · Issues #89, #90 · RN-A5-04, RN-A5-05, RN-A5-06, RN-A5-07, RN-A5-10, RN-A5-17, RN-A5-18, RN-A5-19,
-- RN-A5-22, RN-A5-23, RN-A5-24
-- Qué hace: máquina de estados de la obligación con separación de funciones, bitácora automática, baja lógica
-- en vez de DELETE e inmutabilidad de obligaciones cerradas y de sus pagos y documentos.

-- RN-A5-24: nada cambia en una obligación CERRADO ni en sus pagos y documentos
CREATE OR REPLACE FUNCTION fn_bloquea_cerradas() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_estado estado_obligacion; v_id INT;
BEGIN
    IF TG_TABLE_NAME = 'obligaciones' THEN
        IF OLD.estado = 'CERRADO' THEN
            RAISE EXCEPTION 'RN-A5-24: la obligación % está CERRADO y es inmutable', OLD.id_obligacion;
        END IF;
        RETURN COALESCE(NEW, OLD);
    END IF;
    v_id := COALESCE((to_jsonb(NEW)->>'id_obligacion')::INT, (to_jsonb(OLD)->>'id_obligacion')::INT);
    SELECT estado INTO v_estado FROM obligaciones WHERE id_obligacion = v_id;
    IF v_estado = 'CERRADO' THEN
        RAISE EXCEPTION 'RN-A5-24: la obligación % está CERRADO; sus pagos y documentos no se modifican', v_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END; $$;
CREATE TRIGGER tg_a_bloquea_cerradas BEFORE UPDATE OR DELETE ON obligaciones
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_cerradas();
CREATE TRIGGER tg_a_bloquea_pagos_cerrados BEFORE INSERT OR UPDATE OR DELETE ON pagos_obligacion
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_cerradas();
CREATE TRIGGER tg_a_bloquea_documentos_cerrados BEFORE INSERT OR UPDATE OR DELETE ON documentos_fiscales
FOR EACH ROW EXECUTE FUNCTION fn_bloquea_cerradas();

-- RN-A5-04, 05, 06, 07, 10, 18, 19, 23: máquina de estados
-- PENDIENTE → CALCULADO → PRESENTADO → LINEA_GENERADA → AUTORIZADO → PAGADO → CONCILIADO → CERRADO.
-- Retroceso único: rechazo del autorizador a CALCULADO con comentario. VENCIDO entra desde cualquier estado anterior a PAGADO y sale solo a PAGADO.
CREATE OR REPLACE FUNCTION fn_transicion_obligacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_orden TEXT[] := ARRAY['PENDIENTE','CALCULADO','PRESENTADO','LINEA_GENERADA','AUTORIZADO','PAGADO','CONCILIADO','CERRADO'];
    v_de INT; v_a INT; v_critica BOOLEAN; v_clave TEXT; v_rol rol_usuario; v_pagado DECIMAL;
BEGIN
    -- RN-A5-23: después de AUTORIZADO el monto final no cambia salvo por rechazo
    IF OLD.estado = NEW.estado THEN
        IF OLD.estado IN ('AUTORIZADO', 'PAGADO', 'CONCILIADO') AND NEW.monto_final IS DISTINCT FROM OLD.monto_final THEN
            RAISE EXCEPTION 'RN-A5-23: el monto final de la obligación % está congelado desde su autorización', OLD.id_obligacion;
        END IF;
        RETURN NEW;
    END IF;

    SELECT t.critica, t.clave INTO v_critica, v_clave FROM tipos_obligacion t WHERE t.id_tipo_obligacion = NEW.id_tipo_obligacion;

    -- VENCIDO: entra desde cualquier estado anterior a PAGADO; sale solo a PAGADO (RN-A5-19)
    IF NEW.estado = 'VENCIDO' THEN
        IF OLD.estado IN ('PAGADO', 'CONCILIADO', 'CERRADO') THEN
            RAISE EXCEPTION 'RN-A5-19: la obligación % ya está % y no puede marcarse VENCIDO', OLD.id_obligacion, OLD.estado;
        END IF;
        RETURN NEW;
    END IF;
    IF OLD.estado = 'VENCIDO' AND NEW.estado <> 'PAGADO' THEN
        RAISE EXCEPTION 'RN-A5-19: una obligación VENCIDO solo puede pasar a PAGADO';
    END IF;

    -- Rechazo del autorizador: regresa a CALCULADO con comentario y descongela el monto (RN-A5-19, RN-A5-23)
    IF OLD.estado IN ('LINEA_GENERADA', 'AUTORIZADO') AND NEW.estado = 'CALCULADO' THEN
        IF NEW.comentario IS NULL OR btrim(NEW.comentario) = '' THEN
            RAISE EXCEPTION 'RN-A5-19: el rechazo exige un comentario';
        END IF;
        NEW.id_autorizador := NULL;
        NEW.monto_final := NULL;
        RETURN NEW;
    END IF;

    IF OLD.estado <> 'VENCIDO' THEN
        v_de := array_position(v_orden, OLD.estado::TEXT);
        v_a  := array_position(v_orden, NEW.estado::TEXT);
        IF v_a IS NULL OR v_de IS NULL OR v_a <> v_de + 1 THEN
            RAISE EXCEPTION 'RN-A5-19: transición % a % no permitida', OLD.estado, NEW.estado;
        END IF;
    END IF;

    IF NEW.estado = 'CALCULADO' AND NEW.monto_estimado IS NULL THEN
        RAISE EXCEPTION 'RN-A5-19: CALCULADO requiere monto_estimado';
    END IF;

    -- RN-A5-10: un pedimento no sale de CALCULADO sin fracción arancelaria en todos sus productos
    IF OLD.estado = 'CALCULADO' AND v_clave = 'PEDIMENTO' AND EXISTS (
        SELECT 1 FROM importaciones i JOIN productos_importados pi USING (id_importacion)
         WHERE i.id_obligacion = NEW.id_obligacion AND pi.fraccion_arancelaria IS NULL) THEN
        RAISE EXCEPTION 'RN-A5-10: la importación de la obligación % tiene productos sin fracción arancelaria', NEW.id_obligacion;
    END IF;

    IF NEW.estado = 'AUTORIZADO' THEN
        IF NEW.id_autorizador IS NULL THEN
            RAISE EXCEPTION 'RN-A5-18: AUTORIZADO requiere id_autorizador';
        END IF;
        IF NEW.id_autorizador = NEW.id_responsable THEN
            RAISE EXCEPTION 'RN-A5-18: quien preparó la obligación % no puede autorizarla', NEW.id_obligacion;
        END IF;
        IF v_critica THEN
            SELECT rol INTO v_rol FROM usuarios WHERE id_usuario = NEW.id_autorizador;
            IF v_rol IS DISTINCT FROM 'AUTORIZADOR' AND v_rol IS DISTINCT FROM 'ADMINISTRADOR' THEN
                RAISE EXCEPTION 'RN-A5-06: la obligación % es crítica; solo AUTORIZADOR o ADMINISTRADOR pueden autorizarla', NEW.id_obligacion;
            END IF;
        END IF;
        NEW.monto_final := COALESCE(NEW.monto_final, NEW.monto_estimado);                     -- RN-A5-23
        IF NEW.monto_final IS NULL THEN
            RAISE EXCEPTION 'RN-A5-23: no hay monto que congelar en la obligación %', NEW.id_obligacion;
        END IF;
    END IF;

    IF NEW.estado = 'PAGADO' AND NOT EXISTS (
        SELECT 1 FROM pagos_obligacion WHERE id_obligacion = NEW.id_obligacion AND estado_pago = 'PAGADO') THEN
        RAISE EXCEPTION 'RN-A5-04: la obligación % no tiene ningún pago registrado', NEW.id_obligacion;
    END IF;

    IF NEW.estado = 'CONCILIADO' THEN
        SELECT COALESCE(SUM(monto), 0) INTO v_pagado FROM pagos_obligacion WHERE id_obligacion = NEW.id_obligacion AND estado_pago = 'PAGADO';
        IF v_pagado <> COALESCE(NEW.monto_final, -1) THEN
            RAISE EXCEPTION 'RN-A5-05: la suma de pagos (%) no coincide con el monto final (%) de la obligación %', v_pagado, NEW.monto_final, NEW.id_obligacion;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM documentos_fiscales WHERE id_obligacion = NEW.id_obligacion AND tipo_documento = 'COMPROBANTE_BANCARIO') THEN
            RAISE EXCEPTION 'RN-A5-07: la obligación % no tiene comprobante bancario registrado', NEW.id_obligacion;
        END IF;
    END IF;

    IF NEW.estado = 'CERRADO' THEN
        NEW.fecha_cierre := COALESCE(NEW.fecha_cierre, CURRENT_DATE);
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_transicion_obligacion BEFORE UPDATE ON obligaciones
FOR EACH ROW EXECUTE FUNCTION fn_transicion_obligacion();

-- RN-A5-17: bitácora de obligaciones, pagos, importaciones y licencias
CREATE OR REPLACE FUNCTION fn_bitacora_fiscal() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_accion TEXT; v_usuario UUID; v_id INT; v_pk TEXT;
BEGIN
    v_pk := CASE TG_TABLE_NAME WHEN 'obligaciones' THEN 'id_obligacion' WHEN 'pagos_obligacion' THEN 'id_pago'
                               WHEN 'importaciones' THEN 'id_importacion' WHEN 'licencias_permisos' THEN 'id_licencia' END;
    v_id := (to_jsonb(NEW)->>v_pk)::INT;
    v_accion := TG_OP;
    IF TG_TABLE_NAME = 'obligaciones' THEN
        v_usuario := COALESCE(auth.uid(), NEW.id_autorizador, NEW.id_responsable);
        IF TG_OP = 'UPDATE' AND OLD.estado <> NEW.estado THEN
            v_accion := CASE WHEN NEW.estado = 'AUTORIZADO' THEN 'AUTORIZAR'
                             WHEN NEW.estado = 'CALCULADO' AND OLD.estado IN ('LINEA_GENERADA','AUTORIZADO') THEN 'RECHAZAR'
                             WHEN NEW.estado = 'CERRADO' THEN 'CERRAR'
                             ELSE NEW.estado::TEXT END;
        ELSIF TG_OP = 'UPDATE' AND OLD.activo AND NOT NEW.activo THEN
            v_accion := 'BAJA';
        END IF;
    ELSIF TG_TABLE_NAME = 'pagos_obligacion' THEN
        v_usuario := COALESCE(auth.uid(), NEW.id_registrado_por);
    ELSE
        v_usuario := auth.uid();
    END IF;
    INSERT INTO bitacora_fiscal (id_usuario, tabla, id_registro, accion, valor_anterior, valor_nuevo)
    VALUES (v_usuario, TG_TABLE_NAME, v_id, v_accion, CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW));
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_bitacora_obligaciones AFTER INSERT OR UPDATE ON obligaciones
FOR EACH ROW EXECUTE FUNCTION fn_bitacora_fiscal();
CREATE TRIGGER tg_bitacora_pagos AFTER INSERT OR UPDATE ON pagos_obligacion
FOR EACH ROW EXECUTE FUNCTION fn_bitacora_fiscal();

-- RN-A5-22: un DELETE de obligación se convierte en baja lógica con bitácora
CREATE OR REPLACE FUNCTION fn_baja_logica_obligacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE obligaciones SET activo = FALSE WHERE id_obligacion = OLD.id_obligacion AND activo;
    RETURN NULL;   -- cancela el borrado físico
END; $$;
CREATE TRIGGER tg_baja_logica_obligacion BEFORE DELETE ON obligaciones
FOR EACH ROW EXECUTE FUNCTION fn_baja_logica_obligacion();
