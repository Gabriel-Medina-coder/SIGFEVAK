-- Área 5 · Issue #91 · RN-A5-03, RN-A5-14, RN-A5-16, RN-A5-21
-- Qué hace: fn_generar_obligaciones_periodo (crea las obligaciones mensuales, bimestrales y anuales del periodo
-- desde el catálogo; la de ISN toma su base de v_retenciones_area5 del área 4 y la de IVA el trasladado de
-- v_iva_trasladado_periodo del área 2), fn_generar_alertas (15, 7, 3, 1, 0 días y VENCIDA, sin duplicar) y
-- fn_marcar_vencidas. Se disparan desde el botón de administración o con pg_cron.

CREATE OR REPLACE FUNCTION fn_generar_obligaciones_periodo(p_periodo VARCHAR)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    t RECORD; v_inicio DATE; v_fin DATE; v_venc DATE; v_n INT := 0; v_monto DECIMAL; v_periodo VARCHAR(7);
    v_base DECIMAL; v_tasa DECIMAL; v_entidad TEXT; v_resp UUID;
BEGIN
    IF p_periodo !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' THEN
        RAISE EXCEPTION 'El periodo debe tener formato AAAA-MM';
    END IF;
    v_inicio := TO_DATE(p_periodo || '-01', 'YYYY-MM-DD');
    v_fin    := (v_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    SELECT id_usuario INTO v_resp FROM usuarios WHERE rol = 'CONTADOR' AND activo ORDER BY creado_en LIMIT 1;

    FOR t IN SELECT * FROM tipos_obligacion WHERE frecuencia IN ('MENSUAL', 'BIMESTRAL', 'ANUAL') AND dias_vencimiento IS NOT NULL LOOP
        v_monto := NULL; v_entidad := NULL; v_periodo := p_periodo;
        IF t.frecuencia = 'MENSUAL' THEN
            v_venc := (v_inicio + INTERVAL '1 month')::DATE + (t.dias_vencimiento - 1);          -- RN-A5-03
            IF t.clave = 'IVA_MENSUAL' THEN
                -- IVA trasladado del área 2 (I-07); el acreditable se captura a mano (pregunta abierta 3)
                SELECT iva_trasladado INTO v_monto FROM v_iva_trasladado_periodo WHERE periodo = p_periodo;
            END IF;
        ELSIF t.frecuencia = 'BIMESTRAL' THEN
            IF EXTRACT(MONTH FROM v_inicio)::INT % 2 = 1 THEN CONTINUE; END IF;                 -- el bimestre cierra en mes par
            v_venc := (v_inicio + INTERVAL '1 month')::DATE + (t.dias_vencimiento - 1);
            IF t.clave = 'ISN_CHIAPAS' THEN
                v_entidad := 'Chiapas';
                -- RN-A5-14: base gravable del área 4 (I-03) × tasa vigente de la entidad
                SELECT COALESCE(SUM(base_isn), 0) INTO v_base FROM v_retenciones_area5
                 WHERE entidad_federativa = v_entidad AND fecha_fin BETWEEN (v_inicio - INTERVAL '1 month')::DATE AND v_fin;
                v_tasa := fn_parametro_fiscal('TASA_ISN', v_entidad, NULL, v_venc);
                v_monto := CASE WHEN v_tasa IS NULL THEN NULL ELSE ROUND(v_base * v_tasa, 2) END;
            END IF;
        ELSE  -- ANUAL: se genera al cerrar diciembre, con periodo AAAA y vencimiento el día indicado de marzo
            IF EXTRACT(MONTH FROM v_inicio) <> 12 THEN CONTINUE; END IF;
            v_periodo := TO_CHAR(v_inicio, 'YYYY');
            v_venc := MAKE_DATE(EXTRACT(YEAR FROM v_inicio)::INT + 1, 3, t.dias_vencimiento);
        END IF;

        INSERT INTO obligaciones (id_tipo_obligacion, periodo, fecha_vencimiento, monto_estimado, entidad, id_responsable)
        SELECT t.id_tipo_obligacion, v_periodo, v_venc, v_monto, v_entidad, v_resp
        WHERE NOT EXISTS (SELECT 1 FROM obligaciones WHERE id_tipo_obligacion = t.id_tipo_obligacion AND periodo = v_periodo);
        IF FOUND THEN v_n := v_n + 1; END IF;
    END LOOP;
    RETURN v_n;
END; $$;

-- RN-A5-21: alertas a 15, 7, 3, 1 y 0 días y VENCIDA al día siguiente; UNIQUE (id_obligacion, dias_anticipacion) evita duplicados
CREATE OR REPLACE FUNCTION fn_generar_alertas() RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_n INT := 0; v_m INT;
BEGIN
    INSERT INTO alertas (id_obligacion, fecha_alerta, dias_anticipacion, nivel, mensaje, id_usuario)
    SELECT o.id_obligacion, o.fecha_vencimiento - d.dias, d.dias, d.nivel::nivel_alerta,
           d.texto || ': ' || t.nombre || COALESCE(' ' || o.periodo, '') || ' vence el ' || TO_CHAR(o.fecha_vencimiento, 'DD/MM/YYYY'),
           o.id_responsable
      FROM obligaciones o
      JOIN tipos_obligacion t USING (id_tipo_obligacion)
      CROSS JOIN (VALUES (15, 'PREVENTIVA', 'Aviso inicial'), (7, 'PREVENTIVA', 'Solicitar documentación'),
                         (3, 'ALTA', 'Priorizar trámite'), (1, 'CRITICA', 'Vencimiento próximo'), (0, 'CRITICA', 'Aviso inmediato')) AS d(dias, nivel, texto)
     WHERE o.activo AND o.estado NOT IN ('PAGADO', 'CONCILIADO', 'CERRADO')
    ON CONFLICT (id_obligacion, dias_anticipacion) DO NOTHING;
    GET DIAGNOSTICS v_m = ROW_COUNT; v_n := v_n + v_m;

    INSERT INTO alertas (id_obligacion, fecha_alerta, dias_anticipacion, nivel, mensaje, id_usuario)
    SELECT o.id_obligacion, o.fecha_vencimiento + 1, -1, 'VENCIDA',
           'Incumplimiento: ' || t.nombre || COALESCE(' ' || o.periodo, '') || ' venció el ' || TO_CHAR(o.fecha_vencimiento, 'DD/MM/YYYY'),
           o.id_responsable
      FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion)
     WHERE o.activo AND o.estado = 'VENCIDO'
    ON CONFLICT (id_obligacion, dias_anticipacion) DO NOTHING;
    GET DIAGNOSTICS v_m = ROW_COUNT; v_n := v_n + v_m;

    -- Las alertas de obligaciones ya pagadas o cerradas se dan por atendidas
    UPDATE alertas a SET estado_envio = 'ATENDIDA'
      FROM obligaciones o
     WHERE o.id_obligacion = a.id_obligacion AND a.estado_envio <> 'ATENDIDA' AND o.estado IN ('PAGADO', 'CONCILIADO', 'CERRADO');
    RETURN v_n;
END; $$;

-- RN-A5-16: vencidas automáticas
CREATE OR REPLACE FUNCTION fn_marcar_vencidas() RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_n INT;
BEGIN
    UPDATE obligaciones SET estado = 'VENCIDO'
     WHERE activo AND fecha_vencimiento < CURRENT_DATE
       AND estado NOT IN ('PAGADO', 'CONCILIADO', 'CERRADO', 'VENCIDO');
    GET DIAGNOSTICS v_n = ROW_COUNT;
    PERFORM fn_generar_alertas();
    RETURN v_n;
END; $$;
