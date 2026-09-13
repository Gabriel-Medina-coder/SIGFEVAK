-- Área 4 · Issues #76, #77 · RN-A4-02, RN-A4-03, RN-A4-05, RN-A4-06, RN-A4-08, RN-A4-09, RN-A4-10, RN-A4-12,
-- RN-A4-14, RN-A4-16, RN-A4-17
-- Qué hace: fn_calcular_periodo (sueldo del mes, cumplimiento, tramo, comisión y los cinco bonos),
-- fn_aplicar_ajustes (descuentos por cancelación con tope del art. 110) y fn_calcular_nomina (ISR art. 96,
-- cuota obrera IMSS y ajustes). En esta versión solo se calculan periodos MENSUAL: el sueldo del mes entra al
-- periodo mensual y las quincenas quedan como fase 2 (pregunta abierta 8).

CREATE OR REPLACE FUNCTION fn_calcular_periodo(p_id_periodo INT, p_usuario VARCHAR)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    p          periodos_nomina%ROWTYPE;
    a          agentes_ventas%ROWTYPE;
    v_periodo  VARCHAR(7);
    v_factor   DECIMAL; v_uma_mensual DECIMAL; v_tope_umas DECIMAL;
    v_meta     metas%ROWTYPE;
    v_ventas   DECIMAL; v_pct DECIMAL; v_tasa DECIMAL; v_sueldo DECIMAL; v_comision DECIMAL;
    v_nuevos   INT; v_pct_vencida DECIMAL; v_prom_trim DECIMAL; v_meses_trim INT;
    v_bono     bonos_catalogo%ROWTYPE; v_monto DECIMAL; v_exento DECIMAL;
BEGIN
    SELECT * INTO p FROM periodos_nomina WHERE id_periodo = p_id_periodo;
    IF p.id_periodo IS NULL THEN RAISE EXCEPTION 'El periodo % no existe', p_id_periodo; END IF;
    IF p.tipo <> 'MENSUAL' THEN
        RAISE EXCEPTION 'RN-A4-17: en esta versión solo se calculan periodos MENSUAL; las quincenas son fase 2';
    END IF;
    IF p.estatus <> 'ABIERTO' THEN
        RAISE EXCEPTION 'RN-A4-13: el periodo % está %; solo se calcula en ABIERTO', p_id_periodo, p.estatus;
    END IF;

    v_periodo     := TO_CHAR(p.fecha_inicio, 'YYYY-MM');
    v_factor      := fn_parametro('FACTOR_DIAS_MES', NULL, p.fecha_fin);                 -- RN-A4-14
    v_uma_mensual := fn_parametro('UMA_MENSUAL', NULL, p.fecha_fin);
    v_tope_umas   := COALESCE(fn_parametro('TOPE_EXENTO_PUNTUALIDAD_UMAS', NULL, p.fecha_fin), 0);
    IF v_factor IS NULL OR v_uma_mensual IS NULL THEN
        RAISE EXCEPTION 'RN-A4-14: faltan FACTOR_DIAS_MES o UMA_MENSUAL vigentes al %', p.fecha_fin;
    END IF;

    -- Recalcular desde cero
    DELETE FROM nomina_detalle  WHERE id_periodo = p_id_periodo;
    DELETE FROM bonos_asignados WHERE id_periodo = p_id_periodo AND calculado;

    FOR a IN SELECT * FROM agentes_ventas WHERE estatus = 'ACTIVO' ORDER BY id_agente LOOP
        -- RN-A4-02: zona obligatoria; RN-A4-05: sin esquema se usa la tasa fija de respaldo
        IF a.id_zona IS NULL THEN
            RAISE EXCEPTION 'RN-A4-02: el agente % no tiene zona asignada', a.nombre;
        END IF;
        -- RN-A4-03: la meta del periodo debe existir
        SELECT * INTO v_meta FROM metas WHERE id_agente = a.id_agente AND periodo = v_periodo;
        IF v_meta.id_meta IS NULL THEN
            RAISE EXCEPTION 'RN-A4-03: el agente % no tiene meta para %', a.nombre, v_periodo;
        END IF;

        -- RN-A4-06: ventas cobradas sin IVA del mes de cobro
        SELECT COALESCE(SUM(subtotal), 0) INTO v_ventas
          FROM v_ventas_cobradas_agente WHERE id_agente = a.id_agente AND periodo = v_periodo;
        v_pct := ROUND(v_ventas / v_meta.monto_meta * 100, 2);

        IF a.id_esquema IS NOT NULL THEN
            SELECT tasa INTO v_tasa FROM tramos_comision
             WHERE id_esquema = a.id_esquema AND pct_min <= v_pct AND (pct_max IS NULL OR v_pct < pct_max)
             ORDER BY pct_min DESC LIMIT 1;
            IF v_tasa IS NULL THEN
                RAISE EXCEPTION 'RN-A4-04: el esquema % no tiene tramo para un cumplimiento de % %%', a.id_esquema, v_pct;
            END IF;
        ELSE
            v_tasa := a.comision / 100;                                                    -- RN-A4-05
            INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_nuevo)
            VALUES (p_usuario, 'agentes_ventas', 'SIN_ESQUEMA',
                    jsonb_build_object('id_agente', a.id_agente, 'tasa_respaldo', v_tasa, 'periodo', v_periodo));
        END IF;

        -- Sueldo del mes (clave SAT 001)
        v_sueldo := ROUND(a.salario_diario * v_factor, 2);
        INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
        VALUES (p_id_periodo, a.id_agente, 'SUELDO', 'PERCEPCION', '001', v_sueldo, v_sueldo, 0, TRUE);

        -- Comisión: la tasa del tramo se aplica a toda la base (RN-A4-06), clave SAT 028
        v_comision := ROUND(v_ventas * v_tasa, 2);
        INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
        VALUES (p_id_periodo, a.id_agente, 'COMISION', 'PERCEPCION', '028', v_comision, v_comision, 0, TRUE);

        -- Bono de cumplimiento de meta
        SELECT * INTO v_bono FROM bonos_catalogo WHERE clave = 'META';
        IF v_bono.id_bono IS NOT NULL AND v_pct >= 100 THEN
            INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto) VALUES (a.id_agente, v_bono.id_bono, p_id_periodo, v_bono.monto);
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
            VALUES (p_id_periodo, a.id_agente, 'BONO_META', 'PERCEPCION', v_bono.clave_sat, v_bono.monto, v_bono.monto, 0, v_bono.integra_sbc);
        END IF;

        -- Bono por cliente nuevo: primera compra pagada en el mes
        SELECT * INTO v_bono FROM bonos_catalogo WHERE clave = 'CLIENTE_NUEVO';
        SELECT COUNT(*) INTO v_nuevos FROM v_clientes_nuevos_agente WHERE id_agente = a.id_agente AND periodo_alta = v_periodo;
        IF v_bono.id_bono IS NOT NULL AND v_nuevos > 0 THEN
            v_monto := v_bono.monto * v_nuevos;
            INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto) VALUES (a.id_agente, v_bono.id_bono, p_id_periodo, v_monto);
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
            VALUES (p_id_periodo, a.id_agente, 'BONO_CLIENTE_NUEVO', 'PERCEPCION', v_bono.clave_sat, v_monto, v_monto, 0, v_bono.integra_sbc);
        END IF;

        -- Bono de cobranza sana: cartera vencida menor al 5 % (sección 2.3), leída de v_cartera_agente del área 2 (I-02)
        SELECT * INTO v_bono FROM bonos_catalogo WHERE clave = 'COBRANZA_SANA';
        SELECT COALESCE(pct_vencida, 0) INTO v_pct_vencida FROM v_cartera_agente WHERE id_agente = a.id_agente;
        IF v_bono.id_bono IS NOT NULL AND COALESCE(v_pct_vencida, 0) < 5 THEN
            INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto) VALUES (a.id_agente, v_bono.id_bono, p_id_periodo, v_bono.monto);
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
            VALUES (p_id_periodo, a.id_agente, 'BONO_COBRANZA', 'PERCEPCION', v_bono.clave_sat, v_bono.monto, v_bono.monto, 0, v_bono.integra_sbc);
        END IF;

        -- Premio de puntualidad: 10 % del sueldo del mes si no hubo retardos; no integra SBC; exento hasta el tope en UMAs (RN-A4-10, RN-A4-12)
        SELECT * INTO v_bono FROM bonos_catalogo WHERE clave = 'PUNTUALIDAD';
        IF v_bono.id_bono IS NOT NULL AND v_meta.sin_retardos THEN
            v_monto  := ROUND(v_sueldo * v_bono.porcentaje, 2);
            v_exento := LEAST(v_monto, ROUND(v_uma_mensual * v_tope_umas, 2));
            INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto) VALUES (a.id_agente, v_bono.id_bono, p_id_periodo, v_monto);
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
            VALUES (p_id_periodo, a.id_agente, 'PREMIO_PUNTUALIDAD', 'PERCEPCION', v_bono.clave_sat, v_monto, v_monto - v_exento, v_exento, v_bono.integra_sbc);
        END IF;

        -- Bono trimestral: promedio de cumplimiento de los tres meses que terminan en este periodo >= 110 % (solo con las tres metas)
        SELECT * INTO v_bono FROM bonos_catalogo WHERE clave = 'TRIMESTRAL';
        SELECT COUNT(*), AVG(pct_cumplimiento) INTO v_meses_trim, v_prom_trim
          FROM v_cumplimiento_meta
         WHERE id_agente = a.id_agente
           AND periodo IN (TO_CHAR(p.fecha_inicio, 'YYYY-MM'),
                           TO_CHAR(p.fecha_inicio - INTERVAL '1 month', 'YYYY-MM'),
                           TO_CHAR(p.fecha_inicio - INTERVAL '2 month', 'YYYY-MM'));
        IF v_bono.id_bono IS NOT NULL AND v_meses_trim = 3 AND v_prom_trim >= 110 THEN
            INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto) VALUES (a.id_agente, v_bono.id_bono, p_id_periodo, v_bono.monto);
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado, exento, integra_sbc)
            VALUES (p_id_periodo, a.id_agente, 'BONO_TRIMESTRAL', 'PERCEPCION', v_bono.clave_sat, v_bono.monto, v_bono.monto, 0, v_bono.integra_sbc);
        END IF;

        INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_nuevo)
        VALUES (p_usuario, 'nomina_detalle', 'CALCULO',
                jsonb_build_object('id_periodo', p_id_periodo, 'id_agente', a.id_agente, 'ventas', v_ventas,
                                   'pct_cumplimiento', v_pct, 'tasa', v_tasa, 'comision', v_comision, 'clientes_nuevos', v_nuevos));
    END LOOP;

    UPDATE periodos_nomina SET estatus = 'CALCULADO', calculado_por = p_usuario, comentario = NULL WHERE id_periodo = p_id_periodo;
END; $$;

-- RN-A4-08: aplica los ajustes pendientes del agente sin exceder el tope del art. 110 LFT
-- (TOPE_DESCUENTO_110 × excedente del salario mínimo mensual); lo que no cabe se difiere como ajuste nuevo.
CREATE OR REPLACE FUNCTION fn_aplicar_ajustes(p_id_periodo INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    p periodos_nomina%ROWTYPE; r RECORD; aj RECORD;
    v_tope_pct DECIMAL; v_sm DECIMAL; v_factor DECIMAL; v_percepciones DECIMAL; v_tope DECIMAL; v_aplicado DECIMAL; v_parte DECIMAL;
BEGIN
    SELECT * INTO p FROM periodos_nomina WHERE id_periodo = p_id_periodo;
    v_tope_pct := fn_parametro('TOPE_DESCUENTO_110', NULL, p.fecha_fin);
    v_sm       := fn_parametro('SM_GENERAL', NULL, p.fecha_fin);
    v_factor   := fn_parametro('FACTOR_DIAS_MES', NULL, p.fecha_fin);

    FOR r IN SELECT DISTINCT id_agente FROM ajustes_comision WHERE id_periodo_aplicado IS NULL LOOP
        SELECT COALESCE(SUM(monto), 0) INTO v_percepciones FROM nomina_detalle
         WHERE id_periodo = p_id_periodo AND id_agente = r.id_agente AND tipo = 'PERCEPCION';
        IF v_percepciones = 0 THEN CONTINUE; END IF;              -- el agente no está en este periodo
        v_tope := GREATEST(ROUND((v_percepciones - v_sm * v_factor) * v_tope_pct, 2), 0);
        v_aplicado := 0;
        FOR aj IN SELECT * FROM ajustes_comision WHERE id_agente = r.id_agente AND id_periodo_aplicado IS NULL ORDER BY fecha, id_ajuste LOOP
            IF v_aplicado >= v_tope THEN EXIT; END IF;
            v_parte := LEAST(-aj.monto, v_tope - v_aplicado);
            IF v_parte < -aj.monto THEN
                -- Se aplica una parte y el resto queda pendiente para el siguiente periodo
                INSERT INTO ajustes_comision (id_agente, id_factura, id_periodo_origen, monto, motivo, fecha)
                VALUES (aj.id_agente, aj.id_factura, aj.id_periodo_origen, aj.monto + v_parte, aj.motivo || ' (diferido por tope art. 110)', aj.fecha);
                UPDATE ajustes_comision SET monto = -v_parte, id_periodo_aplicado = p_id_periodo WHERE id_ajuste = aj.id_ajuste;
            ELSE
                UPDATE ajustes_comision SET id_periodo_aplicado = p_id_periodo WHERE id_ajuste = aj.id_ajuste;
            END IF;
            v_aplicado := v_aplicado + v_parte;
        END LOOP;
        IF v_aplicado > 0 THEN
            INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, integra_sbc)
            VALUES (p_id_periodo, r.id_agente, 'AJUSTE_COMISION', 'DEDUCCION', '004', v_aplicado, FALSE);
        END IF;
    END LOOP;
END; $$;

-- RN-A4-10, RN-A4-12, RN-A4-14, RN-A4-16: deducciones del periodo. ISR con la tarifa mensual del art. 96 sobre lo gravado,
-- cuota obrera IMSS sobre lo que integra SBC, y ajustes de comisión. INFONAVIT queda fuera del alcance (pregunta abierta 4).
CREATE OR REPLACE FUNCTION fn_calcular_nomina(p_id_periodo INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    p periodos_nomina%ROWTYPE; r RECORD; v_tarifa JSONB; v_tramo JSONB;
    v_cuota_imss DECIMAL; v_isr DECIMAL; v_imss DECIMAL;
BEGIN
    SELECT * INTO p FROM periodos_nomina WHERE id_periodo = p_id_periodo;
    IF p.estatus NOT IN ('CALCULADO', 'REVISADO') THEN
        RAISE EXCEPTION 'RN-A4-13: el periodo % está %; la nómina se calcula en CALCULADO o REVISADO', p_id_periodo, p.estatus;
    END IF;
    v_tarifa     := fn_parametro_tabla('TARIFA_ISR_MENSUAL', p.fecha_fin);              -- RN-A4-14
    v_cuota_imss := fn_parametro('CUOTA_IMSS_OBRERO', NULL, p.fecha_fin);
    IF v_tarifa IS NULL OR v_cuota_imss IS NULL THEN
        RAISE EXCEPTION 'RN-A4-14: faltan TARIFA_ISR_MENSUAL o CUOTA_IMSS_OBRERO vigentes al %', p.fecha_fin;
    END IF;

    DELETE FROM nomina_detalle WHERE id_periodo = p_id_periodo AND tipo = 'DEDUCCION';
    UPDATE ajustes_comision SET id_periodo_aplicado = NULL WHERE id_periodo_aplicado = p_id_periodo;

    FOR r IN
        SELECT id_agente,
               SUM(gravado) AS gravado,
               SUM(CASE WHEN integra_sbc THEN monto ELSE 0 END) AS base_sbc
          FROM nomina_detalle WHERE id_periodo = p_id_periodo AND tipo = 'PERCEPCION' GROUP BY id_agente
    LOOP
        -- ISR art. 96: cuota fija + (gravado - límite inferior) × porcentaje del rango
        SELECT t INTO v_tramo FROM jsonb_array_elements(v_tarifa) AS t
         WHERE (t->>'li')::DECIMAL <= r.gravado AND (t->>'ls' IS NULL OR (t->>'ls')::DECIMAL >= r.gravado)
         ORDER BY (t->>'li')::DECIMAL DESC LIMIT 1;
        v_isr := ROUND((v_tramo->>'cuota')::DECIMAL + (r.gravado - (v_tramo->>'li')::DECIMAL) * (v_tramo->>'pct')::DECIMAL, 2);
        INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, integra_sbc)
        VALUES (p_id_periodo, r.id_agente, 'ISR', 'DEDUCCION', '002', v_isr, FALSE);

        -- Cuota obrera IMSS sobre la base que integra SBC (RN-A4-10)
        v_imss := ROUND(r.base_sbc * v_cuota_imss, 2);
        INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, integra_sbc)
        VALUES (p_id_periodo, r.id_agente, 'IMSS_OBRERO', 'DEDUCCION', '001', v_imss, FALSE);
    END LOOP;

    PERFORM fn_aplicar_ajustes(p_id_periodo);                                              -- RN-A4-08

    INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_nuevo)
    VALUES (COALESCE(p.revisado_por, p.calculado_por, 'sistema'), 'nomina_detalle', 'NOMINA', jsonb_build_object('id_periodo', p_id_periodo));
END; $$;
