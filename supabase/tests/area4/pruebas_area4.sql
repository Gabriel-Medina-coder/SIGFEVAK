-- Área 4 · Issues #80, #81 · Pruebas de RN-A4-01, RN-A4-03, RN-A4-04, RN-A4-08, RN-A4-09, RN-A4-13, RN-A4-15, RN-A4-18
-- y el ejemplo de la sección 10 exacto sobre el periodo 2026-09 del seed. Cada bloque lanza RAISE EXCEPTION si la
-- regla no se cumple. Corre en una transacción que se revierte.
BEGIN;

DO $$
DECLARE
    v_zona_gen INT; v_zona_zlfn INT; v_esq INT; v_jorge INT; v_per INT; v_per_oct INT;
    v_ok BOOLEAN; v_num DECIMAL; v_txt TEXT; r RECORD;
BEGIN
    SELECT id_zona INTO v_zona_gen  FROM zonas WHERE zona_salarial = 'GENERAL' ORDER BY id_zona LIMIT 1;
    SELECT id_zona INTO v_zona_zlfn FROM zonas WHERE zona_salarial = 'ZLFN' ORDER BY id_zona LIMIT 1;
    SELECT id_esquema INTO v_esq FROM esquemas_compensacion WHERE nombre = 'Esquema 2026 general';
    SELECT id_agente INTO v_jorge FROM agentes_ventas WHERE nombre = 'Jorge Mendoza';
    SELECT id_periodo INTO v_per FROM periodos_nomina WHERE tipo = 'MENSUAL' AND fecha_inicio = DATE '2026-09-01';

    -- RN-A4-01: salario menor al mínimo de la zona se rechaza (general 315.04, ZLFN 440.87)
    v_ok := FALSE;
    BEGIN
        INSERT INTO agentes_ventas (nombre, sueldo_base, comision, id_zona, salario_diario) VALUES ('PRUEBA agente', 9000, 1, v_zona_gen, 300);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-01%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-01 falló: aceptó salario 300 en zona general'; END IF;
    v_ok := FALSE;
    BEGIN
        INSERT INTO agentes_ventas (nombre, sueldo_base, comision, id_zona, salario_diario) VALUES ('PRUEBA agente', 9000, 1, v_zona_zlfn, 350);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-01%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-01 falló: aceptó salario 350 en zona ZLFN'; END IF;

    -- RN-A4-04: tramo traslapado se rechaza
    v_ok := FALSE;
    BEGIN
        INSERT INTO tramos_comision (id_esquema, pct_min, pct_max, tasa) VALUES (v_esq, 90, 110, 0.05);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-04%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-04 falló: aceptó tramo traslapado'; END IF;

    -- RN-A4-09: bono manual sin autorizado_por se rechaza por CHECK
    v_ok := FALSE;
    BEGIN
        INSERT INTO bonos_asignados (id_agente, id_bono, id_periodo, monto, calculado)
        SELECT v_jorge, id_bono, v_per, 100, FALSE FROM bonos_catalogo WHERE clave = 'META';
    EXCEPTION WHEN check_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-09 falló: aceptó bono manual sin autorización'; END IF;

    -- ---------- Ejemplo de la sección 10 sobre el periodo 2026-09 del seed ----------
    SELECT pct_cumplimiento, ventas_cobradas INTO v_num, v_txt FROM v_cumplimiento_meta WHERE id_agente = v_jorge AND periodo = '2026-09';
    IF v_num <> 112 OR v_txt::DECIMAL <> 560000 THEN RAISE EXCEPTION 'Cumplimiento falló: % %% sobre %', v_num, v_txt; END IF;
    FOR r IN SELECT * FROM (VALUES
        ('SUELDO', 10640.00), ('COMISION', 16800.00), ('BONO_META', 2500.00), ('BONO_CLIENTE_NUEVO', 1000.00),
        ('BONO_COBRANZA', 1000.00), ('PREMIO_PUNTUALIDAD', 1064.00)) AS v(concepto, monto)
    LOOP
        SELECT monto INTO v_num FROM nomina_detalle WHERE id_periodo = v_per AND id_agente = v_jorge AND concepto = r.concepto;
        IF v_num IS DISTINCT FROM r.monto THEN RAISE EXCEPTION 'Ejemplo 10 falló: % = % (esperado %)', r.concepto, v_num, r.monto; END IF;
    END LOOP;
    SELECT percepciones INTO v_num FROM v_nomina_totales WHERE id_periodo = v_per AND id_agente = v_jorge;
    IF v_num <> 33004 THEN RAISE EXCEPTION 'Ejemplo 10 falló: percepciones = %', v_num; END IF;
    IF EXISTS (SELECT 1 FROM nomina_detalle WHERE id_periodo = v_per AND id_agente = v_jorge AND concepto = 'BONO_TRIMESTRAL') THEN
        RAISE EXCEPTION 'Bono trimestral no debía pagarse sin tres meses de metas';
    END IF;
    -- RN-A4-12: el premio de puntualidad queda exento (1,064 < tope) y no integra SBC (RN-A4-10)
    IF (SELECT exento FROM nomina_detalle WHERE id_periodo = v_per AND id_agente = v_jorge AND concepto = 'PREMIO_PUNTUALIDAD') <> 1064 THEN
        RAISE EXCEPTION 'RN-A4-12 falló: premio de puntualidad no exento';
    END IF;
    -- ISR con la tarifa del seed: gravado 31,940 → tramo 31,236.50: 5,004.12 + (31,940 − 31,236.50) × 23.52 % = 5,169.58
    SELECT monto INTO v_num FROM nomina_detalle WHERE id_periodo = v_per AND id_agente = v_jorge AND concepto = 'ISR';
    IF v_num <> 5169.58 THEN RAISE EXCEPTION 'ISR falló: %', v_num; END IF;
    -- IMSS obrero: base que integra SBC 31,940 × 2.38 % = 760.17
    SELECT monto INTO v_num FROM nomina_detalle WHERE id_periodo = v_per AND id_agente = v_jorge AND concepto = 'IMSS_OBRERO';
    IF v_num <> 760.17 THEN RAISE EXCEPTION 'IMSS falló: %', v_num; END IF;
    -- RN-A4-16: ISN de Chiapas al 2 % sobre la base que integra SBC
    SELECT isn_estimado INTO v_num FROM v_retenciones_area5 WHERE id_periodo = v_per AND entidad_federativa = 'Chiapas';
    IF v_num IS NULL OR v_num <= 0 THEN RAISE EXCEPTION 'RN-A4-16 falló: ISN de Chiapas = %', v_num; END IF;

    -- ---------- Estados con un periodo propio de 2026-10 ----------
    INSERT INTO metas (id_agente, periodo, monto_meta) SELECT id_agente, '2026-10', 100000 FROM agentes_ventas WHERE estatus = 'ACTIVO';
    INSERT INTO periodos_nomina (tipo, fecha_inicio, fecha_fin) VALUES ('MENSUAL', DATE '2026-10-01', DATE '2026-10-31') RETURNING id_periodo INTO v_per_oct;

    -- RN-A4-13: saltar de ABIERTO a REVISADO se rechaza
    v_ok := FALSE;
    BEGIN
        UPDATE periodos_nomina SET estatus = 'REVISADO', revisado_por = 'x' WHERE id_periodo = v_per_oct;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-13%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-13 falló: aceptó salto de estado'; END IF;

    -- RN-A4-03: sin meta no hay cálculo
    DELETE FROM metas WHERE periodo = '2026-10' AND id_agente = v_jorge;
    v_ok := FALSE;
    BEGIN
        PERFORM fn_calcular_periodo(v_per_oct, 'calc@sigfevak.mx');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-03%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-03 falló: calculó sin meta'; END IF;
    INSERT INTO metas (id_agente, periodo, monto_meta) VALUES (v_jorge, '2026-10', 100000);

    PERFORM fn_calcular_periodo(v_per_oct, 'calc@sigfevak.mx');
    IF (SELECT estatus FROM periodos_nomina WHERE id_periodo = v_per_oct) <> 'CALCULADO' THEN RAISE EXCEPTION 'El cálculo no dejó el periodo en CALCULADO'; END IF;

    -- RN-A4-13: retroceso a ABIERTO sin comentario se rechaza; con comentario pasa
    v_ok := FALSE;
    BEGIN
        UPDATE periodos_nomina SET estatus = 'ABIERTO' WHERE id_periodo = v_per_oct;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-13%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-13 falló: regresó a ABIERTO sin comentario'; END IF;
    UPDATE periodos_nomina SET estatus = 'ABIERTO', comentario = 'Falta la meta corregida de un agente', revisado_por = 'gerente@sigfevak.mx' WHERE id_periodo = v_per_oct;
    PERFORM fn_calcular_periodo(v_per_oct, 'calc@sigfevak.mx');
    UPDATE periodos_nomina SET estatus = 'REVISADO', revisado_por = 'gerente@sigfevak.mx' WHERE id_periodo = v_per_oct;

    -- RN-A4-08: un ajuste pendiente se descuenta en la nómina respetando el tope del art. 110
    INSERT INTO ajustes_comision (id_agente, id_factura, id_periodo_origen, monto, motivo)
    VALUES (v_jorge, (SELECT MIN(id_factura) FROM facturas), v_per, -500.00, 'Factura cancelada tras comisionar');
    PERFORM fn_calcular_nomina(v_per_oct);
    SELECT monto INTO v_num FROM nomina_detalle WHERE id_periodo = v_per_oct AND id_agente = v_jorge AND concepto = 'AJUSTE_COMISION';
    IF v_num IS DISTINCT FROM 500.00 THEN RAISE EXCEPTION 'RN-A4-08 falló: ajuste aplicado = %', v_num; END IF;
    IF EXISTS (SELECT 1 FROM ajustes_comision WHERE id_agente = v_jorge AND id_periodo_aplicado IS NULL) THEN
        RAISE EXCEPTION 'RN-A4-08 falló: el ajuste sigue pendiente';
    END IF;

    -- RN-A4-15: quien calculó no autoriza
    v_ok := FALSE;
    BEGIN
        UPDATE periodos_nomina SET estatus = 'AUTORIZADO', autorizado_por = 'calc@sigfevak.mx' WHERE id_periodo = v_per_oct;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-15%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-15 falló: autorizó quien calculó'; END IF;
    UPDATE periodos_nomina SET estatus = 'AUTORIZADO', autorizado_por = 'autorizador@sigfevak.mx' WHERE id_periodo = v_per_oct;
    UPDATE periodos_nomina SET estatus = 'PAGADO' WHERE id_periodo = v_per_oct;
    IF (SELECT fecha_pago FROM periodos_nomina WHERE id_periodo = v_per_oct) IS NULL THEN RAISE EXCEPTION 'PAGADO no puso fecha_pago'; END IF;

    -- RN-A4-18: un periodo PAGADO no se modifica ni acepta movimientos
    v_ok := FALSE;
    BEGIN
        INSERT INTO nomina_detalle (id_periodo, id_agente, concepto, tipo, clave_sat, monto, gravado) VALUES (v_per_oct, v_jorge, 'SUELDO', 'PERCEPCION', '001', 1, 1);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-18%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-18 falló: aceptó movimiento en periodo pagado'; END IF;
    v_ok := FALSE;
    BEGIN
        UPDATE periodos_nomina SET estatus = 'ABIERTO', comentario = 'x' WHERE id_periodo = v_per_oct;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A4-18%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A4-18 falló: modificó un periodo pagado'; END IF;
    UPDATE periodos_nomina SET estatus = 'CERRADO' WHERE id_periodo = v_per_oct;

    RAISE NOTICE 'Pruebas del área 4: todas pasaron';
END $$;

ROLLBACK;
