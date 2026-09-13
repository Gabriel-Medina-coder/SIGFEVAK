-- Área 2 · Issue #51 · RN-A2-02, RN-A2-08, RN-A2-09, RN-A2-11
-- Qué hace: completa el seed base (10 clientes, 5 agentes, 15 facturas) con folios y vencimientos para las
-- filas anteriores a la migración, un cliente inactivo, un cliente con 15 días de crédito, renglones para las
-- facturas que no tenían, y 6 facturas nuevas que reproducen el ejemplo de la sección 10 (FAC-000016) y el
-- del área 4 (Jorge Mendoza cobra $560,000 sin IVA en 2026-09, 2 clientes nuevos, cartera vencida 3 %).
-- Nunca escribe subtotal, iva, valor_total ni folios a mano en las facturas nuevas: los ponen los triggers. Idempotente.

-- ---------- 1. Folios para filas anteriores a la migración (RN-A2-11) ----------
WITH n AS (
    SELECT id_cliente, ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn FROM clientes WHERE numero_comercializador IS NULL
)
UPDATE clientes c SET numero_comercializador = 'COM-' || LPAD(n.rn::TEXT, 6, '0') FROM n WHERE c.id_cliente = n.id_cliente;
SELECT setval('seq_comercializador', GREATEST((SELECT COUNT(*) FROM clientes), 1));

WITH n AS (
    SELECT id_factura, ROW_NUMBER() OVER (ORDER BY id_factura) AS rn FROM facturas WHERE folio IS NULL
)
UPDATE facturas f SET folio = 'FAC-' || LPAD(n.rn::TEXT, 6, '0') FROM n WHERE f.id_factura = n.id_factura;
SELECT setval('seq_folio_factura', GREATEST((SELECT COUNT(*) FROM facturas), 1));

-- ---------- 2. Clientes: uno con 15 días de crédito y uno inactivo ----------
UPDATE clientes SET dias_credito = 15 WHERE rfc = 'ESU110303QR9' AND dias_credito <> 15;

INSERT INTO clientes (nombre_empresa, rfc, estado, activo)
SELECT 'Comercial Antigua del Centro S.A. de C.V.', 'CAC050101UV1', 'Querétaro', FALSE
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE rfc = 'CAC050101UV1');

-- ---------- 3. Vencimiento y fecha de cobro para las facturas anteriores a la migración (RN-A2-08, RN-A2-09) ----------
UPDATE facturas f SET fecha_vencimiento = f.fecha + c.dias_credito
FROM clientes c WHERE c.id_cliente = f.id_cliente AND f.fecha_vencimiento IS NULL;

UPDATE facturas SET fecha_cobro = fecha + 10 WHERE estado_pago = 'PAGADO' AND fecha_cobro IS NULL;

-- ---------- 4. Renglones para las facturas que no tenían (las PAGADO se abren, se cargan y se cierran de nuevo) ----------
DO $$
DECLARE r RECORD; v_estado estado_pago; v_cobro DATE;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            (11, 'Bocina Portátil BT 20W',      80,  900.00),
            (12, 'Cargador USB-C 65W GaN',      150, 330.00),
            (13, 'Monitor LED 24" FHD',         60,  3100.00),
            (14, 'Regulador de voltaje 1200VA', 100, 650.00),
            (15, 'Power bank 20000 mAh',        200, 520.00)
        ) AS v(id_factura, producto, cantidad, precio)
    LOOP
        IF EXISTS (SELECT 1 FROM detalle_factura WHERE id_factura = r.id_factura) THEN CONTINUE; END IF;
        SELECT estado_pago, fecha_cobro INTO v_estado, v_cobro FROM facturas WHERE id_factura = r.id_factura;
        IF v_estado = 'PAGADO' THEN
            UPDATE facturas SET estado_pago = 'PENDIENTE' WHERE id_factura = r.id_factura;
        END IF;
        INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
        SELECT r.id_factura, p.id_producto, r.cantidad, r.precio FROM productos p WHERE p.nombre = r.producto;
        IF v_estado = 'PAGADO' THEN
            UPDATE facturas SET estado_pago = 'PAGADO', fecha_cobro = v_cobro WHERE id_factura = r.id_factura;
        END IF;
    END LOOP;
END $$;

-- ---------- 5. Recalcula subtotal, iva y valor_total de todas las facturas anteriores a la migración (RN-A2-02) ----------
UPDATE facturas f
   SET subtotal    = s.sub,
       iva         = ROUND(s.sub * fn_tasa_iva(), 2),
       valor_total = s.sub + ROUND(s.sub * fn_tasa_iva(), 2)
FROM (SELECT f2.id_factura, COALESCE(SUM(d.importe), 0) AS sub
        FROM facturas f2 LEFT JOIN detalle_factura d USING (id_factura) GROUP BY f2.id_factura) s
WHERE s.id_factura = f.id_factura
  AND (f.subtotal <> s.sub OR f.valor_total <> s.sub + ROUND(s.sub * fn_tasa_iva(), 2));

-- ---------- 6. Facturas nuevas (folio, vencimiento, totales y fecha de cobro los ponen los triggers) ----------
DO $$
DECLARE v_id INT; v_cli INT; v_ag INT; v_prod INT;
BEGIN
    IF EXISTS (SELECT 1 FROM facturas WHERE folio = 'FAC-000016') THEN RETURN; END IF;

    -- FAC-000016 · ejemplo de la sección 10: Distribuidora Bajío, Jorge Mendoza, 10 tabletas a 1,850 y 25 cables a 89
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'DBA120614MN7';
    SELECT id_agente INTO v_ag FROM agentes_ventas WHERE nombre = 'Jorge Mendoza';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-09-14') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 10, 1850.00 FROM productos WHERE nombre = 'Tableta Android 10" OEM';
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 25, 89.00 FROM productos WHERE nombre = 'Cable HDMI 2.1 4K 2m';
    UPDATE facturas SET estado_pago = 'PAGADO', fecha_cobro = DATE '2026-09-20' WHERE id_factura = v_id;

    -- FAC-000017 · Norte Digital (cliente nuevo para Jorge), 50 routers a 1,500 y 25 monitores a 1,411 = 110,275
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'NDI160228KL6';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-09-08') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 50, 1500.00 FROM productos WHERE nombre = 'Router Wi-Fi 6 AX1800';
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 25, 1411.00 FROM productos WHERE nombre = 'Monitor LED 24" FHD';
    UPDATE facturas SET estado_pago = 'PAGADO', fecha_cobro = DATE '2026-09-12' WHERE id_factura = v_id;

    -- FAC-000018 · TechMex (ya le compró en agosto), 130 smartwatch a 3,300 = 429,000
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'TCD190405IJ5';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-09-04') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 130, 3300.00 FROM productos WHERE nombre = 'Smartwatch Fitness Pro';
    UPDATE facturas SET estado_pago = 'PAGADO', fecha_cobro = DATE '2026-09-15' WHERE id_factura = v_id;

    -- FAC-000019 · COPPEL, vencida (fecha 2026-08-01, vence 2026-08-31), 12 power bank a 850 = 10,200
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'CDI980722CD2';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-08-01') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 12, 850.00 FROM productos WHERE nombre = 'Power bank 20000 mAh';

    -- FAC-000020 · Mayoreo Pacífico, pendiente vigente, 6 cables a 100 = 600
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'MPA090917ST0';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-09-11') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 6, 100.00 FROM productos WHERE nombre = 'Cable HDMI 2.1 4K 2m';

    -- FAC-000021 · Ramírez & Hijos con Andrés Fuentes, vencida (fecha 2026-07-20), 30 reguladores a 620 = 18,600
    SELECT id_cliente INTO v_cli FROM clientes WHERE rfc = 'RHC001120OP8';
    SELECT id_agente INTO v_ag FROM agentes_ventas WHERE nombre = 'Andrés Fuentes';
    INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (v_cli, v_ag, DATE '2026-07-20') RETURNING id_factura INTO v_id;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    SELECT v_id, id_producto, 30, 620.00 FROM productos WHERE nombre = 'Regulador de voltaje 1200VA';
END $$;
