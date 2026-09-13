-- Área 5 · Issue #97 · Pruebas de RN-A5-04, RN-A5-05, RN-A5-06, RN-A5-07, RN-A5-10, RN-A5-12, RN-A5-16 a RN-A5-19,
-- RN-A5-21, RN-A5-22, RN-A5-24 y de los ejemplos 10.1 y 10.2 sobre el seed. Corre en una transacción que se revierte.
BEGIN;

DO $$
DECLARE
    v_contador UUID; v_autorizador UUID; v_gerente UUID; v_tipo_iva INT; v_tipo_ped INT;
    v_obl INT; v_pago INT; v_imp INT; v_ok BOOLEAN; v_num DECIMAL; v_num2 DECIMAL; v_txt TEXT; v_n INT;
BEGIN
    SELECT id_usuario INTO v_contador    FROM usuarios WHERE correo = 'contador@sigfevak.mx';
    SELECT id_usuario INTO v_autorizador FROM usuarios WHERE correo = 'autorizador@sigfevak.mx';
    SELECT id_usuario INTO v_gerente     FROM usuarios WHERE correo = 'gerente@sigfevak.mx';
    SELECT id_tipo_obligacion INTO v_tipo_iva FROM tipos_obligacion WHERE clave = 'IVA_MENSUAL';
    SELECT id_tipo_obligacion INTO v_tipo_ped FROM tipos_obligacion WHERE clave = 'PEDIMENTO';

    -- ---------- Ejemplo 10.1 sobre el seed: IVA de julio cerrada con 110,000 ----------
    SELECT o.estado::TEXT, o.monto_final INTO v_txt, v_num FROM obligaciones o WHERE o.id_tipo_obligacion = v_tipo_iva AND o.periodo = '2026-07';
    IF v_txt <> 'CERRADO' OR v_num <> 110000 THEN RAISE EXCEPTION 'Ejemplo 10.1 falló: % %', v_txt, v_num; END IF;

    -- ---------- Ejemplo 10.2 sobre el seed: pedimento de 200 tabletas ----------
    SELECT igi, dta, iva_importacion, total_contribuciones INTO v_num, v_num2, v_txt, v_n FROM importaciones WHERE numero_pedimento = '26 47 3891 6004520';
    IF v_num <> 75000 OR v_num2 <> 4000 OR v_txt::DECIMAL <> 92640 OR v_n <> 171640 THEN
        RAISE EXCEPTION 'Ejemplo 10.2 falló: igi % dta % iva % total %', v_num, v_num2, v_txt, v_n;
    END IF;
    SELECT impuestos_por_unidad_sin_iva INTO v_num FROM v_impuestos_importacion_producto WHERE numero_pedimento = '26 47 3891 6004520';
    IF v_num <> 395 THEN RAISE EXCEPTION 'Ejemplo 10.2 falló: impuestos por unidad = %', v_num; END IF;
    SELECT monto_estimado INTO v_num FROM obligaciones o JOIN importaciones i USING (id_obligacion) WHERE i.numero_pedimento = '26 47 3891 6004520';
    IF v_num <> 171640 THEN RAISE EXCEPTION 'El monto de la obligación del pedimento no se actualizó: %', v_num; END IF;

    -- RN-A5-16: la obligación de ISR de julio quedó VENCIDO y tiene alerta VENCIDA (RN-A5-21)
    SELECT o.id_obligacion INTO v_obl FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion) WHERE t.clave = 'ISR_PROV' AND o.periodo = '2026-07';
    IF (SELECT estado FROM obligaciones WHERE id_obligacion = v_obl) <> 'VENCIDO' THEN RAISE EXCEPTION 'RN-A5-16 falló'; END IF;
    IF NOT EXISTS (SELECT 1 FROM alertas WHERE id_obligacion = v_obl AND nivel = 'VENCIDA') THEN RAISE EXCEPTION 'RN-A5-21 falló: sin alerta VENCIDA'; END IF;
    -- RN-A5-21: volver a generar no duplica
    SELECT COUNT(*) INTO v_n FROM alertas;
    PERFORM fn_generar_alertas();
    IF (SELECT COUNT(*) FROM alertas) <> v_n THEN RAISE EXCEPTION 'RN-A5-21 falló: alertas duplicadas'; END IF;

    -- ---------- Máquina de estados con una obligación propia ----------
    INSERT INTO obligaciones (id_tipo_obligacion, periodo, fecha_vencimiento, id_responsable)
    VALUES (v_tipo_iva, '2030-01', DATE '2030-02-17', v_contador) RETURNING id_obligacion INTO v_obl;

    -- RN-A5-19: saltar a PRESENTADO se rechaza; CALCULADO sin monto se rechaza
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-19%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-19 falló: aceptó salto'; END IF;
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-19%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-19 falló: CALCULADO sin monto'; END IF;

    UPDATE obligaciones SET estado = 'CALCULADO', monto_estimado = 50000 WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_obl;

    -- RN-A5-18: el responsable no se autoriza a sí mismo (CHECK); RN-A5-06: un gerente no autoriza una crítica
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = v_contador WHERE id_obligacion = v_obl;
    EXCEPTION WHEN check_violation THEN v_ok := TRUE; WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-18%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-18 falló'; END IF;
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = v_gerente WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-06%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-06 falló'; END IF;

    -- RN-A5-19: rechazo sin comentario se rechaza; con comentario regresa a CALCULADO
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-19%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-19 falló: rechazo sin comentario'; END IF;
    UPDATE obligaciones SET estado = 'CALCULADO', comentario = 'Línea de captura con importe distinto' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = v_autorizador WHERE id_obligacion = v_obl;
    IF (SELECT monto_final FROM obligaciones WHERE id_obligacion = v_obl) <> 50000 THEN RAISE EXCEPTION 'RN-A5-23 falló: monto_final no se congeló'; END IF;

    -- RN-A5-23: el monto congelado no cambia
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET monto_final = 1 WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-23%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-23 falló'; END IF;

    -- RN-A5-04: PAGADO sin pago se rechaza
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-04%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-04 falló'; END IF;

    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, referencia, metodo_pago, id_registrado_por, id_autorizado_por)
    VALUES (v_obl, CURRENT_DATE, 30000, 'REF-PRUEBA-1', 'SPEI', v_contador, v_autorizador) RETURNING id_pago INTO v_pago;
    UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = v_obl;

    -- RN-A5-05: conciliar con pagos incompletos se rechaza; RN-A5-07: sin comprobante se rechaza
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-05%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-05 falló'; END IF;
    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, referencia, metodo_pago, id_registrado_por, id_autorizado_por)
    VALUES (v_obl, CURRENT_DATE, 20000, 'REF-PRUEBA-2', 'SPEI', v_contador, v_autorizador);
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-07%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-07 falló'; END IF;
    INSERT INTO documentos_fiscales (id_obligacion, id_pago, tipo_documento, nombre, referencia) VALUES (v_obl, v_pago, 'COMPROBANTE_BANCARIO', 'Comprobante', 'docs/x.pdf');
    UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'CERRADO' WHERE id_obligacion = v_obl;
    IF (SELECT fecha_cierre FROM obligaciones WHERE id_obligacion = v_obl) IS NULL THEN RAISE EXCEPTION 'CERRADO no puso fecha_cierre'; END IF;

    -- RN-A5-24: cerrada inmutable, también sus pagos y documentos
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET comentario = 'x' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-24%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-24 falló: obligación'; END IF;
    v_ok := FALSE;
    BEGIN INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, referencia, metodo_pago, id_registrado_por) VALUES (v_obl, CURRENT_DATE, 1, 'x', 'SPEI', v_contador);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-24%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-24 falló: pago'; END IF;

    -- RN-A5-22: DELETE se convierte en baja lógica
    INSERT INTO obligaciones (id_tipo_obligacion, periodo, fecha_vencimiento, id_responsable)
    VALUES (v_tipo_iva, '2030-02', DATE '2030-03-17', v_contador) RETURNING id_obligacion INTO v_obl;
    DELETE FROM obligaciones WHERE id_obligacion = v_obl;
    IF NOT EXISTS (SELECT 1 FROM obligaciones WHERE id_obligacion = v_obl AND NOT activo) THEN RAISE EXCEPTION 'RN-A5-22 falló'; END IF;
    IF NOT EXISTS (SELECT 1 FROM bitacora_fiscal WHERE tabla = 'obligaciones' AND id_registro = v_obl AND accion = 'BAJA') THEN RAISE EXCEPTION 'RN-A5-17 falló: baja sin bitácora'; END IF;

    -- RN-A5-16: una obligación vencida pasa a VENCIDO y solo sale a PAGADO
    INSERT INTO obligaciones (id_tipo_obligacion, periodo, fecha_vencimiento, id_responsable, monto_estimado)
    VALUES (v_tipo_iva, '2020-01', DATE '2020-02-17', v_contador, 100) RETURNING id_obligacion INTO v_obl;
    PERFORM fn_marcar_vencidas();
    IF (SELECT estado FROM obligaciones WHERE id_obligacion = v_obl) <> 'VENCIDO' THEN RAISE EXCEPTION 'RN-A5-16 falló: no marcó VENCIDO'; END IF;
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-19%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-19 falló: VENCIDO salió a otro estado'; END IF;

    -- ---------- Importaciones ----------
    INSERT INTO obligaciones (id_tipo_obligacion, fecha_vencimiento, id_responsable) VALUES (v_tipo_ped, CURRENT_DATE, v_contador) RETURNING id_obligacion INTO v_obl;
    INSERT INTO importaciones (id_obligacion, numero_pedimento, aduana, pais_origen, pais_procedencia, fecha_importacion, valor_aduanero)
    VALUES (v_obl, 'PRUEBA-PED', 'Manzanillo', 'China', 'China', CURRENT_DATE, 10000) RETURNING id_importacion INTO v_imp;
    -- RN-A5-12: fracción sin tasa se rechaza
    v_ok := FALSE;
    BEGIN INSERT INTO productos_importados (id_importacion, nombre, cantidad, valor_unitario, fraccion_arancelaria) VALUES (v_imp, 'x', 1, 10000, '0000.00.00');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-12%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-12 falló'; END IF;
    -- RN-A5-10: sin fracción no sale de CALCULADO
    INSERT INTO productos_importados (id_importacion, nombre, cantidad, valor_unitario) VALUES (v_imp, 'Producto sin fracción', 1, 10000);
    UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    v_ok := FALSE;
    BEGIN UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-10%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-10 falló'; END IF;
    -- RN-A5-13: al fijar la fracción se congela la tasa y se recalculan IGI, DTA e IVA
    UPDATE productos_importados SET fraccion_arancelaria = '8471.30.01' WHERE id_importacion = v_imp;
    SELECT igi, dta, iva_importacion INTO v_num, v_num2, v_txt FROM importaciones WHERE id_importacion = v_imp;
    IF v_num <> 1500 OR v_num2 <> 80 OR v_txt::DECIMAL <> ROUND((10000 + 1500 + 80) * 0.16, 2) THEN
        RAISE EXCEPTION 'RN-A5-13 falló: igi % dta % iva %', v_num, v_num2, v_txt;
    END IF;
    -- RN-A5-08: una importación sobre una obligación que no es PEDIMENTO se rechaza
    v_ok := FALSE;
    BEGIN
        INSERT INTO importaciones (id_obligacion, numero_pedimento, aduana, pais_origen, pais_procedencia, fecha_importacion, valor_aduanero)
        SELECT id_obligacion, 'PRUEBA-PED-2', 'x', 'x', 'x', CURRENT_DATE, 1 FROM obligaciones WHERE id_tipo_obligacion = v_tipo_iva LIMIT 1;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A5-08%' THEN v_ok := TRUE; ELSE RAISE; END IF; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-08 falló'; END IF;

    -- RN-A5-15: uso de suelo sin municipio se rechaza
    v_ok := FALSE;
    BEGIN INSERT INTO licencias_permisos (tipo_licencia, autoridad_emisora) VALUES ('USO_SUELO', 'x');
    EXCEPTION WHEN check_violation THEN v_ok := TRUE; END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A5-15 falló'; END IF;

    RAISE NOTICE 'Pruebas del área 5: todas pasaron';
END $$;

ROLLBACK;
