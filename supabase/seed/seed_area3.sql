-- Área 3 · Issue #9 · RN-A3-04, RN-A3-06
-- Qué hace: 20 productos, 12 entradas y 10 renglones de factura (salidas) sobre las facturas del seed base.
-- Nunca escribe productos.stock: lo mueven los triggers. Idempotente.

-- ---------- 20 PRODUCTOS ----------
INSERT INTO productos (tipo, nombre)
SELECT v.tipo::tipo_producto, v.nombre FROM (VALUES
    ('ELECTRONICO', 'Tableta Android 10" OEM'),
    ('ELECTRONICO', 'Smartwatch Fitness Pro'),
    ('ELECTRONICO', 'Auriculares BT TW-55'),
    ('ELECTRONICO', 'Bocina Portátil BT 20W'),
    ('ELECTRONICO', 'Cámara IP WiFi 1080p'),
    ('ELECTRONICO', 'Router Wi-Fi 6 AX1800'),
    ('ELECTRONICO', 'Monitor LED 24" FHD'),
    ('ELECTRONICO', 'Teclado mecánico RGB'),
    ('ELECTRONICO', 'Mouse inalámbrico 2.4G'),
    ('ELECTRONICO', 'Power bank 20000 mAh'),
    ('MANUFACTURA', 'Cable HDMI 2.1 4K 2m'),
    ('MANUFACTURA', 'Cargador USB-C 65W GaN'),
    ('MANUFACTURA', 'Regulador de voltaje 1200VA'),
    ('MANUFACTURA', 'Multicontacto 6 salidas'),
    ('MANUFACTURA', 'Cable USB-C a USB-C 1m'),
    ('MANUFACTURA', 'Base para laptop aluminio'),
    ('MANUFACTURA', 'Funda tablet 10" negra'),
    ('MANUFACTURA', 'Soporte de monitor articulado'),
    ('MANUFACTURA', 'Extensión eléctrica 5m'),
    ('MANUFACTURA', 'Adaptador HDMI a VGA')
) AS v(tipo, nombre)
ON CONFLICT (nombre, tipo) DO NOTHING;

-- ---------- 12 ENTRADAS (el trigger suma stock, volumen y capital) ----------
INSERT INTO entradas_producto (id_producto, fecha, cantidad, costo_unitario, proveedor, documento_ref, flete_unitario, impuestos_unitarios)
SELECT p.id_producto, v.fecha, v.cantidad, v.costo, v.proveedor, v.doc, v.flete, v.imp
FROM (VALUES
    ('Tableta Android 10" OEM',      DATE '2026-08-01', 400,  1850.00, 'Shenzhen Import Co.',      'IMP-2026-081', 40.00, 185.00),
    ('Smartwatch Fitness Pro',       DATE '2026-08-03', 750,  2400.00, 'Shenzhen Import Co.',      'IMP-2026-082', 35.00, 240.00),
    ('Auriculares BT TW-55',         DATE '2026-08-05', 1200, 320.00,  'Guangzhou Audio Ltd.',     'IMP-2026-083', 8.00,  32.00),
    ('Bocina Portátil BT 20W',       DATE '2026-08-08', 500,  610.00,  'Guangzhou Audio Ltd.',     'IMP-2026-084', 12.00, 61.00),
    ('Cable HDMI 2.1 4K 2m',         DATE '2026-08-10', 2000, 89.00,   'Planta interna Querétaro', 'OP-2026-014',  0.00,  0.00),
    ('Cargador USB-C 65W GaN',       DATE '2026-08-12', 3000, 210.00,  'Planta interna Querétaro', 'OP-2026-015',  0.00,  0.00),
    ('Router Wi-Fi 6 AX1800',        DATE '2026-08-15', 300,  1150.00, 'Shenzhen Import Co.',      'IMP-2026-085', 30.00, 115.00),
    ('Monitor LED 24" FHD',          DATE '2026-08-18', 250,  2650.00, 'Electrónica del Norte SA', 'A-5541',       60.00, 0.00),
    ('Regulador de voltaje 1200VA',  DATE '2026-08-20', 600,  480.00,  'Planta interna Querétaro', 'OP-2026-016',  0.00,  0.00),
    ('Multicontacto 6 salidas',      DATE '2026-08-22', 1500, 95.00,   'Planta interna Querétaro', 'OP-2026-017',  0.00,  0.00),
    ('Power bank 20000 mAh',         DATE '2026-09-01', 800,  380.00,  'Electrónica del Norte SA', 'A-5590',       10.00, 0.00),
    ('Tableta Android 10" OEM',      DATE '2026-09-05', 100,  200.00,  'Planta interna Querétaro', 'OP-2026-018',  20.00, 0.00)
) AS v(nombre, fecha, cantidad, costo, proveedor, doc, flete, imp)
JOIN productos p ON p.nombre = v.nombre
WHERE NOT EXISTS (SELECT 1 FROM entradas_producto);

-- ---------- 10 SALIDAS: renglones sobre facturas del seed base (el trigger valida y descuenta stock) ----------
INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
SELECT f.id_factura, p.id_producto, v.cantidad, v.precio
FROM (VALUES
    (1,  'Tableta Android 10" OEM',    90,  2600.00),
    (2,  'Smartwatch Fitness Pro',     130, 3300.00),
    (3,  'Auriculares BT TW-55',       200, 476.00),
    (4,  'Cargador USB-C 65W GaN',     460, 320.00),
    (5,  'Cable HDMI 2.1 4K 2m',       800, 98.00),
    (6,  'Bocina Portátil BT 20W',     305, 469.00),
    (7,  'Router Wi-Fi 6 AX1800',      50,  1330.00),
    (8,  'Monitor LED 24" FHD',        70,  3000.00),
    (9,  'Auriculares BT TW-55',       100, 580.00),
    (10, 'Multicontacto 6 salidas',    900, 138.00)
) AS v(orden, nombre, cantidad, precio)
JOIN (SELECT id_factura, ROW_NUMBER() OVER (ORDER BY id_factura) AS orden FROM facturas) f ON f.orden = v.orden
JOIN productos p ON p.nombre = v.nombre
WHERE NOT EXISTS (SELECT 1 FROM detalle_factura);

-- ---------- 1 CONCILIACIÓN con faltante (el trigger alinea el stock y deja evidencia) ----------
INSERT INTO ajustes_inventario (id_producto, fecha, conteo_fisico, motivo, responsable)
SELECT p.id_producto, DATE '2026-09-10', p.stock - 2, 'Merma detectada en conteo físico', 'Almacén'
FROM productos p
WHERE p.nombre = 'Auriculares BT TW-55'
  AND NOT EXISTS (SELECT 1 FROM ajustes_inventario);
