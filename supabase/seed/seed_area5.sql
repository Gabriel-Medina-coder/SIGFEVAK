-- Área 5 · Issue #96 · RN-A5-12, RN-A5-19, RN-A5-20
-- Qué hace: 8 instituciones, 11 tipos de obligación, parámetros fiscales con vigencia, obligaciones de julio a
-- octubre 2026 en distintos estados (la de IVA de julio recorre los 9 estados con los números del ejemplo 10.1,
-- una vencida), 2 importaciones (la primera reproduce el ejemplo 10.2), 4 licencias, alertas generadas.
-- Referencia a los usuarios de prueba por correo (los crea la coordinación en Supabase Auth). Idempotente.

-- ---------- INSTITUCIONES (sección 2.2) ----------
INSERT INTO instituciones (nombre, siglas, ambito, entidad, portal_url) VALUES
    ('Servicio de Administración Tributaria',              'SAT',              'FEDERAL',   NULL,      'https://www.sat.gob.mx'),
    ('Agencia Nacional de Aduanas de México',              'ANAM',             'FEDERAL',   NULL,      'https://anam.gob.mx'),
    ('Ventanilla Única de Comercio Exterior Mexicana',     'VUCEM',            'FEDERAL',   NULL,      'https://www.ventanillaunica.gob.mx'),
    ('Secretaría de Hacienda del Estado de Chiapas',       'Hacienda Chiapas', 'ESTATAL',   'Chiapas', 'https://www.haciendachiapas.gob.mx'),
    ('Protección Civil del Estado de Chiapas',             'PC Chiapas',       'ESTATAL',   'Chiapas', NULL),
    ('Ayuntamiento de Tuxtla Gutiérrez',                   'Ayuntamiento',     'MUNICIPAL', 'Chiapas', NULL),
    ('Secretaría de Economía',                             'SE',               'FEDERAL',   NULL,      'https://www.gob.mx/se'),
    ('Sistema de Información Empresarial Mexicano',        'SIEM',             'FEDERAL',   NULL,      'https://www.siem.gob.mx')
ON CONFLICT (nombre) DO NOTHING;

-- ---------- TIPOS DE OBLIGACIÓN (sección 2.6) ----------
INSERT INTO tipos_obligacion (id_institucion, clave, nombre, frecuencia, dias_vencimiento, critica, descripcion)
SELECT i.id_institucion, v.clave, v.nombre, v.frecuencia::frecuencia_obligacion, v.dia, v.critica, v.descripcion
FROM (VALUES
    ('SAT',              'ISR_PROV',            'Pago provisional de ISR',              'MENSUAL',        17,   TRUE,  'Día 17 del mes siguiente'),
    ('SAT',              'IVA_MENSUAL',         'IVA mensual',                          'MENSUAL',        17,   TRUE,  'Día 17 del mes siguiente'),
    ('Hacienda Chiapas', 'ISN_CHIAPAS',         'Impuesto Sobre Nóminas de Chiapas',    'BIMESTRAL',      17,   TRUE,  'Día 17 del mes siguiente al bimestre'),
    ('SAT',              'ISR_ANUAL',           'Declaración anual de ISR',             'ANUAL',          31,   TRUE,  '31 de marzo'),
    ('SIEM',             'SIEM',                'Registro anual SIEM',                  'SEGUN_VIGENCIA', NULL, FALSE, 'Según fecha de alta'),
    ('ANAM',             'PEDIMENTO',           'Pedimento de importación',             'POR_OPERACION',  NULL, TRUE,  'Al despacho aduanal'),
    ('VUCEM',            'E2',                  'Manifestación de Valor E2',            'POR_OPERACION',  NULL, FALSE, 'Antes del despacho cuando aplique'),
    ('Ayuntamiento',     'USO_SUELO',           'Licencia de uso de suelo',             'SEGUN_VIGENCIA', NULL, FALSE, 'Según licencia'),
    ('Ayuntamiento',     'LIC_FUNCIONAMIENTO',  'Licencia de funcionamiento',           'SEGUN_VIGENCIA', NULL, FALSE, 'Renovación anual típica'),
    ('PC Chiapas',       'PROTECCION_CIVIL',    'Programa Interno de Protección Civil', 'SEGUN_VIGENCIA', NULL, FALSE, 'Según dictamen'),
    ('SE',               'PADRON_IMPORTADORES', 'Padrón de Importadores',               'SEGUN_VIGENCIA', NULL, FALSE, 'Vigencia mientras no se suspenda')
) AS v(siglas, clave, nombre, frecuencia, dia, critica, descripcion)
JOIN instituciones i ON i.siglas = v.siglas
ON CONFLICT (clave) DO NOTHING;

-- ---------- PARÁMETROS FISCALES (sección 2.5; RN-A5-20) ----------
INSERT INTO parametros_fiscales (clave, entidad, fraccion, valor, vigencia_inicio, fuente)
SELECT v.clave, v.entidad, v.fraccion, v.valor, DATE '2026-01-01', v.fuente FROM (VALUES
    ('TASA_ISR_PM',          NULL,      NULL,         0.300000, 'LISR art. 9'),
    ('TASA_IVA',             NULL,      NULL,         0.160000, 'LIVA art. 1'),
    ('TASA_ISN',             'Chiapas', NULL,         0.020000, 'Ley de Hacienda del Estado de Chiapas'),
    ('TASA_DTA',             NULL,      NULL,         0.008000, 'LFD art. 49: 8 al millar, regla general'),
    ('COEFICIENTE_UTILIDAD', NULL,      NULL,         0.085000, 'Coeficiente de utilidad del ejercicio anterior; lo confirma contabilidad'),
    ('RECARGO_MENSUAL',      NULL,      NULL,         0.014700, 'CFF art. 21; tasa de recargos por mora 1.47 % mensual'),
    ('TASA_IGI',             NULL,      '8471.30.01', 0.150000, 'Tabletas; tasa del ejemplo 10.2, confirmar en la TIGIE (pregunta abierta 9)'),
    ('TASA_IGI',             NULL,      '8517.62.15', 0.150000, 'Relojes inteligentes y routers; confirmar en la TIGIE (pregunta abierta 9)'),
    ('TASA_IGI',             NULL,      '8518.30.99', 0.150000, 'Auriculares; confirmar en la TIGIE (pregunta abierta 9)'),
    ('TASA_IGI',             NULL,      '8518.22.01', 0.150000, 'Bocinas; confirmar en la TIGIE (pregunta abierta 9)'),
    ('TASA_IGI',             NULL,      '8525.89.99', 0.150000, 'Cámaras IP; confirmar en la TIGIE (pregunta abierta 9)')
) AS v(clave, entidad, fraccion, valor, fuente)
WHERE NOT EXISTS (SELECT 1 FROM parametros_fiscales p WHERE p.clave = v.clave AND p.entidad IS NOT DISTINCT FROM v.entidad AND p.fraccion IS NOT DISTINCT FROM v.fraccion);

-- ---------- OBLIGACIONES PERIÓDICAS de julio a octubre (el ISN del bimestre sep-oct toma la base del área 4) ----------
SELECT fn_generar_obligaciones_periodo('2026-07');
SELECT fn_generar_obligaciones_periodo('2026-08');
SELECT fn_generar_obligaciones_periodo('2026-09');
SELECT fn_generar_obligaciones_periodo('2026-10');

-- ---------- EJEMPLO 10.1: IVA de julio recorre los 9 estados con 110,000 = 320,000 trasladado − 210,000 acreditable ----------
DO $$
DECLARE v_obl INT; v_contador UUID; v_autorizador UUID; v_pago INT;
BEGIN
    SELECT o.id_obligacion INTO v_obl FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion)
     WHERE t.clave = 'IVA_MENSUAL' AND o.periodo = '2026-07';
    IF (SELECT estado FROM obligaciones WHERE id_obligacion = v_obl) <> 'PENDIENTE' THEN RETURN; END IF;
    SELECT id_usuario INTO v_contador    FROM usuarios WHERE correo = 'contador@sigfevak.mx';
    SELECT id_usuario INTO v_autorizador FROM usuarios WHERE correo = 'autorizador@sigfevak.mx';

    UPDATE obligaciones SET monto_estimado = 110000.00, id_responsable = v_contador, estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    INSERT INTO declaraciones (id_obligacion, tipo_declaracion, numero_operacion, folio, linea_captura, fecha_presentacion, importe_declarado, fecha_limite_pago)
    VALUES (v_obl, 'Definitiva', '260812345678', 'ACUSE-2607-IVA', '0026 0812 3456 7890 12', DATE '2026-08-12', 110000.00, DATE '2026-08-17');
    INSERT INTO documentos_fiscales (id_obligacion, tipo_documento, nombre, referencia, fecha)
    VALUES (v_obl, 'ACUSE_SAT', 'Acuse IVA julio 2026', 'docs/acuses/2026-07-iva.pdf', DATE '2026-08-12');
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = v_autorizador WHERE id_obligacion = v_obl;
    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, banco, referencia, linea_captura, metodo_pago, id_registrado_por, id_autorizado_por)
    VALUES (v_obl, DATE '2026-08-16', 110000.00, 'BBVA', 'SPEI-20260816-778812', '0026 0812 3456 7890 12', 'SPEI', v_contador, v_autorizador)
    RETURNING id_pago INTO v_pago;
    INSERT INTO documentos_fiscales (id_obligacion, id_pago, tipo_documento, nombre, referencia, fecha)
    VALUES (v_obl, v_pago, 'COMPROBANTE_BANCARIO', 'Comprobante SPEI IVA julio 2026', 'docs/comprobantes/2026-08-16-iva.pdf', DATE '2026-08-16');
    UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'CERRADO', fecha_cierre = DATE '2026-08-17' WHERE id_obligacion = v_obl;
END $$;

-- ISR provisional de julio queda sin atender: fn_marcar_vencidas la pasa a VENCIDO (RN-A5-16)
-- Agosto: IVA en LINEA_GENERADA e ISR en CALCULADO
DO $$
DECLARE v_iva INT; v_isr INT; v_contador UUID;
BEGIN
    SELECT id_usuario INTO v_contador FROM usuarios WHERE correo = 'contador@sigfevak.mx';
    SELECT o.id_obligacion INTO v_iva FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion) WHERE t.clave = 'IVA_MENSUAL' AND o.periodo = '2026-08';
    SELECT o.id_obligacion INTO v_isr FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion) WHERE t.clave = 'ISR_PROV' AND o.periodo = '2026-08';
    IF (SELECT estado FROM obligaciones WHERE id_obligacion = v_iva) = 'PENDIENTE' THEN
        UPDATE obligaciones SET monto_estimado = 143584.00 - 98000.00, id_responsable = v_contador, estado = 'CALCULADO' WHERE id_obligacion = v_iva;
        INSERT INTO declaraciones (id_obligacion, tipo_declaracion, numero_operacion, folio, linea_captura, fecha_presentacion, importe_declarado, fecha_limite_pago)
        VALUES (v_iva, 'Definitiva', '260912345679', 'ACUSE-2608-IVA', '0026 0912 3456 7890 13', DATE '2026-09-11', 45584.00, DATE '2026-09-17');
        UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_iva;
        UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_iva;
    END IF;
    IF (SELECT estado FROM obligaciones WHERE id_obligacion = v_isr) = 'PENDIENTE' THEN
        UPDATE obligaciones SET monto_estimado = ROUND(897400.00 * fn_parametro_fiscal('COEFICIENTE_UTILIDAD', NULL, NULL, DATE '2026-09-17') * fn_parametro_fiscal('TASA_ISR_PM', NULL, NULL, DATE '2026-09-17'), 2),
               id_responsable = v_contador, estado = 'CALCULADO' WHERE id_obligacion = v_isr;
    END IF;
END $$;

-- ---------- IMPORTACIONES ----------
-- Ejemplo 10.2: 200 tabletas a 2,500 con fracción 8471.30.01 al 15 % → IGI 75,000, DTA 4,000, IVA 92,640, total 171,640
DO $$
DECLARE v_obl INT; v_imp INT; v_tipo INT; v_admin UUID; v_prod INT;
BEGIN
    IF EXISTS (SELECT 1 FROM importaciones WHERE numero_pedimento = '26 47 3891 6004520') THEN RETURN; END IF;
    SELECT id_tipo_obligacion INTO v_tipo FROM tipos_obligacion WHERE clave = 'PEDIMENTO';
    SELECT id_usuario INTO v_admin FROM usuarios WHERE correo = 'admin@sigfevak.mx';
    SELECT id_producto INTO v_prod FROM productos WHERE nombre = 'Tableta Android 10" OEM';

    INSERT INTO obligaciones (id_tipo_obligacion, fecha_vencimiento, id_responsable, entidad)
    VALUES (v_tipo, DATE '2026-08-01', v_admin, NULL) RETURNING id_obligacion INTO v_obl;
    INSERT INTO importaciones (id_obligacion, numero_pedimento, aduana, agente_aduanal, pais_origen, pais_procedencia, fecha_importacion, valor_aduanero, numero_e2, padron_importador, encargo_conferido)
    VALUES (v_obl, '26 47 3891 6004520', 'Manzanillo', 'Agencia Aduanal del Pacífico', 'China', 'China', DATE '2026-08-01', 500000.00, 'E2-2026-0141', 'PI-2024-08812', 'EC-2026-0031')
    RETURNING id_importacion INTO v_imp;
    INSERT INTO productos_importados (id_importacion, id_producto, nombre, marca, modelo, cantidad, valor_unitario, fraccion_arancelaria, nico, nom_aplicable)
    VALUES (v_imp, v_prod, 'Tableta Android 10" OEM', 'Genérica', 'A10-2026', 200, 2500.00, '8471.30.01', '00', 'NOM-019-SCFI');
    -- El monto quedó calculado por los triggers; el pedimento se paga al despacho y se concilia
    UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    INSERT INTO documentos_fiscales (id_obligacion, tipo_documento, nombre, referencia, fecha)
    VALUES (v_obl, 'PEDIMENTO', 'Pedimento 26 47 3891 6004520', 'docs/pedimentos/2026-08-01.pdf', DATE '2026-08-01'),
           (v_obl, 'MANIFESTACION_E2', 'Manifestación de valor E2-2026-0141', 'docs/vucem/e2-2026-0141.pdf', DATE '2026-07-30');
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = (SELECT id_usuario FROM usuarios WHERE correo = 'autorizador@sigfevak.mx') WHERE id_obligacion = v_obl;
    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, banco, referencia, metodo_pago, id_registrado_por, id_autorizado_por)
    VALUES (v_obl, DATE '2026-08-01', 171640.00, 'BBVA', 'SPEI-20260801-441120', 'SPEI', v_admin, (SELECT id_usuario FROM usuarios WHERE correo = 'autorizador@sigfevak.mx'));
    INSERT INTO documentos_fiscales (id_obligacion, id_pago, tipo_documento, nombre, referencia, fecha)
    SELECT v_obl, id_pago, 'COMPROBANTE_BANCARIO', 'Comprobante pedimento 26 47 3891 6004520', 'docs/comprobantes/2026-08-01-pedimento.pdf', DATE '2026-08-01'
      FROM pagos_obligacion WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'CONCILIADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'CERRADO', fecha_cierre = DATE '2026-08-01' WHERE id_obligacion = v_obl;
END $$;

-- Segunda importación: la entrada SZ-2026-0917 del área 1 (50 cámaras) más dos productos, 3 en total
DO $$
DECLARE v_obl INT; v_imp INT; v_tipo INT; v_admin UUID; v_entrada INT;
BEGIN
    IF EXISTS (SELECT 1 FROM importaciones WHERE numero_pedimento = '26 47 3891 6004521') THEN RETURN; END IF;
    SELECT id_tipo_obligacion INTO v_tipo FROM tipos_obligacion WHERE clave = 'PEDIMENTO';
    SELECT id_usuario INTO v_admin FROM usuarios WHERE correo = 'admin@sigfevak.mx';
    SELECT id_entrada INTO v_entrada FROM entradas_producto WHERE numero_factura_proveedor = 'SZ-2026-0917';

    INSERT INTO obligaciones (id_tipo_obligacion, fecha_vencimiento, id_responsable)
    VALUES (v_tipo, DATE '2026-09-08', v_admin) RETURNING id_obligacion INTO v_obl;
    INSERT INTO importaciones (id_obligacion, id_entrada, numero_pedimento, aduana, agente_aduanal, pais_origen, pais_procedencia, fecha_importacion, valor_aduanero, padron_importador, encargo_conferido)
    VALUES (v_obl, v_entrada, '26 47 3891 6004521', 'Manzanillo', 'Agencia Aduanal del Pacífico', 'China', 'China', DATE '2026-09-08', 37000.00 + 66600.00 + 29600.00, 'PI-2024-08812', 'EC-2026-0031')
    RETURNING id_importacion INTO v_imp;
    INSERT INTO productos_importados (id_importacion, id_producto, nombre, marca, modelo, cantidad, valor_unitario, fraccion_arancelaria, nico)
    SELECT v_imp, p.id_producto, v.nombre, v.marca, v.modelo, v.cantidad, v.valor, v.fraccion, '00'
    FROM (VALUES
        ('Cámara IP WiFi 1080p',   'VigiaMX', 'IP-1080', 50,  740.00, '8525.89.99'),
        ('Smartwatch Fitness Pro', 'Genérica', 'SW-26',  30, 2220.00, '8517.62.15'),
        ('Auriculares BT TW-55',   'Genérica', 'TW-55',  100, 296.00, '8518.30.99')
    ) AS v(nombre, marca, modelo, cantidad, valor, fraccion)
    LEFT JOIN productos p ON p.nombre = v.nombre;
    -- Pagado al despacho; la conciliación queda pendiente para la demostración
    UPDATE obligaciones SET estado = 'CALCULADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'PRESENTADO' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'LINEA_GENERADA' WHERE id_obligacion = v_obl;
    UPDATE obligaciones SET estado = 'AUTORIZADO', id_autorizador = (SELECT id_usuario FROM usuarios WHERE correo = 'autorizador@sigfevak.mx') WHERE id_obligacion = v_obl;
    INSERT INTO pagos_obligacion (id_obligacion, fecha_pago, monto, banco, referencia, metodo_pago, id_registrado_por, id_autorizado_por)
    SELECT v_obl, DATE '2026-09-08', total_contribuciones, 'BBVA', 'SPEI-20260908-512230', 'SPEI', v_admin, (SELECT id_usuario FROM usuarios WHERE correo = 'autorizador@sigfevak.mx')
      FROM importaciones WHERE id_importacion = v_imp;
    UPDATE obligaciones SET estado = 'PAGADO' WHERE id_obligacion = v_obl;
END $$;

-- ---------- LICENCIAS (municipio sede: Tuxtla Gutiérrez, pregunta abierta 1) ----------
INSERT INTO licencias_permisos (tipo_licencia, autoridad_emisora, municipio, numero_licencia, fecha_emision, fecha_vencimiento, costo, estado)
SELECT v.tipo, v.autoridad, v.municipio, v.numero, v.emision, v.vencimiento, v.costo, v.estado::estado_licencia FROM (VALUES
    ('USO_SUELO',               'Ayuntamiento de Tuxtla Gutiérrez',        'Tuxtla Gutiérrez', 'US-2025-04471',  DATE '2025-10-01', DATE '2026-09-30', 4800.00,  'VIGENTE'),
    ('LICENCIA_FUNCIONAMIENTO', 'Ayuntamiento de Tuxtla Gutiérrez',        'Tuxtla Gutiérrez', 'LF-2026-01188',  DATE '2026-01-15', DATE '2027-01-14', 6500.00,  'VIGENTE'),
    ('PROTECCION_CIVIL',        'Protección Civil del Estado de Chiapas',  'Tuxtla Gutiérrez', 'PIPC-2025-0932', DATE '2025-08-20', DATE '2026-08-19', 12000.00, 'VIGENTE'),
    ('SIEM',                    'Sistema de Información Empresarial Mexicano', NULL,           'SIEM-2026-77120', DATE '2026-03-10', DATE '2027-03-09', 670.00,  'VIGENTE')
) AS v(tipo, autoridad, municipio, numero, emision, vencimiento, costo, estado)
WHERE NOT EXISTS (SELECT 1 FROM licencias_permisos l WHERE l.numero_licencia = v.numero);

-- ---------- FUNCIONES DIARIAS ----------
SELECT fn_marcar_vencidas();
SELECT fn_generar_alertas();
SELECT fn_actualizar_estado_licencias();
