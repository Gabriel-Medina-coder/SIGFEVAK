-- Área 1 · Issue #26 · RN-A1-08, RN-A1-17
-- Qué hace: 2 almacenes, 4 proveedores, 6 productos con SKU, 3 materias primas con stock vía entradas,
-- 1 BOM, la entrada del ejemplo 10.1, una importación en USD, una recepción con faltante y la orden
-- OP-2026-0001 recorrida hasta TERMINADA (ejemplo 10.2). Nunca escribe stock; lo mueven los triggers. Idempotente.

-- ---------- ALMACENES ----------
INSERT INTO almacenes (nombre, tipo, ubicacion) VALUES
    ('Insumos Planta',             'INSUMOS',            'Nave 2, Querétaro'),
    ('Producto Terminado Central', 'PRODUCTO_TERMINADO', 'Nave 1, Querétaro')
ON CONFLICT (nombre) DO NOTHING;

-- ---------- PROVEEDORES: 2 nacionales con RFC, 1 extranjero sin RFC, 1 inactivo ----------
INSERT INTO proveedores (nombre, rfc, pais, contacto, activo) VALUES
    ('Electrónica del Norte SA de CV', 'EDN010203AB1', 'México', 'ventas@edn.mx',        TRUE),
    ('Plásticos Bajío SA de CV',       'PBA050607CD2', 'México', 'Laura Ríos, 442 555 0101', TRUE),
    ('Shenzhen Import Co.',            NULL,           'China',  'export@shenzhenimport.cn', TRUE),
    ('Distribuidora Antigua SA',       'DAN990101EF3', 'México', NULL,                   FALSE)
ON CONFLICT (nombre) DO NOTHING;

-- ---------- PRODUCTOS: 4 existentes reciben SKU y catálogo, 2 nuevos de manufactura ----------
INSERT INTO productos (tipo, nombre, sku, marca, modelo, categoria, stock_minimo, precio_venta_sugerido)
SELECT v.tipo::tipo_producto, v.nombre, v.sku, v.marca, v.modelo, v.categoria, v.minimo, v.precio FROM (VALUES
    ('MANUFACTURA', 'Kit bocina portátil BT 20W', 'MF-KIT-BOC20', 'SIGFEVAK', 'KB-20',  'Audio > Bocinas',   30, 799.00),
    ('MANUFACTURA', 'Kit cargador solar 10W',     'MF-KIT-SOL10', 'SIGFEVAK', 'KS-10',  'Energía > Solares', 20, 549.00)
) AS v(tipo, nombre, sku, marca, modelo, categoria, minimo, precio)
ON CONFLICT (nombre, tipo) DO NOTHING;

UPDATE productos p SET sku = v.sku, marca = v.marca, modelo = v.modelo, categoria = v.categoria, stock_minimo = v.minimo
FROM (VALUES
    ('Tableta Android 10" OEM',   'EL-TAB-A10',  'Genérica', 'A10-2026', 'Cómputo > Tabletas',    100),
    ('Cámara IP WiFi 1080p',      'EL-CAM-IP1080','VigiaMX', 'IP-1080',  'Seguridad > Cámaras',    50),
    ('Base para laptop aluminio', 'MF-BAS-LAP',  'SIGFEVAK', 'BL-01',    'Accesorios > Soportes', 150),
    ('Cable HDMI 2.1 4K 2m',      'MF-CAB-HDMI2','SIGFEVAK', 'HD-21',    'Cables > Video',        500)
) AS v(nombre, sku, marca, modelo, categoria, minimo)
WHERE p.nombre = v.nombre AND p.sku IS NULL;

-- ---------- MATERIAS PRIMAS (stock 0; lo suben las entradas) ----------
INSERT INTO materias_primas (sku, nombre, unidad_medida, id_almacen, id_proveedor)
SELECT v.sku, v.nombre, v.um, a.id_almacen, pr.id_proveedor
FROM (VALUES
    ('MP-CARCASA-BOC', 'Carcasa plástica bocina 20W', 'PIEZA', 'Plásticos Bajío SA de CV'),
    ('MP-MODULO-BOC',  'Módulo bocina 20W con BT',     'PIEZA', 'Electrónica del Norte SA de CV'),
    ('MP-CABLE-2X22',  'Cable dúplex 2x22 AWG',        'METRO', 'Electrónica del Norte SA de CV')
) AS v(sku, nombre, um, proveedor)
JOIN almacenes a ON a.nombre = 'Insumos Planta'
JOIN proveedores pr ON pr.nombre = v.proveedor
ON CONFLICT (sku) DO NOTHING;

INSERT INTO entradas_materia_prima (id_materia, fecha, cantidad, costo_unitario, id_proveedor, documento_ref)
SELECT m.id_materia, v.fecha, v.cantidad, v.costo, m.id_proveedor, v.doc
FROM (VALUES
    ('MP-CARCASA-BOC', DATE '2026-08-20', 200, 85.00,  'F-PB-1180'),
    ('MP-MODULO-BOC',  DATE '2026-08-21', 150, 140.00, 'F-EDN-5602'),
    ('MP-CABLE-2X22',  DATE '2026-08-21', 500, 12.50,  'F-EDN-5603')
) AS v(sku, fecha, cantidad, costo, doc)
JOIN materias_primas m ON m.sku = v.sku
WHERE NOT EXISTS (SELECT 1 FROM entradas_materia_prima);

-- ---------- BOM del kit de bocina: 1 carcasa + 1 módulo ----------
INSERT INTO bom (id_producto_destino, id_materia, cantidad_por_unidad)
SELECT p.id_producto, m.id_materia, 1
FROM productos p, materias_primas m
WHERE p.sku = 'MF-KIT-BOC20' AND m.sku IN ('MP-CARCASA-BOC', 'MP-MODULO-BOC')
ON CONFLICT (id_producto_destino, id_materia) DO NOTHING;

-- ---------- ENTRADAS VÍA A ----------
-- Ejemplo 10.1: 100 unidades a $200, flete $20, MXN, factura F-4471 → valor 220, capital 22,000
INSERT INTO entradas_producto (id_producto, fecha, cantidad, cantidad_esperada, costo_unitario, flete_unitario, impuestos_unitarios,
                               moneda, tipo_cambio, id_proveedor, id_almacen, numero_factura_proveedor, fecha_factura_proveedor,
                               responsable_recepcion, documento_ref)
SELECT p.id_producto, DATE '2026-09-07', 100, 100, 200.00, 20.00, 0, 'MXN', 1, pr.id_proveedor, a.id_almacen,
       'F-4471', DATE '2026-09-05', 'Almacén PT', 'F-4471'
FROM productos p, proveedores pr, almacenes a
WHERE p.sku = 'MF-BAS-LAP' AND pr.nombre = 'Plásticos Bajío SA de CV' AND a.nombre = 'Producto Terminado Central'
  AND NOT EXISTS (SELECT 1 FROM entradas_producto WHERE numero_factura_proveedor = 'F-4471');

-- Importación en USD: 50 unidades a USD 40, flete 3, impuestos 5, tipo de cambio 18.50 → valor 888, capital 44,400
INSERT INTO entradas_producto (id_producto, fecha, cantidad, cantidad_esperada, costo_unitario, flete_unitario, impuestos_unitarios,
                               moneda, tipo_cambio, pais_origen, id_proveedor, id_almacen, numero_factura_proveedor,
                               fecha_factura_proveedor, documento_importacion_ref, responsable_recepcion, documento_ref)
SELECT p.id_producto, DATE '2026-09-08', 50, 50, 40.00, 3.00, 5.00, 'USD', 18.5, 'China', pr.id_proveedor, a.id_almacen,
       'SZ-2026-0917', DATE '2026-08-28', 'Pedimento 26 47 3891 6004521', 'Almacén PT', 'SZ-2026-0917'
FROM productos p, proveedores pr, almacenes a
WHERE p.sku = 'EL-CAM-IP1080' AND pr.nombre = 'Shenzhen Import Co.' AND a.nombre = 'Producto Terminado Central'
  AND NOT EXISTS (SELECT 1 FROM entradas_producto WHERE numero_factura_proveedor = 'SZ-2026-0917');

-- Recepción con faltante: esperaba 300 cables, llegaron 290 (aparece en v_discrepancias_recepcion)
INSERT INTO entradas_producto (id_producto, fecha, cantidad, cantidad_esperada, costo_unitario, estado_mercancia, id_proveedor, id_almacen,
                               numero_orden_compra, responsable_recepcion, observaciones, documento_ref)
SELECT p.id_producto, DATE '2026-09-09', 290, 300, 89.00, 'INCOMPLETO', pr.id_proveedor, a.id_almacen,
       'OC-2026-0210', 'Almacén PT', 'Faltaron 10 piezas; reclamación abierta con el proveedor', 'OC-2026-0210'
FROM productos p, proveedores pr, almacenes a
WHERE p.sku = 'MF-CAB-HDMI2' AND pr.nombre = 'Electrónica del Norte SA de CV' AND a.nombre = 'Producto Terminado Central'
  AND NOT EXISTS (SELECT 1 FROM entradas_producto WHERE numero_orden_compra = 'OC-2026-0210');

-- ---------- VÍA B: orden OP-2026-0001 hasta TERMINADA (ejemplo 10.2) ----------
DO $$
DECLARE
    v_orden INT;
    v_prod  INT;
BEGIN
    IF EXISTS (SELECT 1 FROM ordenes_produccion WHERE folio = 'OP-2026-0001') THEN RETURN; END IF;

    SELECT id_producto INTO v_prod FROM productos WHERE sku = 'MF-KIT-BOC20';

    INSERT INTO ordenes_produccion (folio, id_producto_destino, cantidad_planeada, fecha_inicio_programada, fecha_fin_programada, responsable)
    VALUES ('OP-2026-0001', v_prod, 50, DATE '2026-09-01', DATE '2026-09-05', 'Marco Delgado')
    RETURNING id_orden INTO v_orden;

    UPDATE ordenes_produccion SET estado = 'EN_PROCESO', fecha_inicio_real = DATE '2026-09-01' WHERE id_orden = v_orden;

    INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real, merma, motivo_merma, fecha, turno)
    SELECT v_orden, m.id_materia, v.cantidad, v.merma, v.motivo, DATE '2026-09-02', 'Matutino'
    FROM (VALUES
        ('MP-CARCASA-BOC', 52, 2, 'carcasa rayada'),
        ('MP-MODULO-BOC',  50, 0, NULL)
    ) AS v(sku, cantidad, merma, motivo)
    JOIN materias_primas m ON m.sku = v.sku;

    UPDATE ordenes_produccion
       SET estado = 'EN_CALIDAD', costo_mano_obra = 2500.00, costos_indirectos = 580.00
     WHERE id_orden = v_orden;

    INSERT INTO control_calidad (id_orden, aprobadas, rechazadas, motivo_rechazo, responsable, fecha)
    VALUES (v_orden, 48, 2, 'no enciende', 'Sofía Campos', DATE '2026-09-04');

    -- Al terminar, fn_cerrar_orden genera lote y entrada de 48 a $302.08 con proveedor PRODUCCIÓN INTERNA
    UPDATE ordenes_produccion SET estado = 'TERMINADA', fecha_fin_real = DATE '2026-09-04' WHERE id_orden = v_orden;
END $$;

-- Segunda orden en proceso, para v_capital_en_proceso y el tablero
DO $$
DECLARE v_orden INT; v_prod INT;
BEGIN
    IF EXISTS (SELECT 1 FROM ordenes_produccion WHERE folio = 'OP-2026-0002') THEN RETURN; END IF;
    SELECT id_producto INTO v_prod FROM productos WHERE sku = 'MF-KIT-BOC20';
    INSERT INTO ordenes_produccion (folio, id_producto_destino, cantidad_planeada, fecha_inicio_programada, fecha_fin_programada, responsable)
    VALUES ('OP-2026-0002', v_prod, 40, DATE '2026-09-10', DATE '2026-09-16', 'Marco Delgado')
    RETURNING id_orden INTO v_orden;
    UPDATE ordenes_produccion SET estado = 'EN_PROCESO', fecha_inicio_real = DATE '2026-09-10' WHERE id_orden = v_orden;
    INSERT INTO consumo_produccion (id_orden, id_materia, cantidad_real, fecha, turno)
    SELECT v_orden, m.id_materia, 20, DATE '2026-09-11', 'Vespertino' FROM materias_primas m WHERE m.sku = 'MP-CARCASA-BOC';
END $$;
