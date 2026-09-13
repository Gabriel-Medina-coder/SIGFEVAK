-- Coordinación · Seed histórico · D-12
-- Qué hace: simula dos años de uso de la app (sep 2024 a ago 2026) sobre los seeds de las seis áreas:
-- parámetros legales y fiscales 2024 y 2025, proveedores, 14 comercializadores nuevos, un agente que se dio de baja,
-- compras mensuales, facturas cobradas y canceladas, conciliaciones, nóminas mensuales cerradas, obligaciones
-- fiscales cerradas, pedimentos, licencias vencidas y renovadas, campañas e investigaciones de mercado.
-- Reglas: todo pasa por los triggers con fechas explícitas; nunca escribe stock (RN-A3-06). Lo comprado cada mes
-- es lo que se vendió ese mes, así el stock final de cada producto no cambia y los ejemplos de los seeds siguen
-- exactos. Ninguna factura histórica queda pendiente ni se cobra en sep 2026, Jorge Mendoza nunca vende a Norte
-- Digital ni a Distribuidora Bajío, y no hay ventas históricas en ago 2026 (caso B del área 6).
-- Sep 2024 es el mes de implantación: se capturan compras y ventas y la primera nómina calculada es oct 2024.
-- Determinista (setseed) e idempotente: si ya existe el periodo de nómina de oct 2024 no hace nada.
-- Va después de todas las migraciones y seeds de área.

-- ---------- 1. PARÁMETROS 2024 Y 2025 (RN-A4-14, RN-A5-20) ----------
INSERT INTO parametros_legales (clave, entidad, valor, vigencia_inicio, vigencia_fin, fuente)
SELECT v.clave, NULL, v.valor, v.inicio, v.fin, v.fuente FROM (VALUES
    ('SM_GENERAL',  248.9300, DATE '2024-01-01', DATE '2024-12-31', 'CONASAMI 2024'),
    ('SM_ZLFN',     374.8900, DATE '2024-01-01', DATE '2024-12-31', 'CONASAMI 2024'),
    ('SM_GENERAL',  278.8000, DATE '2025-01-01', DATE '2025-12-31', 'CONASAMI 2025'),
    ('SM_ZLFN',     419.8800, DATE '2025-01-01', DATE '2025-12-31', 'CONASAMI 2025'),
    ('UMA_DIARIA',  108.5700, DATE '2024-02-01', DATE '2025-01-31', 'INEGI 2024'),
    ('UMA_MENSUAL', 3300.5300, DATE '2024-02-01', DATE '2025-01-31', 'INEGI 2024'),
    ('UMA_DIARIA',  113.1400, DATE '2025-02-01', DATE '2026-01-31', 'INEGI 2025'),
    ('UMA_MENSUAL', 3439.4600, DATE '2025-02-01', DATE '2026-01-31', 'INEGI 2025')
) AS v(clave, valor, inicio, fin, fuente)
WHERE NOT EXISTS (SELECT 1 FROM parametros_legales p WHERE p.clave = v.clave AND p.vigencia_inicio = v.inicio);

-- Los que no cambiaron de 2024 a 2026 se copian con vigencia 2024-2025
INSERT INTO parametros_legales (clave, entidad, valor, tabla, vigencia_inicio, vigencia_fin, fuente)
SELECT p.clave, p.entidad, p.valor, p.tabla, DATE '2024-01-01', DATE '2025-12-31', p.fuente || ' · mismo valor en 2024 y 2025'
FROM parametros_legales p
WHERE p.vigencia_inicio = DATE '2026-01-01'
  AND p.clave IN ('FACTOR_DIAS_MES', 'TOPE_DESCUENTO_110', 'CUOTA_IMSS_OBRERO', 'TOPE_EXENTO_PUNTUALIDAD_UMAS', 'ISN', 'TARIFA_ISR_MENSUAL')
  AND NOT EXISTS (SELECT 1 FROM parametros_legales q WHERE q.clave = p.clave AND q.entidad IS NOT DISTINCT FROM p.entidad AND q.vigencia_inicio = DATE '2024-01-01');

INSERT INTO parametros_fiscales (clave, entidad, fraccion, valor, tabla, vigencia_inicio, vigencia_fin, fuente)
SELECT p.clave, p.entidad, p.fraccion, p.valor, p.tabla, DATE '2024-01-01', DATE '2025-12-31', p.fuente || ' · mismo valor en 2024 y 2025'
FROM parametros_fiscales p
WHERE p.vigencia_inicio = DATE '2026-01-01'
  AND NOT EXISTS (SELECT 1 FROM parametros_fiscales q WHERE q.clave = p.clave AND q.entidad IS NOT DISTINCT FROM p.entidad
                     AND q.fraccion IS NOT DISTINCT FROM p.fraccion AND q.vigencia_inicio = DATE '2024-01-01');

-- ---------- 2. PROVEEDORES ----------
INSERT INTO proveedores (nombre, rfc, pais, contacto, activo) VALUES
    ('Guangzhou Audio Ltd.',                     NULL,           'China',  'sales@gzaudio.cn',             TRUE),
    ('Cables y Conectores de Querétaro SA de CV', 'CCQ080415GH4', 'México', 'Héctor Salas, 442 555 0133',   TRUE),
    ('Energía Industrial del Bajío SA de CV',    'EIB100920JK5', 'México', 'compras@energiabajio.mx',      TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- ---------- 3. CATÁLOGO: SKU y datos comerciales de los productos que no los tenían ----------
UPDATE productos p SET sku = v.sku, marca = v.marca, modelo = v.modelo, categoria = v.categoria,
       stock_minimo = v.minimo, precio_venta_sugerido = v.precio
FROM (VALUES
    ('Smartwatch Fitness Pro',        'EL-SW-FITPRO',  'Genérica', 'SW-26',     'Wearables > Relojes',     40,  3300.00),
    ('Auriculares BT TW-55',          'EL-AUD-TW55',   'Genérica', 'TW-55',     'Audio > Auriculares',    150,   520.00),
    ('Bocina Portátil BT 20W',        'EL-BOC-BT20',   'Genérica', 'BT-20',     'Audio > Bocinas',         60,   900.00),
    ('Router Wi-Fi 6 AX1800',         'EL-RTR-AX18',   'NetMX',    'AX1800',    'Redes > Routers',         40,  1500.00),
    ('Monitor LED 24" FHD',           'EL-MON-24FHD',  'VisionMX', 'M24-FHD',   'Cómputo > Monitores',     30,  3100.00),
    ('Teclado mecánico RGB',          'EL-TEC-RGB',    'KeyPro',   'KP-RGB',    'Cómputo > Periféricos',   40,   790.00),
    ('Mouse inalámbrico 2.4G',        'EL-MOU-24G',    'KeyPro',   'KP-M24',    'Cómputo > Periféricos',  100,   165.00),
    ('Power bank 20000 mAh',          'EL-PWB-20K',    'Genérica', 'PB-20K',    'Energía > Baterías',     100,   540.00),
    ('Cargador USB-C 65W GaN',        'MF-CAR-65W',    'SIGFEVAK', 'CG-65',     'Energía > Cargadores',   300,   330.00),
    ('Regulador de voltaje 1200VA',   'MF-REG-1200',   'SIGFEVAK', 'RV-1200',   'Energía > Reguladores',   60,   650.00),
    ('Multicontacto 6 salidas',       'MF-MUL-6S',     'SIGFEVAK', 'MC-6',      'Energía > Multicontactos',200,  140.00),
    ('Cable USB-C a USB-C 1m',        'MF-CAB-USBC1',  'SIGFEVAK', 'UC-1',      'Cables > Datos',         300,    79.00),
    ('Funda tablet 10" negra',        'MF-FUN-TAB10',  'SIGFEVAK', 'FT-10',     'Accesorios > Fundas',    100,   120.00),
    ('Soporte de monitor articulado', 'MF-SOP-MON',    'SIGFEVAK', 'SM-01',     'Accesorios > Soportes',   40,   690.00),
    ('Extensión eléctrica 5m',        'MF-EXT-5M',     'SIGFEVAK', 'EX-5',      'Energía > Extensiones',  150,   125.00),
    ('Adaptador HDMI a VGA',          'MF-ADP-HDVGA',  'SIGFEVAK', 'AD-HV',     'Cables > Video',         100,   110.00)
) AS v(nombre, sku, marca, modelo, categoria, minimo, precio)
WHERE p.nombre = v.nombre AND p.sku IS NULL;

UPDATE productos p SET precio_venta_sugerido = v.precio
FROM (VALUES ('Tableta Android 10" OEM', 2600.00), ('Cámara IP WiFi 1080p', 1200.00), ('Base para laptop aluminio', 450.00), ('Cable HDMI 2.1 4K 2m', 110.00)) AS v(nombre, precio)
WHERE p.nombre = v.nombre AND p.precio_venta_sugerido IS NULL;

-- ---------- 4. COMERCIALIZADORES NUEVOS (RN-A2-05, RN-A2-11; el folio lo pone el trigger) ----------
INSERT INTO clientes (nombre_empresa, rfc, estado, dias_credito)
SELECT v.nombre, v.rfc, v.estado, v.dias FROM (VALUES
    ('Grupo Comercial Tapatío S.A. de C.V.',             'GCT140521AB2', 'Jalisco',          30),
    ('Distribuidora Electrónica del Golfo S.A. de C.V.', 'DEG110907CD3', 'Veracruz',         30),
    ('Tecno Abastos Monterrey S.A. de C.V.',             'TAM170314EF4', 'Nuevo León',       45),
    ('Comercializadora Yucateca de Tecnología S.A.',     'CYT150822GH5', 'Yucatán',          30),
    ('Mayoristas Unidos de Oaxaca S.A. de C.V.',         'MUO120118IJ6', 'Oaxaca',           15),
    ('Digital Store Querétaro S. de R.L.',               'DSQ180605KL7', 'Querétaro',        30),
    ('Casa Hernández Electrónica S.A.',                  'CHE990412MN8', 'Tabasco',          30),
    ('Soluciones Tecnológicas Bajacalifornianas S.A.',   'STB160930OP9', 'Baja California',  30),
    ('Punto Digital Tuxtla S.A. de C.V.',                'PDT191111QR1', 'Chiapas',          15),
    ('Importadora y Distribuidora Sinaloense S.A.',      'IDS130227ST2', 'Sinaloa',          30),
    ('Electro Hogar Morelos S.A. de C.V.',               'EHM200303UV3', 'Morelos',          30),
    ('Red Comercial Hidalguense S.A. de C.V.',           'RCH210715WX4', 'Hidalgo',          30),
    ('Tienda Conecta Puebla S.A. de C.V.',               'TCP220120YZ5', 'Puebla',           30),
    ('Mercado Tech Aguascalientes S.A.',                 'MTA170808AB6', 'Aguascalientes',   30)
) AS v(nombre, rfc, estado, dias)
WHERE NOT EXISTS (SELECT 1 FROM clientes c WHERE c.rfc = v.rfc);

-- ---------- 5. AGENTE QUE SE DIO DE BAJA EN AGO 2025 (RN-A4-01, RN-A4-02) ----------
INSERT INTO agentes_ventas (nombre, sueldo_base, comision, rfc, curp, nss, fecha_ingreso, id_zona, id_esquema, salario_diario, entidad_federativa, clabe)
SELECT 'Rodrigo Beltrán', 10640.00, 2.00, 'BERR860314AB7', 'BERR860314HQTLDD04', '32148612345', DATE '2023-02-01',
       z.id_zona, e.id_esquema, 350.00, z.entidad, '012180001234567896'
FROM zonas z, esquemas_compensacion e
WHERE z.nombre = 'Centro' AND e.nombre = 'Esquema 2026 general'
  AND NOT EXISTS (SELECT 1 FROM agentes_ventas WHERE nombre = 'Rodrigo Beltrán');

-- ---------- 6. AUXILIARES DE ESTA CARGA (viven solo en la sesión) ----------
-- Pone la fecha del evento en las bitácoras que los triggers acaban de escribir con NOW()
CREATE OR REPLACE FUNCTION pg_temp.h_fechar(p_ts TIMESTAMP) RETURNS VOID LANGUAGE sql AS $$
    UPDATE bitacora_fiscal SET fecha = p_ts WHERE fecha = now()::TIMESTAMP;
    UPDATE bitacora_nomina SET fecha = p_ts WHERE fecha = now()::TIMESTAMP;
$$;

-- Recorre una obligación de PENDIENTE a CERRADO con declaración, pago y comprobante (RN-A5-04, 05, 07, 18, 19, 23)
CREATE OR REPLACE FUNCTION pg_temp.h_recorrer_obligacion(p_obl INT, p_monto DECIMAL, p_base DATE, p_resp UUID, p_aut UUID,
                                                         p_tipo_decl TEXT, p_sat BOOLEAN, p_nombre TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_pago INT; v_linea TEXT; v_op TEXT;
BEGIN
    v_op    := TO_CHAR(p_base, 'YYMMDD') || LPAD(p_obl::TEXT, 6, '0');
    v_linea := '00' || TO_CHAR(p_base, 'YY') || ' ' || TO_CHAR(p_base, 'MMDD') || ' ' || LPAD((p_obl * 7919 % 10000)::TEXT, 4, '0') || ' '
               || LPAD((p_obl * 104729 % 10000)::TEXT, 4, '0') || ' ' || LPAD((p_obl % 100)::TEXT, 2, '0');
    UPDATE obligaciones SET monto_estimado = p_monto, id_responsable = p_resp, estado = 'CALCULADO' WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 8) + TIME '10:05');
    IF p_tipo_decl IS NOT NULL THEN
        INSERT INTO declaraciones (id_obligacion, tipo_declaracion, numero_operacion, folio, linea_captura, fecha_presentacion, importe_declarado, fecha_limite_pago)
        VALUES (p_obl, p_tipo_decl, v_op, 'ACUSE-' || v_op, v_linea, p_base - 5, p_monto, p_base);
        INSERT INTO documentos_fiscales (id_obligacion, tipo_documento, nombre, referencia, fecha)
        VALUES (p_obl, (CASE WHEN p_sat THEN 'ACUSE_SAT' ELSE 'OTRO' END)::tipo_documento_fiscal, 'Acuse ' || p_nombre,
                'docs/acuses/' || TO_CHAR(p_base, 'YYYY-MM') || '-' || p_obl || '.pdf', p_base - 5);
    END IF;
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 5) + TIME '11:10');
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 5) + TIME '11:25');
    UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = p_aut WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 4) + TIME '09:40');
    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, banco, referencia, linea_captura, metodo_pago, id_registrado_por, id_autorizado_por)
    VALUES (p_obl, p_base - 2, p_monto, CASE WHEN p_obl % 3 = 0 THEN 'Banorte' ELSE 'BBVA' END,
            'SPEI-' || TO_CHAR(p_base - 2, 'YYYYMMDD') || '-' || LPAD((p_obl * 7331 % 1000000)::TEXT, 6, '0'), v_linea, 'SPEI', p_resp, p_aut)
    RETURNING id_pago INTO v_pago;
    INSERT INTO documentos_fiscales (id_obligacion, id_pago, tipo_documento, nombre, referencia, fecha)
    VALUES (p_obl, v_pago, 'COMPROBANTE_BANCARIO', 'Comprobante SPEI ' || p_nombre,
            'docs/comprobantes/' || TO_CHAR(p_base - 2, 'YYYY-MM-DD') || '-' || p_obl || '.pdf', p_base - 2);
    PERFORM pg_temp.h_fechar((p_base - 2) + TIME '12:30');
    UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 2) + TIME '12:45');
    UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 1) + TIME '16:00');
    UPDATE obligaciones SET estado = 'CERRADO', fecha_cierre = p_base - 1 WHERE id_obligacion = p_obl;
    PERFORM pg_temp.h_fechar((p_base - 1) + TIME '16:20');
END; $$;

-- ---------- 7. DOS AÑOS DE OPERACIÓN ----------
DO $$
DECLARE
    v_admin UUID; v_contador UUID; v_autorizador UUID;
    v_alm INT; v_mes DATE; v_eom DATE; v_periodo TEXT; v_factor DECIMAL; v_idx INT;
    c RECORD; f RECORD; l RECORD; e RECORD; a RECORD; o RECORD; pr RECORD;
    v_n INT; v_lineas INT; v_obj DECIMAL; v_r DECIMAL; v_prod INT; v_precio DECIMAL; v_qty INT; v_usados INT[];
    v_fecha DATE; v_cobro DATE; v_agente INT; v_plan INT := 0; v_fac INT; v_ent INT; v_per INT; v_obl INT; v_imp INT;
    v_tc DECIMAL; v_costo DECIMAL; v_flete DECIMAL; v_impu DECIMAL; v_moneda TEXT; v_doc TEXT; v_ped TEXT;
    v_monto DECIMAL; v_tras DECIMAL; v_sub DECIMAL; v_acred DECIMAL; v_ventas DECIMAL; v_total_peso DECIMAL;
BEGIN
    IF EXISTS (SELECT 1 FROM periodos_nomina WHERE tipo = 'MENSUAL' AND fecha_inicio = DATE '2024-10-01') THEN RETURN; END IF;
    PERFORM setseed(0.2026);

    SELECT id_usuario INTO v_admin       FROM usuarios WHERE correo = 'admin@sigfevak.mx';
    SELECT id_usuario INTO v_contador    FROM usuarios WHERE correo = 'contador@sigfevak.mx';
    SELECT id_usuario INTO v_autorizador FROM usuarios WHERE correo = 'autorizador@sigfevak.mx';
    SELECT id_almacen INTO v_alm FROM almacenes WHERE nombre = 'Producto Terminado Central';

    -- Catálogo de venta: costo de compra en MXN, precio, peso en la mezcla de venta, proveedor y fracción
    CREATE TEMP TABLE h_prod ON COMMIT DROP AS
    SELECT p.id_producto, v.nombre, v.costo, v.precio, v.peso, v.proveedor, v.moneda, v.fraccion,
           SUM(v.peso) OVER (ORDER BY v.orden) - v.peso AS peso_desde, SUM(v.peso) OVER (ORDER BY v.orden) AS peso_hasta
    FROM (VALUES
        (1,  'Tableta Android 10" OEM',       1850.00, 2600.00,  8, 'Shenzhen Import Co.',                       'USD', '8471.30.01'),
        (2,  'Smartwatch Fitness Pro',        2400.00, 3300.00,  6, 'Shenzhen Import Co.',                       'USD', '8517.62.15'),
        (3,  'Auriculares BT TW-55',           330.00,  520.00, 12, 'Guangzhou Audio Ltd.',                      'USD', '8518.30.99'),
        (4,  'Bocina Portátil BT 20W',         620.00,  900.00,  9, 'Guangzhou Audio Ltd.',                      'USD', '8518.22.01'),
        (5,  'Cámara IP WiFi 1080p',           780.00, 1200.00,  6, 'Shenzhen Import Co.',                       'USD', '8525.89.99'),
        (6,  'Router Wi-Fi 6 AX1800',         1150.00, 1500.00,  5, 'Shenzhen Import Co.',                       'USD', '8517.62.15'),
        (7,  'Monitor LED 24" FHD',           2650.00, 3100.00,  5, 'Electrónica del Norte SA de CV',            'MXN', NULL),
        (8,  'Teclado mecánico RGB',           520.00,  790.00,  5, 'Electrónica del Norte SA de CV',            'MXN', NULL),
        (9,  'Mouse inalámbrico 2.4G',          95.00,  165.00,  8, 'Electrónica del Norte SA de CV',            'MXN', NULL),
        (10, 'Power bank 20000 mAh',           380.00,  540.00,  8, 'Electrónica del Norte SA de CV',            'MXN', NULL),
        (11, 'Cable HDMI 2.1 4K 2m',            72.00,  110.00, 10, 'Cables y Conectores de Querétaro SA de CV', 'MXN', NULL),
        (12, 'Cargador USB-C 65W GaN',         210.00,  330.00,  9, 'Cables y Conectores de Querétaro SA de CV', 'MXN', NULL),
        (13, 'Regulador de voltaje 1200VA',    480.00,  650.00,  5, 'Energía Industrial del Bajío SA de CV',     'MXN', NULL),
        (14, 'Multicontacto 6 salidas',         95.00,  140.00,  7, 'Energía Industrial del Bajío SA de CV',     'MXN', NULL),
        (15, 'Cable USB-C a USB-C 1m',          45.00,   79.00,  9, 'Cables y Conectores de Querétaro SA de CV', 'MXN', NULL),
        (16, 'Base para laptop aluminio',      220.00,  450.00,  5, 'Plásticos Bajío SA de CV',                  'MXN', NULL),
        (17, 'Funda tablet 10" negra',          60.00,  120.00,  5, 'Plásticos Bajío SA de CV',                  'MXN', NULL),
        (18, 'Soporte de monitor articulado',  390.00,  690.00,  4, 'Plásticos Bajío SA de CV',                  'MXN', NULL),
        (19, 'Extensión eléctrica 5m',          70.00,  125.00,  6, 'Energía Industrial del Bajío SA de CV',     'MXN', NULL),
        (20, 'Adaptador HDMI a VGA',            55.00,  110.00,  5, 'Cables y Conectores de Querétaro SA de CV', 'MXN', NULL)
    ) AS v(orden, nombre, costo, precio, peso, proveedor, moneda, fraccion)
    JOIN productos p ON p.nombre = v.nombre;
    SELECT MAX(peso_hasta) INTO v_total_peso FROM h_prod;

    -- Cartera: agente titular (y quien la tomó tras la baja de Rodrigo), tamaño medio de factura sin IVA,
    -- facturas esperadas al mes y meses en que compró
    CREATE TEMP TABLE h_cli ON COMMIT DROP AS
    SELECT cl.id_cliente, cl.dias_credito, v.rfc, a1.id_agente AS agente, COALESCE(a2.id_agente, a1.id_agente) AS agente_despues,
           v.monto, v.frec, v.desde, v.hasta
    FROM (VALUES
        ('EMA150312AB1', 'Jorge Mendoza',     NULL,              60000, 4.0, DATE '2024-09-01', NULL::DATE),
        ('CDI980722CD2', 'Patricia Leal',     NULL,              50000, 3.0, DATE '2024-09-01', NULL),
        ('RMX040815EF3', 'Andrés Fuentes',    NULL,               30000, 1.8, DATE '2024-09-01', NULL),
        ('BBM070910GH4', 'Verónica Castillo', NULL,              65000, 3.5, DATE '2024-09-01', NULL),
        ('TCD190405IJ5', 'Jorge Mendoza',     NULL,               25000, 2.0, DATE '2024-09-01', NULL),
        ('NDI160228KL6', 'Patricia Leal',     NULL,               30000, 2.0, DATE '2024-09-01', NULL),
        ('DBA120614MN7', 'Miguel Torres',     NULL,               22000, 1.8, DATE '2024-09-01', NULL),
        ('RHC001120OP8', 'Andrés Fuentes',    NULL,               25000, 1.5, DATE '2024-09-01', NULL),
        ('ESU110303QR9', 'Verónica Castillo', NULL,               18000, 2.0, DATE '2024-09-01', NULL),
        ('MPA090917ST0', 'Miguel Torres',     NULL,               25000, 1.5, DATE '2024-09-01', NULL),
        ('CAC050101UV1', 'Andrés Fuentes',    NULL,               18000, 1.2, DATE '2024-09-01', DATE '2025-04-01'),
        ('GCT140521AB2', 'Patricia Leal',     NULL,               30000, 2.0, DATE '2024-09-01', NULL),
        ('DEG110907CD3', 'Verónica Castillo', NULL,               20000, 1.6, DATE '2024-11-01', NULL),
        ('TAM170314EF4', 'Miguel Torres',     NULL,               35000, 2.5, DATE '2024-09-01', NULL),
        ('CYT150822GH5', 'Jorge Mendoza',     NULL,               16000, 1.3, DATE '2025-01-01', NULL),
        ('MUO120118IJ6', 'Verónica Castillo', NULL,               12000, 1.2, DATE '2025-02-01', NULL),
        ('DSQ180605KL7', 'Rodrigo Beltrán',   'Andrés Fuentes',   15000, 1.6, DATE '2024-09-01', NULL),
        ('CHE990412MN8', 'Jorge Mendoza',     NULL,               15000, 1.4, DATE '2024-10-01', NULL),
        ('STB160930OP9', 'Miguel Torres',     NULL,               20000, 1.5, DATE '2025-04-01', NULL),
        ('PDT191111QR1', 'Jorge Mendoza',     NULL,               12000, 1.8, DATE '2024-09-01', NULL),
        ('IDS130227ST2', 'Miguel Torres',     NULL,               25000, 1.8, DATE '2024-09-01', NULL),
        ('EHM200303UV3', 'Patricia Leal',     NULL,               12000, 1.3, DATE '2025-03-01', NULL),
        ('RCH210715WX4', 'Andrés Fuentes',    NULL,               14000, 1.4, DATE '2025-06-01', NULL),
        ('TCP220120YZ5', 'Patricia Leal',     NULL,               16000, 1.5, DATE '2025-10-01', NULL),
        ('MTA170808AB6', 'Rodrigo Beltrán',   'Andrés Fuentes',   17000, 1.4, DATE '2024-09-01', DATE '2025-12-01')
    ) AS v(rfc, titular, despues, monto, frec, desde, hasta)
    JOIN clientes cl ON cl.rfc = v.rfc
    JOIN agentes_ventas a1 ON a1.nombre = v.titular
    LEFT JOIN agentes_ventas a2 ON a2.nombre = v.despues;

    -- ---------- Plan de ventas de sep 2024 a jul 2026 ----------
    CREATE TEMP TABLE h_fac (id_plan INT PRIMARY KEY, mes DATE, fecha DATE, id_cliente INT, id_agente INT, cancelada BOOLEAN, cobro DATE) ON COMMIT DROP;
    CREATE TEMP TABLE h_lin (id_plan INT, mes DATE, id_producto INT, cantidad INT, precio DECIMAL(12,2)) ON COMMIT DROP;

    v_idx := 0;
    FOR v_mes IN SELECT generate_series(DATE '2024-09-01', DATE '2026-07-01', INTERVAL '1 month')::DATE LOOP
        -- Crecimiento de 0.78 a 1.08 en dos años y temporada (Buen Fin, Navidad, cuesta de enero)
        v_factor := (0.78 + 0.30 * v_idx / 22.0) * CASE EXTRACT(MONTH FROM v_mes)::INT
                        WHEN 11 THEN 1.30 WHEN 12 THEN 1.45 WHEN 1 THEN 0.70 WHEN 2 THEN 0.85 WHEN 3 THEN 0.95
                        WHEN 5 THEN 1.10 WHEN 7 THEN 1.05 ELSE 1.00 END;
        v_idx := v_idx + 1;
        FOR c IN SELECT * FROM h_cli WHERE desde <= v_mes AND (hasta IS NULL OR hasta >= v_mes) ORDER BY id_cliente LOOP
            v_n := FLOOR(c.frec * (0.6 + random()::NUMERIC * 0.8) + random()::NUMERIC)::INT;
            FOR i IN 1..v_n LOOP
                v_plan := v_plan + 1;
                v_fecha := v_mes + (1 + FLOOR(random()::NUMERIC * 26))::INT;
                -- Rodrigo vende hasta jun 2025; desde jul 2025 su cartera la atiende Andrés
                v_agente := CASE WHEN v_mes >= DATE '2025-07-01' THEN c.agente_despues ELSE c.agente END;
                v_cobro := v_fecha + GREATEST(c.dias_credito + (FLOOR(random()::NUMERIC * 16) - 10)::INT, 3);
                IF v_mes <= DATE '2025-06-01' AND v_agente = (SELECT id_agente FROM agentes_ventas WHERE nombre = 'Rodrigo Beltrán') THEN
                    v_cobro := LEAST(v_cobro, DATE '2025-07-31');
                END IF;
                v_cobro := LEAST(v_cobro, DATE '2026-08-31');
                INSERT INTO h_fac VALUES (v_plan, v_mes, v_fecha, c.id_cliente, v_agente, random()::NUMERIC < 0.02, v_cobro);

                v_obj := c.monto * v_factor * (0.6 + random()::NUMERIC * 0.8);
                v_lineas := 1 + FLOOR(random()::NUMERIC * 3)::INT;
                v_usados := ARRAY[]::INT[];
                FOR j IN 1..v_lineas LOOP
                    v_r := random()::NUMERIC * v_total_peso;
                    SELECT id_producto, precio INTO v_prod, v_precio FROM h_prod WHERE v_r >= peso_desde AND v_r < peso_hasta;
                    IF v_prod IS NULL OR v_prod = ANY (v_usados) THEN CONTINUE; END IF;
                    v_usados := v_usados || v_prod;
                    v_precio := ROUND(v_precio * (0.95 + random()::NUMERIC * 0.10), 2);
                    v_qty := GREATEST(3, ROUND(v_obj / v_lineas / v_precio)::INT);
                    INSERT INTO h_lin VALUES (v_plan, v_mes, v_prod, v_qty, v_precio);
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
    DELETE FROM h_fac WHERE NOT EXISTS (SELECT 1 FROM h_lin WHERE h_lin.id_plan = h_fac.id_plan);

    -- Conciliaciones trimestrales con faltante (RN-A3-07): lo que falta se compra de más ese mes
    CREATE TEMP TABLE h_aj ON COMMIT DROP AS
    SELECT mes, id_producto, faltante FROM (
        SELECT hl.mes, hl.id_producto, 1 + FLOOR(random()::NUMERIC * 4)::INT AS faltante,
               ROW_NUMBER() OVER (PARTITION BY hl.mes ORDER BY SUM(hl.cantidad) DESC) AS rn
        FROM h_lin hl
        WHERE EXTRACT(MONTH FROM hl.mes) IN (2, 5, 8, 11)
        GROUP BY hl.mes, hl.id_producto
    ) x WHERE rn <= 2;

    -- Compras del mes = unidades vendidas (incluso canceladas, que no reintegran stock) + faltante del conteo
    CREATE TEMP TABLE h_ent ON COMMIT DROP AS
    SELECT hl.mes, hl.id_producto, SUM(hl.cantidad)::INT + COALESCE(MAX(aj.faltante), 0) AS cantidad, FALSE AS ultima, NULL::INT AS id_entrada
    FROM h_lin hl LEFT JOIN h_aj aj ON aj.mes = hl.mes AND aj.id_producto = hl.id_producto
    GROUP BY hl.mes, hl.id_producto;
    -- La última compra histórica de cada producto repite el costo de su entrada más reciente para no mover valor_entrada
    UPDATE h_ent SET ultima = TRUE
    FROM (SELECT id_producto, MAX(mes) AS mes FROM h_ent GROUP BY id_producto) u
    WHERE u.id_producto = h_ent.id_producto AND u.mes = h_ent.mes
      AND EXISTS (SELECT 1 FROM entradas_producto ep WHERE ep.id_producto = h_ent.id_producto);

    CREATE TEMP TABLE h_orig ON COMMIT DROP AS
    SELECT DISTINCT ON (id_producto) id_producto, costo_unitario, flete_unitario, impuestos_unitarios, moneda, tipo_cambio
    FROM entradas_producto ORDER BY id_producto, id_entrada DESC;

    -- La cartera de Comercial Antigua del Centro estuvo activa hasta abr 2025 (RN-A2-10)
    UPDATE clientes SET activo = TRUE WHERE rfc = 'CAC050101UV1';

    -- ---------- Ejecución mes a mes ----------
    FOR v_mes IN SELECT generate_series(DATE '2024-09-01', DATE '2026-08-01', INTERVAL '1 month')::DATE LOOP
        v_eom := (v_mes + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
        v_periodo := TO_CHAR(v_mes, 'YYYY-MM');
        v_tc := CASE
            WHEN v_mes < DATE '2024-12-01' THEN 19.7500 WHEN v_mes < DATE '2025-03-01' THEN 20.3500
            WHEN v_mes < DATE '2025-06-01' THEN 19.9000 WHEN v_mes < DATE '2025-09-01' THEN 18.9500
            WHEN v_mes < DATE '2025-12-01' THEN 18.4500 WHEN v_mes < DATE '2026-03-01' THEN 18.1000
            WHEN v_mes < DATE '2026-06-01' THEN 17.8500 ELSE 18.2500 END;
        v_ped := TO_CHAR(v_mes, 'YY') || ' 47 3891 ' || (5000100 + EXTRACT(YEAR FROM v_mes)::INT * 12 + EXTRACT(MONTH FROM v_mes)::INT)::TEXT;

        -- Compras (vía A del área 1; el trigger del área 3 suma stock, volumen y capital)
        v_n := 0;
        FOR e IN SELECT h.*, p.costo, p.proveedor, p.moneda AS moneda_plan, p.nombre FROM h_ent h JOIN h_prod p USING (id_producto)
                 WHERE h.mes = v_mes ORDER BY h.id_producto LOOP
            v_n := v_n + 1;
            IF e.ultima THEN
                SELECT costo_unitario, flete_unitario, impuestos_unitarios, moneda, tipo_cambio INTO v_costo, v_flete, v_impu, v_moneda, v_r
                  FROM h_orig WHERE id_producto = e.id_producto;
            ELSIF e.moneda_plan = 'USD' THEN
                v_moneda := 'USD'; v_r := v_tc;
                v_costo := ROUND(e.costo / v_tc / 1.17 * (0.97 + random()::NUMERIC * 0.06), 2);
                v_flete := ROUND(v_costo * 0.02, 2);
                v_impu  := ROUND(v_costo * 0.15, 2);
            ELSE
                v_moneda := 'MXN'; v_r := 1;
                v_costo := ROUND(e.costo * (0.97 + random()::NUMERIC * 0.06), 2);
                v_flete := ROUND(v_costo * 0.02, 2);
                v_impu  := 0;
            END IF;
            v_doc := CASE WHEN v_moneda = 'USD' THEN 'IMP-' ELSE 'F-' END || TO_CHAR(v_mes, 'YYMM') || '-' || LPAD(v_n::TEXT, 3, '0');
            INSERT INTO entradas_producto (id_producto, fecha, cantidad, cantidad_esperada, estado_mercancia, costo_unitario, flete_unitario,
                                           impuestos_unitarios, moneda, tipo_cambio, pais_origen, id_proveedor, id_almacen,
                                           numero_factura_proveedor, fecha_factura_proveedor, documento_importacion_ref,
                                           responsable_recepcion, observaciones, documento_ref)
            SELECT e.id_producto, v_mes, e.cantidad,
                   CASE WHEN v_n % 17 = 5 THEN e.cantidad + 2 + v_n % 7 ELSE e.cantidad END,
                   CASE WHEN v_n % 17 = 5 THEN 'INCOMPLETO'::estado_mercancia ELSE 'BUEN_ESTADO'::estado_mercancia END,
                   v_costo, v_flete, v_impu, v_moneda, v_r,
                   CASE WHEN v_moneda = 'USD' THEN 'China' ELSE 'México' END,
                   pv.id_proveedor, v_alm, v_doc, v_mes - 3,
                   CASE WHEN v_moneda = 'USD' AND v_mes <= DATE '2026-07-01' THEN 'Pedimento ' || v_ped END,
                   CASE WHEN v_n % 2 = 0 THEN 'Luis Ortega' ELSE 'Almacén PT' END,
                   CASE WHEN v_n % 17 = 5 THEN 'Faltante reportado al proveedor; nota de crédito en trámite' END,
                   v_doc
            FROM proveedores pv
            WHERE pv.nombre = CASE WHEN e.nombre IN ('Mouse inalámbrico 2.4G', 'Teclado mecánico RGB') AND v_mes < DATE '2025-03-01'
                                   THEN 'Distribuidora Antigua SA' ELSE e.proveedor END
            RETURNING id_entrada INTO v_ent;
            UPDATE h_ent SET id_entrada = v_ent WHERE mes = v_mes AND id_producto = e.id_producto;
        END LOOP;

        -- Facturas del mes (folio, vencimiento y totales por trigger; cobro con fecha explícita, RN-A2-08)
        FOR f IN SELECT * FROM h_fac WHERE mes = v_mes ORDER BY fecha, id_plan LOOP
            INSERT INTO facturas (id_cliente, id_agente, fecha) VALUES (f.id_cliente, f.id_agente, f.fecha) RETURNING id_factura INTO v_fac;
            UPDATE facturas SET uuid_cfdi = (SELECT SUBSTR(h, 1, 8) || '-' || SUBSTR(h, 9, 4) || '-4' || SUBSTR(h, 14, 3) || '-a' || SUBSTR(h, 18, 3) || '-' || SUBSTR(h, 21, 12)
                                              FROM (SELECT MD5('SIGFEVAK-CFDI-' || v_fac) AS h) x)
             WHERE id_factura = v_fac;
            FOR l IN SELECT * FROM h_lin WHERE id_plan = f.id_plan LOOP
                INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES (v_fac, l.id_producto, l.cantidad, l.precio);
            END LOOP;
            IF f.cancelada THEN
                UPDATE facturas SET estado_pago = 'CANCELADO' WHERE id_factura = v_fac;
            ELSE
                UPDATE facturas SET estado_pago = 'PAGADO', fecha_cobro = f.cobro WHERE id_factura = v_fac;
            END IF;
        END LOOP;

        -- Conciliación de fin de trimestre
        FOR a IN SELECT * FROM h_aj WHERE mes = v_mes LOOP
            INSERT INTO ajustes_inventario (id_producto, fecha, conteo_fisico, motivo, responsable)
            SELECT a.id_producto, v_eom, stock - a.faltante,
                   CASE a.faltante % 3 WHEN 0 THEN 'Piezas dañadas en maniobra de descarga' WHEN 1 THEN 'Faltante en conteo cíclico de fin de trimestre'
                                       ELSE 'Merma por exhibición y muestras a clientes' END,
                   'Luis Ortega'
            FROM productos WHERE id_producto = a.id_producto;
        END LOOP;

        -- ---------- Nómina del mes (RN-A4-03, RN-A4-13, RN-A4-15) ----------
        IF v_mes = DATE '2025-07-01' THEN
            NULL;  -- Rodrigo cobra su último mes completo en julio
        ELSIF v_mes = DATE '2025-08-01' THEN
            UPDATE agentes_ventas SET estatus = 'BAJA' WHERE nombre = 'Rodrigo Beltrán';
        END IF;
        IF v_mes >= DATE '2024-10-01' THEN
        FOR a IN SELECT id_agente FROM agentes_ventas WHERE estatus = 'ACTIVO' ORDER BY id_agente LOOP
            SELECT COALESCE(SUM(subtotal), 0) INTO v_ventas FROM v_ventas_cobradas_agente WHERE id_agente = a.id_agente AND periodo = v_periodo;
            INSERT INTO metas (id_agente, periodo, monto_meta, sin_retardos)
            VALUES (a.id_agente, v_periodo, GREATEST(ROUND(v_ventas * (0.82 + random()::NUMERIC * 0.36) / 5000) * 5000, 60000), random()::NUMERIC > 0.15)
            ON CONFLICT (id_agente, periodo) DO NOTHING;
        END LOOP;
        INSERT INTO periodos_nomina (tipo, fecha_inicio, fecha_fin) VALUES ('MENSUAL', v_mes, v_eom) RETURNING id_periodo INTO v_per;
        PERFORM fn_calcular_periodo(v_per, 'contador@sigfevak.mx');
        PERFORM pg_temp.h_fechar((v_eom - 3) + TIME '17:30');
        IF random()::NUMERIC < 0.12 THEN
            UPDATE periodos_nomina SET estatus = 'ABIERTO', revisado_por = 'gerente@sigfevak.mx',
                   comentario = CASE WHEN random()::NUMERIC < 0.5 THEN 'Falta reflejar un cobro registrado tarde por contabilidad'
                                     ELSE 'Revisar la meta de un agente; la capturada no es la acordada' END
             WHERE id_periodo = v_per;
            PERFORM pg_temp.h_fechar((v_eom - 2) + TIME '10:00');
            PERFORM fn_calcular_periodo(v_per, 'contador@sigfevak.mx');
            PERFORM pg_temp.h_fechar((v_eom - 2) + TIME '13:15');
        END IF;
        UPDATE bonos_asignados SET fecha = v_eom WHERE id_periodo = v_per;
        UPDATE periodos_nomina SET estatus = 'REVISADO', revisado_por = 'gerente@sigfevak.mx' WHERE id_periodo = v_per;
        PERFORM fn_calcular_nomina(v_per);
        PERFORM pg_temp.h_fechar((v_eom - 1) + TIME '11:00');
        UPDATE periodos_nomina SET estatus = 'AUTORIZADO', autorizado_por = 'autorizador@sigfevak.mx' WHERE id_periodo = v_per;
        PERFORM pg_temp.h_fechar((v_eom - 1) + TIME '16:40');
        UPDATE periodos_nomina SET estatus = 'PAGADO', fecha_pago = v_eom WHERE id_periodo = v_per;
        PERFORM pg_temp.h_fechar(v_eom + TIME '09:00');
        UPDATE periodos_nomina SET estatus = 'CERRADO' WHERE id_periodo = v_per;
        PERFORM pg_temp.h_fechar((v_eom + 2) + TIME '10:30');
        END IF;

        -- ---------- Pedimento del mes con las compras en USD (RN-A5-08, RN-A5-12, RN-A5-13) ----------
        IF v_mes <= DATE '2026-07-01' AND EXISTS (SELECT 1 FROM h_ent h JOIN entradas_producto ep USING (id_entrada) WHERE h.mes = v_mes AND ep.moneda = 'USD') THEN
            INSERT INTO obligaciones (id_tipo_obligacion, fecha_vencimiento, id_responsable)
            SELECT id_tipo_obligacion, v_mes, v_admin FROM tipos_obligacion WHERE clave = 'PEDIMENTO'
            RETURNING id_obligacion INTO v_obl;
            INSERT INTO importaciones (id_obligacion, id_entrada, numero_pedimento, aduana, agente_aduanal, pais_origen, pais_procedencia,
                                       fecha_importacion, valor_aduanero, padron_importador, encargo_conferido)
            SELECT v_obl, (SELECT ep.id_entrada FROM h_ent h JOIN entradas_producto ep USING (id_entrada)
                            WHERE h.mes = v_mes AND ep.moneda = 'USD' ORDER BY ep.cantidad * ep.costo_unitario DESC LIMIT 1),
                   v_ped, CASE WHEN EXTRACT(MONTH FROM v_mes)::INT % 4 = 0 THEN 'Lázaro Cárdenas' ELSE 'Manzanillo' END,
                   'Agencia Aduanal del Pacífico', 'China', 'China', v_mes - 2,
                   SUM(ROUND(ep.costo_unitario * ep.tipo_cambio, 2) * ep.cantidad), 'PI-2024-08812', 'EC-' || TO_CHAR(v_mes, 'YYYY') || '-0031'
            FROM h_ent h JOIN entradas_producto ep USING (id_entrada)
            WHERE h.mes = v_mes AND ep.moneda = 'USD'
            RETURNING id_importacion INTO v_imp;
            INSERT INTO productos_importados (id_importacion, id_producto, nombre, marca, modelo, cantidad, valor_unitario, fraccion_arancelaria, nico)
            SELECT v_imp, ep.id_producto, p.nombre, p.marca, p.modelo, ep.cantidad, ROUND(ep.costo_unitario * ep.tipo_cambio, 2), hp.fraccion, '00'
            FROM h_ent h JOIN entradas_producto ep USING (id_entrada) JOIN productos p ON p.id_producto = ep.id_producto
            JOIN h_prod hp ON hp.id_producto = ep.id_producto
            WHERE h.mes = v_mes AND ep.moneda = 'USD';
            INSERT INTO documentos_fiscales (id_obligacion, tipo_documento, nombre, referencia, fecha)
            VALUES (v_obl, 'PEDIMENTO', 'Pedimento ' || v_ped, 'docs/pedimentos/' || TO_CHAR(v_mes, 'YYYY-MM') || '.pdf', v_mes - 2);
            PERFORM pg_temp.h_fechar((v_mes - 2) + TIME '08:30');
            SELECT total_contribuciones INTO v_monto FROM importaciones WHERE id_importacion = v_imp;
            PERFORM pg_temp.h_recorrer_obligacion(v_obl, v_monto, v_mes + 7, v_admin, v_autorizador, NULL, FALSE, 'pedimento ' || v_ped);
        END IF;

        -- ---------- Obligaciones periódicas del mes, de pendiente a cerrado (RN-A5-03, RN-A5-14) ----------
        IF v_mes <= DATE '2026-06-01' THEN
            PERFORM fn_generar_obligaciones_periodo(v_periodo);
            SELECT subtotal, iva_trasladado INTO v_sub, v_tras FROM v_iva_trasladado_periodo WHERE periodo = v_periodo;
            SELECT COALESCE(SUM(ep.cantidad * (ep.costo_unitario + ep.flete_unitario + ep.impuestos_unitarios) * ep.tipo_cambio), 0) * 0.16
              INTO v_acred FROM entradas_producto ep WHERE ep.fecha = v_mes;
            FOR o IN SELECT ob.id_obligacion, ob.fecha_vencimiento, ob.monto_estimado, ob.periodo, t.clave, t.nombre
                       FROM obligaciones ob JOIN tipos_obligacion t USING (id_tipo_obligacion)
                      WHERE ob.estado = 'PENDIENTE' AND (ob.periodo = v_periodo OR ob.periodo = TO_CHAR(v_mes, 'YYYY'))
                      ORDER BY ob.id_obligacion LOOP
                v_monto := CASE o.clave
                    WHEN 'IVA_MENSUAL' THEN GREATEST(ROUND(COALESCE(v_tras, 0) - v_acred, 2), ROUND(COALESCE(v_tras, 0) * 0.12, 2))
                    WHEN 'ISR_PROV'    THEN ROUND(COALESCE(v_sub, 0) * fn_parametro_fiscal('COEFICIENTE_UTILIDAD', NULL, NULL, o.fecha_vencimiento)
                                                                     * fn_parametro_fiscal('TASA_ISR_PM', NULL, NULL, o.fecha_vencimiento), 2)
                    WHEN 'ISR_ANUAL'   THEN ROUND((SELECT SUM(monto_final) FROM obligaciones ob2 JOIN tipos_obligacion t2 USING (id_tipo_obligacion)
                                                    WHERE t2.clave = 'ISR_PROV' AND ob2.periodo LIKE o.periodo || '-%') * 0.08, 2)
                    ELSE o.monto_estimado END;
                IF COALESCE(v_monto, 0) <= 0 THEN CONTINUE; END IF;
                PERFORM pg_temp.h_fechar(o.fecha_vencimiento - 30 + TIME '07:00');
                PERFORM pg_temp.h_recorrer_obligacion(o.id_obligacion, v_monto, o.fecha_vencimiento, v_contador, v_autorizador,
                    CASE o.clave WHEN 'ISR_ANUAL' THEN 'Anual normal' WHEN 'ISN_CHIAPAS' THEN 'Normal' ELSE 'Definitiva' END,
                    o.clave <> 'ISN_CHIAPAS', o.nombre || ' ' || o.periodo);
            END LOOP;
        END IF;
    END LOOP;

    -- Bajas lógicas de clientes que dejaron de comprar (RN-A2-10)
    UPDATE clientes SET activo = FALSE WHERE rfc IN ('CAC050101UV1', 'MTA170808AB6');

    -- ---------- Licencias vencidas que ya se renovaron (sección 6.4 del área 5) ----------
    INSERT INTO licencias_permisos (tipo_licencia, autoridad_emisora, municipio, numero_licencia, fecha_emision, fecha_vencimiento, costo, estado)
    SELECT v.tipo, v.autoridad, v.municipio, v.numero, v.emision, v.vencimiento, v.costo, 'VENCIDA' FROM (VALUES
        ('USO_SUELO',               'Ayuntamiento de Tuxtla Gutiérrez',            'Tuxtla Gutiérrez', 'US-2024-03310',   DATE '2024-10-01', DATE '2025-09-30', 4500.00),
        ('LICENCIA_FUNCIONAMIENTO', 'Ayuntamiento de Tuxtla Gutiérrez',            'Tuxtla Gutiérrez', 'LF-2025-00941',   DATE '2025-01-15', DATE '2026-01-14', 6100.00),
        ('LICENCIA_FUNCIONAMIENTO', 'Ayuntamiento de Tuxtla Gutiérrez',            'Tuxtla Gutiérrez', 'LF-2024-00712',   DATE '2024-01-15', DATE '2025-01-14', 5800.00),
        ('PROTECCION_CIVIL',        'Protección Civil del Estado de Chiapas',      'Tuxtla Gutiérrez', 'PIPC-2024-0788',  DATE '2024-08-20', DATE '2025-08-19', 11500.00),
        ('SIEM',                    'Sistema de Información Empresarial Mexicano', NULL,               'SIEM-2025-70311', DATE '2025-03-10', DATE '2026-03-09', 650.00)
    ) AS v(tipo, autoridad, municipio, numero, emision, vencimiento, costo);
    PERFORM pg_temp.h_fechar(TIMESTAMP '2024-09-02 09:00');
END $$;

-- ---------- 8. CAMPAÑAS E INVESTIGACIONES HISTÓRICAS (RN-A6-02, RN-A6-03, RN-A6-13, RN-A6-15) ----------
DO $$
DECLARE
    v_mkt UUID; v_id INT;
    v_tv INT; v_radio INT; v_redes INT; v_correo INT; v_wa INT; v_llamada INT; v_evento INT;
    v_agencia INT; v_medio INT; v_plataforma INT;
BEGIN
    IF EXISTS (SELECT 1 FROM campanas WHERE nombre = 'Buen Fin 2024 mayoristas') THEN RETURN; END IF;
    SELECT id_usuario INTO v_mkt FROM usuarios WHERE correo = 'marketing@sigfevak.mx';
    SELECT id_canal INTO v_tv      FROM canales_marketing WHERE nombre = 'TV';
    SELECT id_canal INTO v_radio   FROM canales_marketing WHERE nombre = 'Radio';
    SELECT id_canal INTO v_redes   FROM canales_marketing WHERE nombre = 'Redes sociales';
    SELECT id_canal INTO v_correo  FROM canales_marketing WHERE nombre = 'Correo';
    SELECT id_canal INTO v_wa      FROM canales_marketing WHERE nombre = 'WhatsApp';
    SELECT id_canal INTO v_llamada FROM canales_marketing WHERE nombre = 'Llamada';
    SELECT id_canal INTO v_evento  FROM canales_marketing WHERE nombre = 'Evento';
    SELECT id_proveedor_marketing INTO v_agencia    FROM proveedores_marketing WHERE tipo_servicio = 'AGENCIA';
    SELECT id_proveedor_marketing INTO v_medio      FROM proveedores_marketing WHERE tipo_servicio = 'MEDIO';
    SELECT id_proveedor_marketing INTO v_plataforma FROM proveedores_marketing WHERE tipo_servicio = 'PLATAFORMA_DIGITAL';

    INSERT INTO proveedores_marketing (razon_social, rfc, tipo_servicio, contacto_nombre, contacto_email, contacto_telefono)
    SELECT 'Opinión y Mercado del Sureste SC', 'OMS150610PQ7', 'ESTUDIO_MERCADO', 'Laura Méndez', 'lmendez@opinionsureste.mx', '961 555 0199'
    WHERE NOT EXISTS (SELECT 1 FROM proveedores_marketing WHERE razon_social = 'Opinión y Mercado del Sureste SC');

    -- Buen Fin 2024 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Buen Fin 2024 mayoristas', 'EXTERNO', 'Mover inventario de audio y tabletas con los mayoristas antes de Navidad', DATE '2024-11-04', DATE '2024-11-20', 60000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_redes, v_plataforma, 'Pauta en redes Buen Fin',        26000.00, DATE '2024-11-05', 'PAGADO'),
        (v_id, v_radio, v_medio,      'Spots en radio regional',        17500.00, DATE '2024-11-06', 'PAGADO'),
        (v_id, v_redes, v_agencia,    'Diseño de piezas y video corto',  9800.00, DATE '2024-10-28', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato) VALUES
        (v_id, v_redes, DATE '2024-11-04', DATE '2024-11-12', 210500, 118000, 5230, 402, 51, 168000.00, 'Meta Ads'),
        (v_id, v_radio, DATE '2024-11-06', DATE '2024-11-20', 0, 85000, 0, 96, 14, 54000.00, 'Manual');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Tableta Android 10" OEM', 'Auriculares BT TW-55', 'Bocina Portátil BT 20W');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Posicionamiento en redes Q1 2025 (EXTERNO, cancelada a medio camino)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Posicionamiento en redes Q1 2025', 'EXTERNO', 'Construir audiencia de revendedores en redes', DATE '2025-01-15', DATE '2025-03-31', 35000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_redes, v_plataforma, 'Pauta de enero', 8000.00, DATE '2025-01-16', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato)
    VALUES (v_id, v_redes, DATE '2025-01-15', DATE '2025-02-05', 64000, 31000, 820, 38, 2, 6500.00, 'Meta Ads');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'CANCELADA', descripcion = 'Cancelada en febrero: el costo por lead triplicó lo planeado' WHERE id_campana = v_id;

    -- Reactivación cartera Bajío y centro (DIRECTO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Reactivación cartera centro 2025', 'DIRECTO', 'Recuperar pedidos de comercializadores del centro que bajaron compras', DATE '2025-03-01', DATE '2025-03-31', 12000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO campana_clientes (id_campana, id_cliente, id_canal, fecha_contacto, estado_contacto, notas)
    SELECT v_id, c.id_cliente, v.canal, v.fecha, v.estado::estado_contacto, v.notas FROM (VALUES
        ('RHC001120OP8', v_llamada, DATE '2025-03-03', 'CONVERTIDO',    'Pedido de reguladores y multicontactos'),
        ('DSQ180605KL7', v_wa,      DATE '2025-03-04', 'CONVERTIDO',    'Volvió a comprar tras la llamada del agente'),
        ('CAC050101UV1', v_correo,  DATE '2025-03-05', 'NO_INTERESADO', 'Cierra operaciones en abril'),
        ('RMX040815EF3', v_correo,  DATE '2025-03-05', 'RESPONDIO',     'Pide lista de precios de mayo')
    ) AS v(rfc, canal, fecha, estado, notas) JOIN clientes c ON c.rfc = v.rfc;
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_llamada, 'Horas de llamadas del ejecutivo',     4200.00, DATE '2025-03-10', 'PAGADO'),
        (v_id, v_wa,      'Mensajería WhatsApp Business',        3100.00, DATE '2025-03-04', 'PAGADO'),
        (v_id, v_correo,  'Plataforma de correo masivo',         1500.00, DATE '2025-03-05', 'PAGADO');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Regulador de voltaje 1200VA', 'Multicontacto 6 salidas');
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Expo Electrónica Sureste 2025 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Expo Electrónica Sureste 2025', 'EXTERNO', 'Presencia en la feria regional de electrónica', DATE '2025-07-09', DATE '2025-07-11', 28000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_evento, NULL,      'Stand y montaje',          17200.00, DATE '2025-06-30', 'PAGADO'),
        (v_id, v_evento, v_agencia, 'Material impreso y demo',   5900.00, DATE '2025-07-02', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato)
    VALUES (v_id, v_evento, DATE '2025-07-09', DATE '2025-07-11', 0, 2100, 0, 58, 7, 36500.00, 'Manual');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Cámara IP WiFi 1080p', 'Router Wi-Fi 6 AX1800');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Regreso a clases 2025 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Regreso a clases 2025', 'EXTERNO', 'Impulsar tabletas, fundas y audífonos en temporada escolar', DATE '2025-07-21', DATE '2025-08-31', 45000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_redes, v_plataforma, 'Pauta en redes',             21000.00, DATE '2025-07-22', 'PAGADO'),
        (v_id, v_tv,    v_medio,      'Menciones en TV regional',   14500.00, DATE '2025-08-04', 'PAGADO'),
        (v_id, v_redes, v_agencia,    'Producción de video',         6200.00, DATE '2025-07-15', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato) VALUES
        (v_id, v_redes, DATE '2025-07-21', DATE '2025-08-10', 240300, 131000, 6110, 455, 60, 142000.00, 'Meta Ads'),
        (v_id, v_tv,    DATE '2025-08-04', DATE '2025-08-31', 0, 190000, 0, 120, 18, 61000.00, 'Manual');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Tableta Android 10" OEM', 'Funda tablet 10" negra', 'Auriculares BT TW-55');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Clientes nuevos del sureste (DIRECTO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Clientes del sureste 2025', 'DIRECTO', 'Aumentar el ticket de los comercializadores del sureste', DATE '2025-09-01', DATE '2025-09-30', 10000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO campana_clientes (id_campana, id_cliente, id_canal, fecha_contacto, estado_contacto, notas)
    SELECT v_id, c.id_cliente, v.canal, v.fecha, v.estado::estado_contacto, v.notas FROM (VALUES
        ('PDT191111QR1', v_wa,      DATE '2025-09-02', 'CONVERTIDO', 'Compró kit de cámaras para un fraccionamiento'),
        ('CHE990412MN8', v_llamada, DATE '2025-09-03', 'CONVERTIDO', NULL),
        ('DEG110907CD3', v_wa,      DATE '2025-09-03', 'RESPONDIO',  'Cotizó monitores; decide en octubre'),
        ('MUO120118IJ6', v_correo,  DATE '2025-09-04', 'CONTACTADO', NULL),
        ('ESU110303QR9', v_llamada, DATE '2025-09-05', 'CONVERTIDO', 'Amplió su pedido mensual')
    ) AS v(rfc, canal, fecha, estado, notas) JOIN clientes c ON c.rfc = v.rfc;
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_wa,      'Mensajería WhatsApp Business', 3800.00, DATE '2025-09-02', 'PAGADO'),
        (v_id, v_llamada, 'Horas de llamadas',            4100.00, DATE '2025-09-15', 'PAGADO');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Cámara IP WiFi 1080p', 'Monitor LED 24" FHD');
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Buen Fin 2025 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Buen Fin 2025 mayoristas', 'EXTERNO', 'Repetir el Buen Fin con smartwatch y cámaras IP', DATE '2025-11-03', DATE '2025-11-19', 65000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_redes, v_plataforma, 'Pauta en redes Buen Fin',   29500.00, DATE '2025-11-04', 'PAGADO'),
        (v_id, v_radio, v_medio,      'Spots en radio regional',   18000.00, DATE '2025-11-05', 'PAGADO'),
        (v_id, v_redes, v_agencia,    'Campaña creativa',          12400.00, DATE '2025-10-27', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato) VALUES
        (v_id, v_redes, DATE '2025-11-03', DATE '2025-11-12', 265800, 150200, 7040, 520, 66, 214000.00, 'Meta Ads'),
        (v_id, v_radio, DATE '2025-11-05', DATE '2025-11-19', 0, 92000, 0, 110, 15, 58000.00, 'Manual');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Smartwatch Fitness Pro', 'Cámara IP WiFi 1080p');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Navidad 2025 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Navidad mayorista 2025', 'EXTERNO', 'Surtir a tiempo a las cadenas para diciembre', DATE '2025-12-01', DATE '2025-12-20', 70000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_tv,    v_medio,      'Spot navideño en TV regional', 32000.00, DATE '2025-12-02', 'PAGADO'),
        (v_id, v_redes, v_plataforma, 'Pauta en redes',               24000.00, DATE '2025-12-01', 'PAGADO'),
        (v_id, v_redes, v_agencia,    'Producción del spot',           9500.00, DATE '2025-11-24', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato) VALUES
        (v_id, v_tv,    DATE '2025-12-02', DATE '2025-12-20', 0, 260000, 0, 140, 22, 96000.00, 'Manual'),
        (v_id, v_redes, DATE '2025-12-01', DATE '2025-12-20', 198000, 104000, 4890, 380, 44, 131000.00, 'Meta Ads');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Tableta Android 10" OEM', 'Bocina Portátil BT 20W', 'Power bank 20000 mAh');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Mayoristas del norte primavera 2026 (DIRECTO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Mayoristas del norte primavera 2026', 'DIRECTO', 'Crecer volumen en Nuevo León, Baja California y Sinaloa', DATE '2026-03-02', DATE '2026-03-31', 14000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO campana_clientes (id_campana, id_cliente, id_canal, fecha_contacto, estado_contacto, notas)
    SELECT v_id, c.id_cliente, v.canal, v.fecha, v.estado::estado_contacto, v.notas FROM (VALUES
        ('TAM170314EF4', v_llamada, DATE '2026-03-03', 'CONVERTIDO',    'Pedido grande de routers'),
        ('STB160930OP9', v_wa,      DATE '2026-03-03', 'CONVERTIDO',    NULL),
        ('IDS130227ST2', v_correo,  DATE '2026-03-04', 'RESPONDIO',     'Pide crédito a 45 días'),
        ('MPA090917ST0', v_correo,  DATE '2026-03-04', 'NO_INTERESADO', 'Surtido por otro mayorista')
    ) AS v(rfc, canal, fecha, estado, notas) JOIN clientes c ON c.rfc = v.rfc;
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_llamada, 'Visitas y llamadas del ejecutivo', 7600.00, DATE '2026-03-12', 'PAGADO'),
        (v_id, v_wa,      'Mensajería WhatsApp Business',     2900.00, DATE '2026-03-03', 'PAGADO');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Router Wi-Fi 6 AX1800', 'Cargador USB-C 65W GaN');
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Hot Sale 2026 (EXTERNO)
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, id_responsable, creado_por)
    VALUES ('Hot Sale 2026', 'EXTERNO', 'Acompañar las ventas en línea de las cadenas con accesorios', DATE '2026-05-25', DATE '2026-06-02', 40000.00, v_mkt, v_mkt)
    RETURNING id_campana INTO v_id;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_id, v_redes, v_plataforma, 'Pauta en redes Hot Sale', 23000.00, DATE '2026-05-24', 'PAGADO'),
        (v_id, v_redes, v_agencia,    'Piezas para cadenas',      8700.00, DATE '2026-05-18', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato)
    VALUES (v_id, v_redes, DATE '2026-05-25', DATE '2026-06-02', 187000, 99000, 4410, 290, 37, 98000.00, 'Meta Ads');
    INSERT INTO campana_productos (id_campana, id_producto) SELECT v_id, id_producto FROM productos WHERE nombre IN ('Cargador USB-C 65W GaN', 'Cable USB-C a USB-C 1m', 'Power bank 20000 mAh');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_id;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_id;

    -- Investigaciones de mercado
    INSERT INTO investigaciones_mercado (titulo, tipo, id_campana, objetivo, metodologia, tamano_muestra, id_proveedor_marketing, costo, fecha_inicio, fecha_fin, estado, resumen_hallazgos, creado_por)
    SELECT v.titulo, v.tipo::tipo_investigacion, (SELECT id_campana FROM campanas WHERE nombre = v.campana), v.objetivo, v.metodo, v.muestra,
           (SELECT id_proveedor_marketing FROM proveedores_marketing WHERE razon_social = v.proveedor), v.costo, v.inicio, v.fin, v.estado::estado_investigacion, v.hallazgos, v_mkt
    FROM (VALUES
        ('Satisfacción de comercializadores 2024', 'ESTUDIO_SATISFACCION', NULL, 'Medir tiempos de entrega y trato del agente', 'Encuesta telefónica a clientes activos', 22,
         'Opinión y Mercado del Sureste SC', 14500.00, DATE '2024-10-07', DATE '2024-10-25', 'FINALIZADA', 'El 81 % califica el servicio como bueno; la queja principal es el surtido incompleto de cables'),
        ('Resultados del Buen Fin 2024', 'ANALISIS_MERCADO', 'Buen Fin 2024 mayoristas', 'Comparar ventas del Buen Fin contra noviembre 2023', 'Análisis de facturación y reportes de cadenas', NULL,
         NULL, 0, DATE '2024-11-25', DATE '2024-12-06', 'FINALIZADA', 'Audio creció 38 % y tabletas 22 %; radio atrajo clientes nuevos en el sureste'),
        ('Focus group de accesorios de energía', 'FOCUS_GROUP', NULL, 'Entender qué valoran los revendedores en cargadores y reguladores', 'Dos sesiones con 8 revendedores en Tuxtla y Querétaro', 16,
         'Opinión y Mercado del Sureste SC', 18000.00, DATE '2025-05-12', DATE '2025-05-30', 'FINALIZADA', 'Garantía y empaque pesan más que el precio; piden kits de cargador más cable'),
        ('Benchmark de precios de cámaras IP 2025', 'BENCHMARKING_COMPETENCIA', NULL, 'Comparar precio y garantía contra tres marcas', 'Levantamiento en tiendas en línea y mayoristas', NULL,
         NULL, 0, DATE '2025-10-06', DATE '2025-10-17', 'FINALIZADA', 'Nuestro precio está 6 % abajo del promedio; la competencia ofrece dos años de garantía'),
        ('Satisfacción de comercializadores 2025', 'ESTUDIO_SATISFACCION', NULL, 'Repetir la medición anual de servicio', 'Encuesta en línea a clientes activos', 24,
         'Opinión y Mercado del Sureste SC', 15200.00, DATE '2025-10-13', DATE '2025-10-31', 'FINALIZADA', 'Sube a 86 % la calificación buena; mejora el surtido de cables tras cambiar de proveedor')
    ) AS v(titulo, tipo, campana, objetivo, metodo, muestra, proveedor, costo, inicio, fin, estado, hallazgos);
END $$;
