-- Área 6 · Issue #113 · RN-A6-01 a RN-A6-16
-- Qué hace: 7 canales (las cuatro categorías), 3 proveedores de tipos distintos, 4 campañas (2 EXTERNO y 2
-- DIRECTO, una FINALIZADA) con costos, métricas, productos y clientes objetivo en los cinco estados de contacto,
-- y 2 investigaciones. Reproduce el caso A y el caso B de la sección 10. Idempotente.

INSERT INTO canales_marketing (nombre, categoria, descripcion) VALUES
    ('TV',             'TRADICIONAL', 'Televisión regional'),
    ('Radio',          'TRADICIONAL', 'Radio regional'),
    ('Redes sociales', 'DIGITAL',     'Meta, TikTok, YouTube'),
    ('Correo',         'DIRECTO',     'Correo electrónico a clientes identificados'),
    ('WhatsApp',       'DIRECTO',     'Mensajería directa a clientes identificados'),
    ('Llamada',        'DIRECTO',     'Llamada telefónica del ejecutivo'),
    ('Evento',         'EVENTOS',     'Ferias, demostraciones y activaciones')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO proveedores_marketing (razon_social, rfc, tipo_servicio, contacto_nombre, contacto_email, contacto_telefono)
SELECT * FROM (VALUES
    ('Agencia Creativa del Sur SA de CV', 'ACS180501KL2', 'AGENCIA'::tipo_proveedor_marketing,            'Mariana Ruiz',  'mariana@creativadelsur.mx', '961 555 0142'),
    ('Radio Chiapas FM',                  'RCF050912MN3', 'MEDIO'::tipo_proveedor_marketing,              'Carlos Peña',   'ventas@radiochiapas.fm',    '961 555 0187'),
    ('Meta Platforms Ireland Ltd',        NULL,           'PLATAFORMA_DIGITAL'::tipo_proveedor_marketing, NULL,            'ads-support@meta.com',      NULL)
) AS v(razon_social, rfc, tipo_servicio, contacto_nombre, contacto_email, contacto_telefono)
WHERE NOT EXISTS (SELECT 1 FROM proveedores_marketing p WHERE p.razon_social = v.razon_social);

DO $$
DECLARE
    v_mkt UUID; v_a INT; v_b INT; v_c INT; v_d INT;
    v_redes INT; v_radio INT; v_wa INT; v_correo INT; v_llamada INT; v_evento INT;
    v_agencia INT; v_medio INT; v_plataforma INT;
BEGIN
    IF EXISTS (SELECT 1 FROM campanas WHERE nombre = 'Lanzamiento Smartwatch Pro') THEN RETURN; END IF;
    SELECT id_usuario INTO v_mkt FROM usuarios WHERE correo = 'marketing@sigfevak.mx';
    SELECT id_canal INTO v_redes   FROM canales_marketing WHERE nombre = 'Redes sociales';
    SELECT id_canal INTO v_radio   FROM canales_marketing WHERE nombre = 'Radio';
    SELECT id_canal INTO v_wa      FROM canales_marketing WHERE nombre = 'WhatsApp';
    SELECT id_canal INTO v_correo  FROM canales_marketing WHERE nombre = 'Correo';
    SELECT id_canal INTO v_llamada FROM canales_marketing WHERE nombre = 'Llamada';
    SELECT id_canal INTO v_evento  FROM canales_marketing WHERE nombre = 'Evento';
    SELECT id_proveedor_marketing INTO v_agencia    FROM proveedores_marketing WHERE tipo_servicio = 'AGENCIA';
    SELECT id_proveedor_marketing INTO v_medio      FROM proveedores_marketing WHERE tipo_servicio = 'MEDIO';
    SELECT id_proveedor_marketing INTO v_plataforma FROM proveedores_marketing WHERE tipo_servicio = 'PLATAFORMA_DIGITAL';

    -- ---------- CASO A · EXTERNO "Lanzamiento Smartwatch Pro": presupuesto 50,000, gasto 45,000, ROI 1.9333 ----------
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, estatus, id_responsable, creado_por)
    VALUES ('Lanzamiento Smartwatch Pro', 'EXTERNO', 'Posicionar el Smartwatch Fitness Pro en el canal mayorista', DATE '2026-09-01', DATE '2026-10-15', 50000.00, 'ACTIVA', v_mkt, v_mkt)
    RETURNING id_campana INTO v_a;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_a, v_redes, v_plataforma, 'Pauta en redes',         22000.00, DATE '2026-09-02', 'PAGADO'),
        (v_a, v_redes, v_agencia,    'Producción de video',    15000.00, DATE '2026-09-03', 'PAGADO'),
        (v_a, v_radio, v_medio,      'Spot en radio regional',  8000.00, DATE '2026-09-05', 'PENDIENTE');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato)
    VALUES (v_a, NULL, DATE '2026-09-01', DATE '2026-09-12', 182400, 96000, 4120, 310, 48, 132000.00, 'Meta Ads + Manual');
    INSERT INTO campana_productos (id_campana, id_producto)
    SELECT v_a, id_producto FROM productos WHERE nombre = 'Smartwatch Fitness Pro';

    -- ---------- CASO B · DIRECTO "Promo revendedores agosto": presupuesto 15,000, 5 clientes objetivo, gasto 11,200 ----------
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, estatus, id_responsable, creado_por)
    VALUES ('Promo revendedores agosto', 'DIRECTO', 'Reactivar compras de los cinco comercializadores principales', DATE '2026-08-01', DATE '2026-08-31', 15000.00, 'PLANEADA', v_mkt, v_mkt)
    RETURNING id_campana INTO v_b;
    INSERT INTO campana_clientes (id_campana, id_cliente, id_canal, fecha_contacto, estado_contacto, notas)
    SELECT v_b, c.id_cliente, v.canal, v.fecha, v.estado::estado_contacto, v.notas
    FROM (VALUES
        ('EMA150312AB1', v_wa,      DATE '2026-08-03', 'CONVERTIDO',    'Compró tras la promoción'),
        ('TCD190405IJ5', v_llamada, DATE '2026-08-04', 'CONVERTIDO',    'Pidió cotización y facturó'),
        ('NDI160228KL6', v_wa,      DATE '2026-08-05', 'RESPONDIO',     'Interesado para octubre'),
        ('DBA120614MN7', v_correo,  DATE '2026-08-06', 'CONTACTADO',    NULL),
        ('RMX040815EF3', v_correo,  DATE '2026-08-06', 'NO_INTERESADO', 'Ya tiene proveedor')
    ) AS v(rfc, canal, fecha, estado, notas)
    JOIN clientes c ON c.rfc = v.rfc;
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_b;   -- RN-A6-15: ya tiene clientes objetivo
    INSERT INTO costos_marketing (id_campana, id_canal, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_b, v_wa,      'Mensajería masiva WhatsApp Business', 8200.00, DATE '2026-08-02', 'PAGADO'),
        (v_b, v_llamada, 'Horas de llamadas del ejecutivo',     3000.00, DATE '2026-08-10', 'PAGADO');
    INSERT INTO campana_productos (id_campana, id_producto)
    SELECT v_b, id_producto FROM productos WHERE nombre IN ('Cargador USB-C 65W GaN', 'Cable HDMI 2.1 4K 2m');

    -- ---------- Campaña EXTERNO FINALIZADA (RN-A6-13) ----------
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, estatus, id_responsable, creado_por)
    VALUES ('Expo Electrónica Sureste 2026', 'EXTERNO', 'Presencia en la feria regional de electrónica', DATE '2026-07-10', DATE '2026-07-12', 30000.00, 'FINALIZADA', v_mkt, v_mkt)
    RETURNING id_campana INTO v_c;
    -- Se carga con la campaña en PLANEADA para que el trigger de cerrada no la bloquee, y después se cierra
    UPDATE campanas SET estatus = 'PLANEADA' WHERE id_campana = v_c;
    INSERT INTO costos_marketing (id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago) VALUES
        (v_c, v_evento, NULL,      'Stand y montaje',        18500.00, DATE '2026-07-01', 'PAGADO'),
        (v_c, v_evento, v_agencia, 'Material impreso y demo', 6400.00, DATE '2026-07-05', 'PAGADO');
    INSERT INTO metricas_marketing (id_campana, id_canal, periodo_inicio, periodo_fin, impresiones, alcance, clics, leads_generados, conversiones, ingreso_atribuido, fuente_dato)
    VALUES (v_c, v_evento, DATE '2026-07-10', DATE '2026-07-12', 0, 2300, 0, 64, 9, 41000.00, 'Manual');
    INSERT INTO campana_productos (id_campana, id_producto)
    SELECT v_c, id_producto FROM productos WHERE nombre IN ('Bocina Portátil BT 20W', 'Auriculares BT TW-55');
    UPDATE campanas SET estatus = 'ACTIVA' WHERE id_campana = v_c;
    UPDATE campanas SET estatus = 'FINALIZADA' WHERE id_campana = v_c;

    -- ---------- Campaña DIRECTO PLANEADA con un cliente en estado OBJETIVO ----------
    INSERT INTO campanas (nombre, tipo_marketing, objetivo, fecha_inicio, fecha_fin, presupuesto_asignado, estatus, id_responsable, creado_por)
    VALUES ('Reactivación Pacífico', 'DIRECTO', 'Recuperar al comercializador de Baja California', DATE '2026-10-01', DATE '2026-10-31', 5000.00, 'PLANEADA', v_mkt, v_mkt)
    RETURNING id_campana INTO v_d;
    INSERT INTO campana_clientes (id_campana, id_cliente, id_canal, estado_contacto)
    SELECT v_d, id_cliente, v_correo, 'OBJETIVO' FROM clientes WHERE rfc = 'MPA090917ST0';

    -- ---------- INVESTIGACIONES: una ligada al caso A y una independiente ----------
    INSERT INTO investigaciones_mercado (titulo, tipo, id_campana, objetivo, metodologia, tamano_muestra, id_proveedor_marketing, costo, fecha_inicio, fecha_fin, estado, resumen_hallazgos, creado_por) VALUES
        ('Percepción del Smartwatch Fitness Pro en mayoristas', 'ENCUESTA', v_a, 'Medir intención de compra antes del lanzamiento', 'Encuesta en línea a compradores de 40 comercializadores', 120, v_agencia, 9500.00, DATE '2026-08-15', DATE '2026-08-29', 'FINALIZADA', 'El 62 % compraría en el primer trimestre si el precio queda por debajo de 3,500', v_mkt),
        ('Benchmark de precios de accesorios 2026',              'BENCHMARKING_COMPETENCIA', NULL, 'Comparar precios de cables y cargadores contra tres competidores', 'Levantamiento de precios en tiendas en línea', NULL, NULL, 0, DATE '2026-09-08', NULL, 'EN_CURSO', NULL, v_mkt);
END $$;
