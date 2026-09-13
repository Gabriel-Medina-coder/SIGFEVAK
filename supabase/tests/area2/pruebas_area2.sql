-- Área 2 · Issue #52 · Pruebas de RN-A2-02 a RN-A2-12
-- Recálculo (insertar, editar, borrar, borrar el último), estado de pago y fecha de cobro, folios, vencimiento,
-- baja lógica, factura cerrada, RFC y rechazo por stock del área 3. Cada bloque lanza RAISE EXCEPTION si la
-- regla no se cumple. Corre en una transacción que se revierte.
BEGIN;

DO $$
DECLARE
    v_cli INT; v_cli_baja INT; v_ag INT; v_fac INT; v_det INT;
    v_tab INT; v_cab INT; v_cam INT;
    v_folio TEXT; v_com TEXT; v_txt TEXT; v_num DECIMAL; v_num2 DECIMAL; v_num3 DECIMAL; v_fecha DATE;
    v_ok BOOLEAN;
BEGIN
    SELECT id_agente INTO v_ag FROM agentes_ventas WHERE nombre = 'Jorge Mendoza';
    SELECT id_producto INTO v_tab FROM productos WHERE nombre = 'Tableta Android 10" OEM';
    SELECT id_producto INTO v_cab FROM productos WHERE nombre = 'Cable HDMI 2.1 4K 2m';
    SELECT id_producto INTO v_cam FROM productos WHERE nombre = 'Cámara IP WiFi 1080p';

    -- RN-A2-05: RFC inválido se rechaza por CHECK
    v_ok := FALSE;
    BEGIN
        INSERT INTO clientes (nombre_empresa, rfc) VALUES ('PRUEBA RFC malo', 'ABC12');
    EXCEPTION WHEN check_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A2-05 falló: aceptó RFC inválido'; END IF;

    -- RN-A2-05: RFC duplicado se rechaza por UNIQUE
    v_ok := FALSE;
    BEGIN
        INSERT INTO clientes (nombre_empresa, rfc) VALUES ('PRUEBA RFC duplicado', 'EMA150312AB1');
    EXCEPTION WHEN unique_violation THEN v_ok := TRUE;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A2-05 falló: aceptó RFC duplicado'; END IF;

    -- RN-A2-11: folio de comercializador generado y consecutivo
    INSERT INTO clientes (nombre_empresa, rfc, dias_credito) VALUES ('PRUEBA Cliente SA', 'PRU010101AB1', 20)
    RETURNING id_cliente, numero_comercializador INTO v_cli, v_com;
    IF v_com !~ '^COM-[0-9]{6}$' THEN RAISE EXCEPTION 'RN-A2-11 falló: folio de cliente = %', v_com; END IF;

    -- RN-A2-09, RN-A2-11: folio de factura y vencimiento = fecha + dias_credito
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-09-14')
    RETURNING id_factura, folio, fecha_vencimiento, valor_total INTO v_fac, v_folio, v_fecha, v_num;
    IF v_folio !~ '^FAC-[0-9]{6}$' THEN RAISE EXCEPTION 'RN-A2-11 falló: folio = %', v_folio; END IF;
    IF v_fecha <> DATE '2026-10-04' THEN RAISE EXCEPTION 'RN-A2-09 falló: vencimiento = %', v_fecha; END IF;
    IF v_num <> 0 THEN RAISE EXCEPTION 'cabecera nueva con total distinto de 0'; END IF;

    -- RN-A2-04: PAGADO con total 0 se rechaza
    v_ok := FALSE;
    BEGIN
        UPDATE facturas SET estado_pago = 'PAGADO' WHERE id_factura = v_fac;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A2-04%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A2-04 falló: pagó una factura vacía'; END IF;

    -- RN-A2-02, RN-A2-03: insertar renglón recalcula (ejemplo de la sección 10)
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES (v_fac, v_tab, 10, 1850.00);
    SELECT subtotal, iva, valor_total INTO v_num, v_num2, v_num3 FROM facturas WHERE id_factura = v_fac;
    IF v_num <> 18500 OR v_num2 <> 2960 OR v_num3 <> 21460 THEN
        RAISE EXCEPTION 'RN-A2-02 falló tras insertar: % % %', v_num, v_num2, v_num3;
    END IF;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES (v_fac, v_cab, 25, 89.00) RETURNING id_detalle INTO v_det;
    SELECT subtotal, iva, valor_total INTO v_num, v_num2, v_num3 FROM facturas WHERE id_factura = v_fac;
    IF v_num <> 20725 OR v_num2 <> 3316 OR v_num3 <> 24041 THEN
        RAISE EXCEPTION 'RN-A2-02 falló tras segundo renglón: % % %', v_num, v_num2, v_num3;
    END IF;

    -- RN-A3-01 desde el área 2: renglón mayor al stock se rechaza y la factura no cambia
    v_ok := FALSE;
    BEGIN
        INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES (v_fac, v_cam, 500, 1200.00);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A3-01%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'Rechazo por stock falló'; END IF;
    SELECT valor_total INTO v_num3 FROM facturas WHERE id_factura = v_fac;
    IF v_num3 <> 24041 THEN RAISE EXCEPTION 'La factura cambió tras un renglón rechazado: %', v_num3; END IF;

    -- RN-A2-02: editar cantidad recalcula; borrar renglón recalcula
    UPDATE detalle_factura SET cantidad = 50 WHERE id_detalle = v_det;
    SELECT subtotal INTO v_num FROM facturas WHERE id_factura = v_fac;
    IF v_num <> 22950 THEN RAISE EXCEPTION 'RN-A2-02 falló tras editar: %', v_num; END IF;
    DELETE FROM detalle_factura WHERE id_detalle = v_det;
    SELECT subtotal, valor_total INTO v_num, v_num3 FROM facturas WHERE id_factura = v_fac;
    IF v_num <> 18500 OR v_num3 <> 21460 THEN RAISE EXCEPTION 'RN-A2-02 falló tras borrar: % %', v_num, v_num3; END IF;

    -- RN-A2-08: PAGADO llena fecha_cobro; regresar a PENDIENTE la limpia
    UPDATE facturas SET estado_pago = 'PAGADO' WHERE id_factura = v_fac;
    SELECT fecha_cobro INTO v_fecha FROM facturas WHERE id_factura = v_fac;
    IF v_fecha <> CURRENT_DATE THEN RAISE EXCEPTION 'RN-A2-08 falló: fecha_cobro = %', v_fecha; END IF;

    -- RN-A2-12: renglones de factura PAGADO no se tocan
    v_ok := FALSE;
    BEGIN
        UPDATE detalle_factura SET cantidad = 11 WHERE id_factura = v_fac;
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A2-12%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A2-12 falló: editó renglón de factura pagada'; END IF;

    UPDATE facturas SET estado_pago = 'PENDIENTE' WHERE id_factura = v_fac;
    SELECT fecha_cobro INTO v_fecha FROM facturas WHERE id_factura = v_fac;
    IF v_fecha IS NOT NULL THEN RAISE EXCEPTION 'RN-A2-08 falló: fecha_cobro no se limpió'; END IF;

    -- RN-A2-02: borrar el último renglón deja la factura en 0
    DELETE FROM detalle_factura WHERE id_factura = v_fac;
    SELECT subtotal, iva, valor_total INTO v_num, v_num2, v_num3 FROM facturas WHERE id_factura = v_fac;
    IF v_num <> 0 OR v_num2 <> 0 OR v_num3 <> 0 THEN RAISE EXCEPTION 'RN-A2-02 falló al vaciar: % % %', v_num, v_num2, v_num3; END IF;

    -- RN-A2-10: cliente dado de baja no recibe facturas
    UPDATE clientes SET activo = FALSE WHERE id_cliente = v_cli;
    v_ok := FALSE;
    BEGIN
        INSERT INTO facturas (id_cliente, id_agente) VALUES (v_cli, v_ag);
    EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'RN-A2-10%' THEN v_ok := TRUE; ELSE RAISE; END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'RN-A2-10 falló: facturó a cliente inactivo'; END IF;
    IF EXISTS (SELECT 1 FROM v_clientes_activos WHERE id_cliente = v_cli) THEN
        RAISE EXCEPTION 'RN-A2-10 falló: cliente inactivo aparece en v_clientes_activos';
    END IF;

    RAISE NOTICE 'Pruebas del área 2: todas pasaron';
END $$;

ROLLBACK;
