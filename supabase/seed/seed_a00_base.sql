-- Área 00 (coordinación) · Seed compartido · docs/MODELO_DATOS.md
-- Qué hace: rol de las seis cuentas de demostración, 10 clientes, 5 agentes y 15 facturas de ejemplo.
-- Idempotente: se puede correr varias veces sin duplicar.

-- ---------- USUARIOS: rol por correo (las cuentas ya existen en Supabase Auth) ----------
INSERT INTO usuarios (id_usuario, nombre, correo, rol, area)
SELECT u.id, v.nombre, u.email, v.rol::rol_usuario, v.area
FROM auth.users u
JOIN (VALUES
    ('admin@sigfevak.mx',       'Administración',        'ADMINISTRADOR',  NULL),
    ('almacen@sigfevak.mx',     'Almacén',               'ALMACEN',        3),
    ('contador@sigfevak.mx',    'Contabilidad',          'CONTADOR',       2),
    ('gerente@sigfevak.mx',     'Gerencia de ventas',    'GERENTE_VENTAS', 4),
    ('autorizador@sigfevak.mx', 'Autorización financiera','AUTORIZADOR',   5),
    ('marketing@sigfevak.mx',   'Marketing',             'MARKETING',      6)
) AS v(correo, nombre, rol, area) ON v.correo = u.email
ON CONFLICT (id_usuario) DO UPDATE SET rol = EXCLUDED.rol, nombre = EXCLUDED.nombre, area = EXCLUDED.area;

-- ---------- CLIENTES (comercializadores) ----------
INSERT INTO clientes (nombre_empresa, rfc, estado)
SELECT * FROM (VALUES
    ('Elektra Mayoreo S.A. de C.V.',      'EMA150312AB1', 'Ciudad de México'),
    ('COPPEL Distribución S.A. de C.V.',  'CDI980722CD2', 'Sinaloa'),
    ('RadioShack México S.A. de C.V.',    'RMX040815EF3', 'Nuevo León'),
    ('Best Buy México S. de R.L.',        'BBM070910GH4', 'Jalisco'),
    ('TechMex CDMX S.A. de C.V.',         'TCD190405IJ5', 'Ciudad de México'),
    ('Norte Digital S.A. de C.V.',        'NDI160228KL6', 'Chihuahua'),
    ('Distribuidora Bajío S.A. de C.V.',  'DBA120614MN7', 'Guanajuato'),
    ('Ramírez & Hijos Comercial S.A.',    'RHC001120OP8', 'Puebla'),
    ('Electrónica del Sureste S.A.',      'ESU110303QR9', 'Chiapas'),
    ('Mayoreo Pacífico S.A. de C.V.',     'MPA090917ST0', 'Baja California')
) AS v(nombre_empresa, rfc, estado)
WHERE NOT EXISTS (SELECT 1 FROM clientes c WHERE c.rfc = v.rfc);

-- ---------- AGENTES DE VENTAS ----------
INSERT INTO agentes_ventas (nombre, sueldo_base, comision)
SELECT * FROM (VALUES
    ('Jorge Mendoza',     10640.00, 3.00),
    ('Patricia Leal',     10640.00, 3.00),
    ('Andrés Fuentes',    10640.00, 2.00),
    ('Verónica Castillo', 10640.00, 3.00),
    ('Miguel Torres',     13402.00, 1.00)
) AS v(nombre, sueldo_base, comision)
WHERE NOT EXISTS (SELECT 1 FROM agentes_ventas a WHERE a.nombre = v.nombre);

-- ---------- FACTURAS (cabeceras; los renglones los agrega el seed del área 3 cuando exista productos) ----------
INSERT INTO facturas (id_cliente, id_agente, fecha, valor_total, iva, estado_pago)
SELECT c.id_cliente, a.id_agente, v.fecha, v.subtotal * 1.16, v.subtotal * 0.16, v.estado::estado_pago
FROM (VALUES
    ('EMA150312AB1', 'Jorge Mendoza',     DATE '2026-08-04', 342000.00, 'PAGADO'),
    ('CDI980722CD2', 'Patricia Leal',     DATE '2026-08-06', 189500.00, 'PAGADO'),
    ('RMX040815EF3', 'Andrés Fuentes',    DATE '2026-08-11', 95200.00,  'PAGADO'),
    ('BBM070910GH4', 'Verónica Castillo', DATE '2026-08-15', 512000.00, 'PAGADO'),
    ('TCD190405IJ5', 'Jorge Mendoza',     DATE '2026-08-20', 78400.00,  'PAGADO'),
    ('NDI160228KL6', 'Patricia Leal',     DATE '2026-08-25', 143000.00, 'PAGADO'),
    ('DBA120614MN7', 'Miguel Torres',     DATE '2026-08-28', 66500.00,  'PAGADO'),
    ('RHC001120OP8', 'Andrés Fuentes',    DATE '2026-09-01', 210000.00, 'PAGADO'),
    ('ESU110303QR9', 'Verónica Castillo', DATE '2026-09-02', 58000.00,  'PARCIAL'),
    ('MPA090917ST0', 'Jorge Mendoza',     DATE '2026-09-03', 124000.00, 'PENDIENTE'),
    ('EMA150312AB1', 'Patricia Leal',     DATE '2026-09-05', 99000.00,  'PENDIENTE'),
    ('CDI980722CD2', 'Jorge Mendoza',     DATE '2026-09-06', 45000.00,  'PENDIENTE'),
    ('BBM070910GH4', 'Miguel Torres',     DATE '2026-09-08', 312000.00, 'PENDIENTE'),
    ('TCD190405IJ5', 'Verónica Castillo', DATE '2026-09-09', 27500.00,  'CANCELADO'),
    ('RMX040815EF3', 'Andrés Fuentes',    DATE '2026-09-10', 88000.00,  'PENDIENTE')
) AS v(rfc, agente, fecha, subtotal, estado)
JOIN clientes c ON c.rfc = v.rfc
JOIN agentes_ventas a ON a.nombre = v.agente
WHERE NOT EXISTS (SELECT 1 FROM facturas);
