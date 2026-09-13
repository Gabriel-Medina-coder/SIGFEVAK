-- Área 1 · Issue #33 · Pruebas de RN-A1-04 a RN-A1-18
-- Entradas: almacén, lote, moneda, documento, proveedor. Manufactura: orden sin BOM, retroceso, consumo en
-- estado incorrecto, materia fuera del BOM, stock negativo, calidad, doble cierre y costo del ejemplo 10.2.
-- Cada bloque lanza RAISE EXCEPTION si la regla no se cumple. Corre en una transacción que se revierte.
BEGIN;

DO $$
DECLARE
    v_alm_ins INT; v_alm_pt INT; v_prov INT;
    v_prod INT; v_prod2 INT; v_lote_otro INT;
    v_carcasa INT; v_modulo INT; v_cable INT;
    v_orden INT;
    v_ok BOOLEAN; v_txt TEXT; v_num DECIMAL; v_int INT;
BEGIN
    -- Escenario propio, aislado del seed
    INSERT INTO almacenes (nombre, tipo) VALUES ('PRUEBA insumos', 'INSUMOS') RETURNING id_almacen INTO v_alm_ins;
    SELECT id_almacen INTO v_alm_pt FROM almacenes WHERE tipo = 'PRODUCTO_TERMINADO' AND activo ORDER BY id_almacen LIMIT 1;
    INSERT INTO proveedores (nombre, rfc) VALUES ('PRUEBA Proveedor SA', 'PRU010101AB1') RETURNING id_proveedor INTO v_prov;
    INSERT INTO productos (tipo, nombre, sku) VALUES ('MANUFACTURA', 'PRUEBA kit', 'PRUEBA-KIT') RETURNING id_producto INTO v_prod;
    INSERT INTO productos (tipo, nombre, sku) VALUES ('ELECTRONICO', 'PRUEBA otro', 'PRUEBA-OTRO') RETURNING id_producto INTO v_prod2;
    INSERT INTO lotes (id_producto, numero_lote) VALUES (v_prod2, 'L-OTRO') RETURNING id_lote INTO v_lote_otro;

    -- RN-A1-06: entrada a almacén de insumos falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, id_almacen, numero_orden_compra)
        VALUES (v_prod, 10, 100, v_alm_ins, 'OC-PRUEBA');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-06%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-06 falló: aceptó entrada a almacén de insumos'; END IF;

    -- RN-A1-05: lote de otro producto falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, id_almacen, id_lote, numero_orden_compra)
        VALUES (v_prod, 10, 100, v_alm_pt, v_lote_otro, 'OC-PRUEBA');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-05%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-05 falló: aceptó lote de otro producto'; END IF;

    -- RN-A1-07: USD con tipo de cambio 1 falla por CHECK
    v_ok := FALSE;
    BEGIN
        INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, moneda, tipo_cambio, numero_orden_compra)
        VALUES (v_prod, 10, 100, 'USD', 1, 'OC-PRUEBA');
    EXCEPTION WHEN check_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-07 falló: aceptó USD con tipo de cambio 1'; END IF;

    -- RN-A1-18: entrada con almacén y sin documento de respaldo falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, id_almacen) VALUES (v_prod, 10, 100, v_alm_pt);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-18%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-18 falló: aceptó entrada sin documento'; END IF;

    -- RN-A1-04 y RN-A1-08: entrada válida copia el nombre del proveedor y el capital sigue la fórmula (ejemplo 10.1)
    INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, flete_unitario, id_proveedor, id_almacen, numero_factura_proveedor)
    VALUES (v_prod, 100, 200, 20, v_prov, v_alm_pt, 'F-PRUEBA');
    SELECT proveedor INTO v_txt FROM entradas_producto WHERE numero_factura_proveedor = 'F-PRUEBA';
    IF v_txt <> 'PRUEBA Proveedor SA' THEN RAISE EXCEPTION 'RN-A1-04 falló: proveedor = %', v_txt; END IF;
    SELECT capital_entrada_mxn INTO v_num FROM v_entradas_detalle WHERE numero_factura_proveedor = 'F-PRUEBA';
    IF v_num <> 22000 THEN RAISE EXCEPTION 'RN-A1-08 falló: capital = %', v_num; END IF;
    SELECT capital_inversion INTO v_num FROM productos WHERE id_producto = v_prod;
    IF v_num <> 22000 THEN RAISE EXCEPTION 'I-01 falló: capital_inversion = %', v_num; END IF;

    -- ---------- Manufactura ----------
    -- RN-A1-06: materia prima en almacén de producto terminado falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO materias_primas (sku, nombre, id_almacen) VALUES ('PRUEBA-MP-X', 'x', v_alm_pt);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-06%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-06 falló: aceptó materia en almacén de producto terminado'; END IF;

    INSERT INTO materias_primas (sku, nombre, id_almacen) VALUES ('PRUEBA-CARCASA', 'Carcasa', v_alm_ins) RETURNING id_materia INTO v_carcasa;
    INSERT INTO materias_primas (sku, nombre, id_almacen) VALUES ('PRUEBA-MODULO',  'Módulo',  v_alm_ins) RETURNING id_materia INTO v_modulo;
    INSERT INTO materias_primas (sku, nombre, id_almacen) VALUES ('PRUEBA-CABLE',   'Cable',   v_alm_ins) RETURNING id_materia INTO v_cable;
    INSERT INTO entradas_materia_prima (id_materia, cantidad, costo_unitario) VALUES (v_carcasa, 60, 85), (v_modulo, 50, 140), (v_cable, 10, 12.5);
    SELECT stock INTO v_num FROM materias_primas WHERE id_materia = v_carcasa;
    IF v_num <> 60 THEN RAISE EXCEPTION 'fn_entrada_materia falló: stock = %', v_num; END IF;

    -- RN-A1-10: orden para producto sin BOM falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO ordenes_produccion (folio, id_producto_destino, cantidad_planeada, fecha_inicio_programada, fecha_fin_programada, responsable)
        VALUES ('OP-PRUEBA-0', v_prod, 50, CURRENT_DATE, CURRENT_DATE, 'Ana');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-10%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-10 falló: aceptó orden sin BOM'; END IF;

    INSERT INTO bom (id_producto_destino, id_materia, cantidad_por_unidad) VALUES (v_prod, v_carcasa, 1), (v_prod, v_modulo, 1);
    INSERT INTO ordenes_produccion (folio, id_producto_destino, cantidad_planeada, fecha_inicio_programada, fecha_fin_programada, responsable)
    VALUES ('OP-PRUEBA-1', v_prod, 50, CURRENT_DATE, CURRENT_DATE, 'Ana') RETURNING id_orden INTO v_orden;

    -- RN-A1-13: consumo en orden PLANEADA falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real) VALUES (v_orden, v_carcasa, 1);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-13%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-13 falló: aceptó consumo en orden planeada'; END IF;

    -- RN-A1-11: saltar PLANEADA → EN_CALIDAD falla
    v_ok := FALSE;
    BEGIN
        UPDATE ordenes_produccion SET estado = 'EN_CALIDAD' WHERE id_orden = v_orden;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-11%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-11 falló: aceptó salto de estado'; END IF;

    UPDATE ordenes_produccion SET estado = 'EN_PROCESO' WHERE id_orden = v_orden;

    -- RN-A1-14: materia fuera del BOM falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real) VALUES (v_orden, v_cable, 1);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-14%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-14 falló: aceptó materia fuera del BOM'; END IF;

    -- RN-A1-09: consumo mayor al stock falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real) VALUES (v_orden, v_carcasa, 61);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-09%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-09 falló: aceptó stock negativo'; END IF;

    -- Consumos del ejemplo 10.2
    INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real, merma, motivo_merma) VALUES (v_orden, v_carcasa, 52, 2, 'carcasa rayada');
    INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real) VALUES (v_orden, v_modulo, 50);
    SELECT stock INTO v_num FROM materias_primas WHERE id_materia = v_carcasa;
    IF v_num <> 8 THEN RAISE EXCEPTION 'RN-A1-09 falló: stock de carcasa = %', v_num; END IF;

    -- RN-A1-11: retroceso EN_PROCESO → PLANEADA falla
    v_ok := FALSE;
    BEGIN
        UPDATE ordenes_produccion SET estado = 'PLANEADA' WHERE id_orden = v_orden;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-11%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-11 falló: aceptó retroceso'; END IF;

    -- RN-A1-12: terminar sin control de calidad falla
    UPDATE ordenes_produccion SET estado = 'EN_CALIDAD', costo_mano_obra = 2500, costos_indirectos = 580 WHERE id_orden = v_orden;
    v_ok := FALSE;
    BEGIN
        UPDATE ordenes_produccion SET estado = 'TERMINADA' WHERE id_orden = v_orden;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-12%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-12 falló: terminó sin calidad'; END IF;

    -- RN-A1-16: inspector igual al responsable de la orden falla
    v_ok := FALSE;
    BEGIN
        INSERT INTO control_calidad (id_orden, aprobadas, rechazadas, responsable) VALUES (v_orden, 48, 0, 'Ana');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-16%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-16 falló: aceptó al mismo responsable'; END IF;

    -- RN-A1-15: totales mayores a lo planeado fallan; rechazadas sin motivo falla por CHECK
    v_ok := FALSE;
    BEGIN
        INSERT INTO control_calidad (id_orden, aprobadas, rechazadas, motivo_rechazo, responsable) VALUES (v_orden, 49, 2, 'x', 'Beto');
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-15%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-15 falló: aceptó totales mayores a lo planeado'; END IF;
    v_ok := FALSE;
    BEGIN
        INSERT INTO control_calidad (id_orden, aprobadas, rechazadas, responsable) VALUES (v_orden, 48, 2, 'Beto');
    EXCEPTION WHEN check_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-15 falló: aceptó rechazadas sin motivo'; END IF;

    INSERT INTO control_calidad (id_orden, aprobadas, rechazadas, motivo_rechazo, responsable) VALUES (v_orden, 48, 2, 'no enciende', 'Beto');
    IF (SELECT resultado FROM control_calidad WHERE id_orden = v_orden) <> 'APROBADO' THEN
        RAISE EXCEPTION 'fn_valida_calidad falló: resultado incorrecto';
    END IF;

    -- RN-A1-17: cierre con costo unitario 302.08 y entrada de 48 (ejemplo 10.2)
    UPDATE ordenes_produccion SET estado = 'TERMINADA' WHERE id_orden = v_orden;
    SELECT costo_unitario, cantidad INTO v_num, v_int FROM entradas_producto WHERE id_orden_produccion = v_orden;
    IF v_num <> 302.08 OR v_int <> 48 THEN RAISE EXCEPTION 'RN-A1-17 falló: costo % cantidad %', v_num, v_int; END IF;
    IF (SELECT proveedor FROM entradas_producto WHERE id_orden_produccion = v_orden) <> 'PRODUCCIÓN INTERNA' THEN
        RAISE EXCEPTION 'RN-A1-12 falló: proveedor incorrecto';
    END IF;
    IF (SELECT cantidad_terminada FROM ordenes_produccion WHERE id_orden = v_orden) <> 48 THEN
        RAISE EXCEPTION 'fn_cerrar_orden falló: cantidad_terminada';
    END IF;
    -- El trigger del área 3 subió el stock del producto terminado: 100 de la entrada + 48 de la orden
    SELECT stock INTO v_int FROM productos WHERE id_producto = v_prod;
    IF v_int <> 148 THEN RAISE EXCEPTION 'Integración con área 3 falló: stock = %', v_int; END IF;

    -- RN-A1-11 / RN-A1-12: doble cierre falla
    v_ok := FALSE;
    BEGIN
        UPDATE ordenes_produccion SET estado = 'CANCELADA' WHERE id_orden = v_orden;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A1-11%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A1-11 falló: modificó una orden terminada'; END IF;

    RAISE NOTICE 'Pruebas del área 1: todas pasaron';
END $$;

ROLLBACK;
