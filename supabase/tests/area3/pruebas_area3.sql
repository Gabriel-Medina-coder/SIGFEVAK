-- Área 3 · Issue #10 · Pruebas de RN-A3-01, RN-A3-04, RN-A3-05, RN-A3-07, RN-A3-08
-- Cada bloque falla con RAISE EXCEPTION si la regla no se cumple. Corre dentro de una transacción
-- que se revierte al final: no deja datos.
BEGIN;

DO $$
DECLARE
    v_id INT;
    v_stock INT; v_volumen INT; v_capital DECIMAL; v_valor DECIMAL;
    v_ok BOOLEAN;
BEGIN
    INSERT INTO productos (tipo, nombre) VALUES ('ELECTRONICO', 'PRUEBA producto temporal') RETURNING id_producto INTO v_id;

    -- RN-A3-04: cantidad debe ser > 0 en entradas
    v_ok := FALSE;
    BEGIN
        INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario) VALUES (v_id, 0, 10);
    EXCEPTION WHEN check_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A3-04 falló: se permitió una entrada con cantidad 0'; END IF;

    -- RN-A3-05 y RN-A3-08 con la fórmula de I-01: entrada de 100 a $200 + flete $20 → capital 22,000, valor 220
    INSERT INTO entradas_producto (id_producto, cantidad, costo_unitario, flete_unitario) VALUES (v_id, 100, 200, 20);
    SELECT stock, volumen, capital_inversion, valor_entrada INTO v_stock, v_volumen, v_capital, v_valor
      FROM productos WHERE id_producto = v_id;
    IF v_stock <> 100 OR v_volumen <> 100 THEN RAISE EXCEPTION 'RN-A3-05 falló: stock % volumen %', v_stock, v_volumen; END IF;
    IF v_capital <> 22000 OR v_valor <> 220 THEN RAISE EXCEPTION 'I-01 falló: capital % valor %', v_capital, v_valor; END IF;

    -- RN-A3-01: una salida mayor al stock se rechaza con el mensaje de la regla
    v_ok := FALSE;
    BEGIN
        INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
        VALUES ((SELECT MIN(id_factura) FROM facturas), v_id, 101, 300);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'RN-A3-01%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A3-01 falló: se permitió stock negativo'; END IF;

    -- Salida válida descuenta stock pero no volumen (RN-A3-05)
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    VALUES ((SELECT MIN(id_factura) FROM facturas), v_id, 30, 300);
    SELECT stock, volumen INTO v_stock, v_volumen FROM productos WHERE id_producto = v_id;
    IF v_stock <> 70 OR v_volumen <> 100 THEN RAISE EXCEPTION 'Salida falló: stock % volumen %', v_stock, v_volumen; END IF;

    -- RN-A3-07: el ajuste congela stock_sistema, calcula la diferencia y alinea el stock
    INSERT INTO ajustes_inventario (id_producto, conteo_fisico, motivo) VALUES (v_id, 68, 'prueba');
    SELECT stock INTO v_stock FROM productos WHERE id_producto = v_id;
    IF v_stock <> 68 THEN RAISE EXCEPTION 'RN-A3-07 falló: stock % tras ajuste', v_stock; END IF;
    IF (SELECT diferencia FROM ajustes_inventario WHERE id_producto = v_id) <> -2 THEN
        RAISE EXCEPTION 'RN-A3-07 falló: diferencia incorrecta';
    END IF;
    IF (SELECT stock_sistema FROM ajustes_inventario WHERE id_producto = v_id) <> 70 THEN
        RAISE EXCEPTION 'RN-A3-07 falló: stock_sistema no se congeló';
    END IF;

    RAISE NOTICE 'Pruebas del área 3: todas pasaron';
END $$;

ROLLBACK;
