-- Área 4 · Issue #66 · RN-A4-02, RN-A4-03, RN-A4-14
-- Qué hace: parámetros legales con vigencia (sección 2.2), catálogo de 5 bonos (sección 2.3), esquema 2026 con
-- 4 tramos, 3 zonas (una ZLFN), datos laborales de los 5 agentes del seed base, metas de 2026-09 y el periodo
-- mensual 2026-09 calculado, revisado y autorizado para que el ejemplo de la sección 10 quede reproducido.
-- Idempotente.

-- ---------- PARÁMETROS LEGALES (sección 2.2; los valores viven aquí, no en código) ----------
INSERT INTO parametros_legales (clave, entidad, valor, tabla, vigencia_inicio, fuente)
SELECT v.clave, v.entidad, v.valor, v.tabla::JSONB, v.vigencia, v.fuente FROM (VALUES
    ('SM_GENERAL',        NULL,      315.0400, NULL, DATE '2026-01-01', 'CONASAMI 2026'),
    ('SM_ZLFN',           NULL,      440.8700, NULL, DATE '2026-01-01', 'CONASAMI 2026'),
    ('UMA_DIARIA',        NULL,      117.3100, NULL, DATE '2026-02-01', 'INEGI 2026'),
    ('UMA_MENSUAL',       NULL,     3566.2200, NULL, DATE '2026-02-01', 'INEGI 2026'),
    ('FACTOR_DIAS_MES',   NULL,       30.4000, NULL, DATE '2026-01-01', 'Convención interna (365/12)'),
    ('TOPE_DESCUENTO_110', NULL,       0.3000, NULL, DATE '2026-01-01', 'LFT art. 110 fracc. I: 30 % del excedente del salario mínimo'),
    ('CUOTA_IMSS_OBRERO', NULL,        0.0238, NULL, DATE '2026-01-01', 'LSS: ramos obreros 0.25 + 0.375 + 0.625 + 1.125 = 2.375 %, redondeado a 4 decimales; falta el ramo excedente de 3 UMA'),
    ('TOPE_EXENTO_PUNTUALIDAD_UMAS', NULL, 1.0000, NULL, DATE '2026-01-01', 'Tope exento del premio de puntualidad en UMAs mensuales; por confirmar (pregunta abierta 9)'),
    ('ISN',               'Chiapas',   0.0200, NULL, DATE '2026-01-01', 'Ley de Hacienda del Estado de Chiapas, según el área 5 (I-03)'),
    ('TARIFA_ISR_MENSUAL', NULL, NULL,
     '[{"li":0.01,"ls":746.04,"cuota":0.00,"pct":0.0192},
       {"li":746.05,"ls":6332.05,"cuota":14.32,"pct":0.0640},
       {"li":6332.06,"ls":11128.01,"cuota":371.83,"pct":0.1088},
       {"li":11128.02,"ls":12935.82,"cuota":893.63,"pct":0.1600},
       {"li":12935.83,"ls":15487.71,"cuota":1182.88,"pct":0.1792},
       {"li":15487.72,"ls":31236.49,"cuota":1640.18,"pct":0.2136},
       {"li":31236.50,"ls":49233.00,"cuota":5004.12,"pct":0.2352},
       {"li":49233.01,"ls":93993.90,"cuota":9236.89,"pct":0.3000},
       {"li":93993.91,"ls":125325.20,"cuota":22665.17,"pct":0.3200},
       {"li":125325.21,"ls":375975.61,"cuota":32691.18,"pct":0.3400},
       {"li":375975.62,"ls":null,"cuota":117912.24,"pct":0.3500}]',
     DATE '2026-01-01', 'Tarifa mensual art. 96 LISR, Anexo 8 RMF; confirmar contra el Anexo 8 de 2026 (pregunta abierta 5)')
) AS v(clave, entidad, valor, tabla, vigencia, fuente)
WHERE NOT EXISTS (SELECT 1 FROM parametros_legales p WHERE p.clave = v.clave AND p.entidad IS NOT DISTINCT FROM v.entidad);

-- ---------- CATÁLOGO DE BONOS (sección 2.3) ----------
INSERT INTO bonos_catalogo (clave, nombre, condicion, monto, porcentaje, integra_sbc, gravado_isr, clave_sat) VALUES
    ('META',          'Bono de cumplimiento de meta', 'Cumplimiento del mes de 100 % o más',                          2500.00, NULL,   TRUE,  TRUE, '038'),
    ('CLIENTE_NUEVO', 'Bono por cliente nuevo',       'Por cada cliente con su primera compra pagada en el mes',        500.00, NULL,   TRUE,  TRUE, '038'),
    ('COBRANZA_SANA', 'Bono de cobranza sana',        'Cartera vencida del agente menor al 5 %',                       1000.00, NULL,   TRUE,  TRUE, '038'),
    ('PUNTUALIDAD',   'Premio de puntualidad',        'Cero retardos en el periodo; 10 % del sueldo del mes',            NULL,   0.1000, FALSE, TRUE, '010'),
    ('TRIMESTRAL',    'Bono trimestral',              'Promedio de cumplimiento del trimestre de 110 % o más',         6000.00, NULL,   TRUE,  TRUE, '038')
ON CONFLICT (clave) DO NOTHING;

-- ---------- ESQUEMA 2026 CON 4 TRAMOS ----------
INSERT INTO esquemas_compensacion (nombre, periodicidad, vigencia_inicio)
SELECT 'Esquema 2026 general', 'MENSUAL', DATE '2026-01-01'
WHERE NOT EXISTS (SELECT 1 FROM esquemas_compensacion WHERE nombre = 'Esquema 2026 general');

INSERT INTO tramos_comision (id_esquema, pct_min, pct_max, tasa)
SELECT e.id_esquema, v.pmin, v.pmax, v.tasa
FROM esquemas_compensacion e, (VALUES (0, 70, 0.0100), (70, 100, 0.0200), (100, 120, 0.0300), (120, NULL, 0.0350)) AS v(pmin, pmax, tasa)
WHERE e.nombre = 'Esquema 2026 general' AND NOT EXISTS (SELECT 1 FROM tramos_comision t WHERE t.id_esquema = e.id_esquema);

-- ---------- ZONAS ----------
INSERT INTO zonas (nombre, region, zona_salarial, entidad) VALUES
    ('Centro',          'Centro',   'GENERAL', 'Ciudad de México'),
    ('Sureste',         'Sur',      'GENERAL', 'Chiapas'),
    ('Frontera Norte',  'Norte',    'ZLFN',    'Baja California')
ON CONFLICT (nombre) DO NOTHING;

-- ---------- AGENTES: datos laborales sobre el seed base (I-12: un solo seed de agentes) ----------
UPDATE agentes_ventas a
   SET rfc = v.rfc, curp = v.curp, nss = v.nss, fecha_ingreso = v.ingreso, id_zona = z.id_zona, id_esquema = e.id_esquema,
       salario_diario = v.salario, entidad_federativa = z.entidad, clabe = v.clabe
FROM (VALUES
    ('Jorge Mendoza',     'MEGJ850214HD1', 'MEGJ850214HCSNRR03', '12138512345', DATE '2022-03-01', 'Sureste',        350.00, '012180001234567891'),
    ('Patricia Leal',     'LEAP900530MN2', 'LEAP900530MDFLXT08', '43159012345', DATE '2023-01-16', 'Centro',         350.00, '012180001234567892'),
    ('Andrés Fuentes',    'FUEA880812KL3', 'FUEA880812HGTNNN01', '65168812345', DATE '2021-08-01', 'Centro',         360.00, '012180001234567893'),
    ('Verónica Castillo', 'CAVV921105PQ4', 'CAVV921105MCSSLR05', '87179212345', DATE '2024-05-02', 'Sureste',        350.00, '012180001234567894'),
    ('Miguel Torres',     'TOMM870920RS5', 'TOMM870920HBCRGG02', '09188712345', DATE '2020-11-15', 'Frontera Norte', 440.87, '012180001234567895')
) AS v(nombre, rfc, curp, nss, ingreso, zona, salario, clabe)
JOIN zonas z ON z.nombre = v.zona
JOIN esquemas_compensacion e ON e.nombre = 'Esquema 2026 general'
WHERE a.nombre = v.nombre AND a.rfc IS NULL;

-- ---------- METAS 2026-09 (RN-A4-03: antes del cálculo) ----------
INSERT INTO metas (id_agente, periodo, monto_meta, sin_retardos)
SELECT a.id_agente, '2026-09', v.meta, v.puntual
FROM (VALUES
    ('Jorge Mendoza', 500000.00, TRUE), ('Patricia Leal', 300000.00, TRUE), ('Andrés Fuentes', 250000.00, FALSE),
    ('Verónica Castillo', 200000.00, TRUE), ('Miguel Torres', 150000.00, TRUE)
) AS v(nombre, meta, puntual)
JOIN agentes_ventas a ON a.nombre = v.nombre
ON CONFLICT (id_agente, periodo) DO NOTHING;

-- ---------- PERIODO MENSUAL 2026-09: calculado, revisado y autorizado (separación de funciones, RN-A4-15) ----------
DO $$
DECLARE v_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM periodos_nomina WHERE tipo = 'MENSUAL' AND fecha_inicio = DATE '2026-09-01') THEN RETURN; END IF;
    INSERT INTO periodos_nomina (tipo, fecha_inicio, fecha_fin) VALUES ('MENSUAL', DATE '2026-09-01', DATE '2026-09-30')
    RETURNING id_periodo INTO v_id;
    PERFORM fn_calcular_periodo(v_id, 'admin@sigfevak.mx');
    UPDATE periodos_nomina SET estatus = 'REVISADO', revisado_por = 'gerente@sigfevak.mx' WHERE id_periodo = v_id;
    PERFORM fn_calcular_nomina(v_id);
    UPDATE periodos_nomina SET estatus = 'AUTORIZADO', autorizado_por = 'autorizador@sigfevak.mx' WHERE id_periodo = v_id;
END $$;
