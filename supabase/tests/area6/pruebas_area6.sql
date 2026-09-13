-- Área 6 · Issue #117 · Pruebas del caso A (presupuesto y ROI), caso B (directo y ROI real) y casos límite
-- (RN-A6-02, RN-A6-03, RN-A6-04, RN-A6-09, RN-A6-10, RN-A6-13, RN-A6-15, RN-A6-16). Corre sobre el seed en una
-- transacción que se revierte.
BEGIN;

DO $$
DECLARE
    v_a INT; v_b INT; v_c INT; v_x INT; v_inv INT; v_redes INT; v_ok BOOLEAN; r RECORD; v_ts TIMESTAMPTZ; v_n INT;
BEGIN
    SELECT id_campana INTO v_a FROM campanas WHERE nombre = 'Lanzamiento Smartwatch Pro';
    SELECT id_campana INTO v_b FROM campanas WHERE nombre = 'Promo revendedores agosto';
    SELECT id_campana INTO v_c FROM campanas WHERE estatus = 'FINALIZADA' LIMIT 1;
    SELECT id_canal INTO v_redes FROM canales_marketing WHERE nombre = 'Redes sociales';

    -- ---------- Caso A ----------
    SELECT * INTO r FROM v_campana_resumen WHERE id_campana = v_a;
    IF r.gasto_total <> 45000 OR r.presupuesto_restante <> 5000 OR r.pct_ejercido <> 90 OR r.roi <> 1.9333
       OR r.leads_generados <> 310 OR r.conversiones <> 48 OR r.ingreso_atribuido <> 132000 THEN
        RAISE EXCEPTION 'Caso A falló: gasto % restante % pct % roi %', r.gasto_total, r.presupuesto_restante, r.pct_ejercido, r.roi;
    END IF;
    -- RN-A6-03: un cuarto costo de 7,500 excede el presupuesto y se rechaza; el resumen no cambia
    v_ok := FALSE;
    BEGIN
        INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto) VALUES (v_a, v_redes, 'Influencer', 7500, CURRENT_DATE);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A6-03%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-03 falló: aceptó exceder el presupuesto'; END IF;
    IF (SELECT gasto_total FROM v_campana_resumen WHERE id_campana = v_a) <> 45000 THEN RAISE EXCEPTION 'El resumen cambió tras un costo rechazado'; END IF;
    -- Con presupuesto ampliado sí entra
    UPDATE campanas SET presupuesto_asignado = 52500 WHERE id_campana = v_a;
    INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto) VALUES (v_a, v_redes, 'Influencer', 7500, CURRENT_DATE);
    IF (SELECT gasto_total FROM v_campana_resumen WHERE id_campana = v_a) <> 52500 THEN RAISE EXCEPTION 'RN-A6-11 falló: gasto tras ampliar'; END IF;

    -- ---------- Caso B ----------
    SELECT * INTO r FROM v_directo_desempeno WHERE id_campana = v_b;
    IF r.total_objetivo <> 5 OR r.total_contactados <> 4 OR r.total_convertidos <> 2 OR r.tasa_conversion_pct <> 40 THEN
        RAISE EXCEPTION 'Caso B falló en v_directo_desempeno: % % % %', r.total_objetivo, r.total_contactados, r.total_convertidos, r.tasa_conversion_pct;
    END IF;
    SELECT * INTO r FROM v_ventas_atribuidas_campana WHERE id_campana = v_b;
    -- RN-A6-14: facturas PAGADO de los cinco clientes objetivo con fecha dentro de agosto
    IF r.facturas_atribuidas <> 5 OR r.ventas_atribuidas_sin_iva <> 771200 OR r.gasto_total <> 11200 OR r.roi_real <> 67.8571 THEN
        RAISE EXCEPTION 'Caso B falló en v_ventas_atribuidas_campana: % % % %', r.facturas_atribuidas, r.ventas_atribuidas_sin_iva, r.gasto_total, r.roi_real;
    END IF;

    -- RN-A6-02: un cliente objetivo en la campaña EXTERNO del caso A se rechaza
    v_ok := FALSE;
    BEGIN
        INSERT INTO campana_clientes (id_campana, id_cliente) SELECT v_a, id_cliente FROM clientes LIMIT 1;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A6-02%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-02 falló'; END IF;

    -- RN-A6-15: una DIRECTO sin clientes no se activa; RN-A6-10: fecha_fin anterior se rechaza
    INSERT INTO campanas (nombre, tipo_marketing, fecha_inicio, presupuesto_asignado) VALUES ('PRUEBA directa', 'DIRECTO', CURRENT_DATE, 1000) RETURNING id_campana INTO v_x;
    v_ok := FALSE;
    BEGIN
        UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_x;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A6-15%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-15 falló'; END IF;
    v_ok := FALSE;
    BEGIN
        UPDATE campanas SET fecha_fin = CURRENT_DATE - 1 WHERE id_campana = v_x;
    EXCEPTION WHEN check_violation THEN v_ok := TRUE; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-10 falló'; END IF;

    -- RN-A6-09: actualizado_en lo pone el trigger al editar, aunque la fila traiga un valor viejo
    -- (dentro de una transacción NOW() es constante, por eso se parte de una marca antigua)
    UPDATE campanas SET actualizado_en = TIMESTAMPTZ '2000-01-01' WHERE id_campana = v_x;
    SELECT actualizado_en INTO v_ts FROM campanas WHERE id_campana = v_x;
    IF v_ts = TIMESTAMPTZ '2000-01-01' THEN RAISE EXCEPTION 'RN-A6-09 falló: el trigger dejó pasar un valor escrito a mano'; END IF;
    UPDATE campanas SET objetivo = 'editada' WHERE id_campana = v_x;
    IF (SELECT actualizado_en FROM campanas WHERE id_campana = v_x) < NOW() - INTERVAL '1 minute' THEN RAISE EXCEPTION 'RN-A6-09 falló'; END IF;

    -- RN-A6-13: la campaña FINALIZADA no acepta costos ni métricas
    v_ok := FALSE;
    BEGIN
        INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto) VALUES (v_c, v_redes, 'x', 1, CURRENT_DATE);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A6-13%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-13 falló: costo'; END IF;
    v_ok := FALSE;
    BEGIN
        INSERT INTO metricas_marketing (id_campana, periodo_inicio, periodo_fin) VALUES (v_c, CURRENT_DATE, CURRENT_DATE);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A6-13%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-13 falló: métrica'; END IF;

    -- RN-A6-04: no se borra una campaña con costos (RESTRICT)
    v_ok := FALSE;
    BEGIN
        DELETE FROM campanas WHERE id_campana = v_a;
    EXCEPTION WHEN foreign_key_violation THEN v_ok := TRUE; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A6-04 falló'; END IF;

    -- RN-A6-16: al borrar una campaña sin costos, su investigación se conserva con id_campana nulo (SET NULL)
    INSERT INTO investigaciones_mercado (titulo, tipo, id_campana) VALUES ('PRUEBA investigación', 'OTRO', v_x) RETURNING id_investigacion INTO v_inv;
    DELETE FROM campanas WHERE id_campana = v_x;
    IF (SELECT id_campana FROM investigaciones_mercado WHERE id_investigacion = v_inv) IS NOT NULL THEN RAISE EXCEPTION 'RN-A6-16 falló'; END IF;

    -- v_productos_baja_rotacion_campana lee v_rotacion del área 3 sin error
    SELECT COUNT(*) INTO v_n FROM v_productos_baja_rotacion_campana;
    IF v_n IS NULL THEN RAISE EXCEPTION 'v_productos_baja_rotacion_campana falló'; END IF;

    RAISE NOTICE 'Pruebas del área 6: todas pasaron';
END $$;

ROLLBACK;
