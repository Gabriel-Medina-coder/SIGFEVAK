-- Área 4 · Issue #81 · RN-A4-08
-- Qué hace: al cancelar una factura cuya comisión ya se autorizó o pagó, genera el ajuste_comision negativo que
-- fn_aplicar_ajustes descuenta en el siguiente periodo con el tope del art. 110 (pregunta abierta 3 cerrada:
-- CANCELADO es el único disparador). Si el periodo del cobro todavía se puede recalcular, no hace falta ajuste.

CREATE OR REPLACE FUNCTION fn_ajuste_por_cancelacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_periodo periodos_nomina%ROWTYPE; v_tasa DECIMAL; v_monto DECIMAL;
BEGIN
    IF NEW.estado_pago <> 'CANCELADO' OR OLD.estado_pago <> 'PAGADO' THEN RETURN NEW; END IF;

    -- Periodo mensual en que se cobró la factura (base de la comisión, RN-A4-06)
    SELECT * INTO v_periodo FROM periodos_nomina
     WHERE tipo = 'MENSUAL' AND COALESCE(OLD.fecha_cobro, OLD.fecha) BETWEEN fecha_inicio AND fecha_fin;
    IF v_periodo.id_periodo IS NULL OR v_periodo.estatus NOT IN ('AUTORIZADO', 'PAGADO', 'CERRADO') THEN
        RETURN NEW;   -- aún no comisionada: el recálculo del periodo la excluye sola
    END IF;

    -- Tasa con la que se pagó: la que dejó el cálculo en bitácora; si no hay, la tasa de respaldo del agente (RN-A4-05)
    SELECT (valor_nuevo->>'tasa')::DECIMAL INTO v_tasa FROM bitacora_nomina
     WHERE tabla = 'nomina_detalle' AND accion = 'CALCULO'
       AND (valor_nuevo->>'id_periodo')::INT = v_periodo.id_periodo
       AND (valor_nuevo->>'id_agente')::INT = NEW.id_agente
     ORDER BY id_bitacora DESC LIMIT 1;
    IF v_tasa IS NULL THEN
        SELECT comision / 100 INTO v_tasa FROM agentes_ventas WHERE id_agente = NEW.id_agente;
    END IF;

    v_monto := ROUND(OLD.subtotal * COALESCE(v_tasa, 0), 2);
    IF v_monto <= 0 THEN RETURN NEW; END IF;

    INSERT INTO ajustes_comision (id_agente, id_factura, id_periodo_origen, monto, motivo)
    VALUES (NEW.id_agente, NEW.id_factura, v_periodo.id_periodo, -v_monto,
            'Cancelación de la factura ' || COALESCE(NEW.folio, NEW.id_factura::TEXT) || ' ya comisionada');
    INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_nuevo)
    VALUES (COALESCE(fn_usuario_actual(), 'sistema'), 'ajustes_comision', 'AJUSTE_CANCELACION',
            jsonb_build_object('id_factura', NEW.id_factura, 'id_periodo_origen', v_periodo.id_periodo, 'tasa', v_tasa, 'monto', -v_monto));
    RETURN NEW;
END; $$;

CREATE TRIGGER tg_ajuste_por_cancelacion AFTER UPDATE OF estado_pago ON facturas
FOR EACH ROW EXECUTE FUNCTION fn_ajuste_por_cancelacion();
