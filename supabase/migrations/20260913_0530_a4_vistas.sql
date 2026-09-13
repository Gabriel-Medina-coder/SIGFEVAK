-- Área 4 · Issues #69, #70, #71 · RN-A4-06, RN-A4-07, RN-A4-10, RN-A4-11, RN-A4-16
-- Qué hace: vistas sobre facturas del área 2 (v_ventas_cobradas_agente, v_clientes_nuevos_agente,
-- v_cumplimiento_meta), vistas de nómina (v_recibo_nomina, v_nomina_totales, v_sbc_bimestral) y vistas de
-- contrato v_retenciones_area5 (I-03) y v_desempeno_agente_zona (I-05).

-- Base de comisiones: facturas cobradas por agente y mes de cobro (RN-A4-06, RN-A4-07). fecha_cobro la puso el área 2 (I-02).
CREATE OR REPLACE VIEW v_ventas_cobradas_agente AS
SELECT f.id_agente,
       TO_CHAR(COALESCE(f.fecha_cobro, f.fecha), 'YYYY-MM') AS periodo,
       f.id_factura, f.id_cliente, f.fecha, f.fecha_cobro,
       f.subtotal
FROM facturas f
WHERE f.estado_pago = 'PAGADO';

-- Clientes nuevos: primera factura pagada de cada cliente con ese agente
CREATE OR REPLACE VIEW v_clientes_nuevos_agente AS
SELECT id_agente, id_cliente, MIN(periodo) AS periodo_alta
FROM v_ventas_cobradas_agente
GROUP BY id_agente, id_cliente;

-- Cumplimiento del mes contra la meta (RN-A4-03, RN-A4-06)
CREATE OR REPLACE VIEW v_cumplimiento_meta AS
SELECT m.id_agente, m.periodo, m.monto_meta,
       COALESCE(SUM(v.subtotal), 0) AS ventas_cobradas,
       ROUND(COALESCE(SUM(v.subtotal), 0) / m.monto_meta * 100, 2) AS pct_cumplimiento
FROM metas m LEFT JOIN v_ventas_cobradas_agente v USING (id_agente, periodo)
GROUP BY m.id_agente, m.periodo, m.monto_meta;

-- Recibo por agente y periodo con claves SAT
CREATE OR REPLACE VIEW v_recibo_nomina AS
SELECT p.id_periodo, p.tipo, p.fecha_inicio, p.fecha_fin, p.estatus, a.id_agente, a.nombre, a.rfc, a.clabe,
       d.id_detalle, d.concepto, d.tipo AS tipo_concepto, d.clave_sat, d.monto, d.gravado, d.exento, d.integra_sbc
FROM nomina_detalle d JOIN periodos_nomina p USING (id_periodo) JOIN agentes_ventas a USING (id_agente)
ORDER BY p.id_periodo, a.id_agente, d.tipo, d.id_detalle;

-- Totales del periodo por agente (base del layout de dispersión)
CREATE OR REPLACE VIEW v_nomina_totales AS
SELECT d.id_periodo, d.id_agente, a.nombre, a.clabe,
       SUM(CASE WHEN d.tipo = 'PERCEPCION' THEN d.monto ELSE 0 END) AS percepciones,
       SUM(CASE WHEN d.tipo = 'DEDUCCION'  THEN d.monto ELSE 0 END) AS deducciones,
       SUM(CASE WHEN d.tipo = 'PERCEPCION' THEN d.monto ELSE -d.monto END) AS neto
FROM nomina_detalle d JOIN agentes_ventas a USING (id_agente)
GROUP BY d.id_periodo, d.id_agente, a.nombre, a.clabe;

-- SBC bimestral para IMSS (RN-A4-11): la parte variable se promedia por bimestre
CREATE OR REPLACE VIEW v_sbc_bimestral AS
SELECT a.id_agente, DATE_TRUNC('month', p.fecha_fin)::DATE AS mes,
       a.salario_diario AS fijo_diario,
       ROUND(SUM(CASE WHEN d.integra_sbc AND d.concepto <> 'SUELDO' THEN d.monto ELSE 0 END) / 60.8, 2) AS variable_diario_bimestre
FROM nomina_detalle d JOIN periodos_nomina p USING (id_periodo) JOIN agentes_ventas a USING (id_agente)
WHERE d.tipo = 'PERCEPCION'
GROUP BY a.id_agente, mes, a.salario_diario;

-- CONTRATO CON EL ÁREA 5 (I-03): retenciones y base de ISN por entidad y periodo; el ISN usa la tasa de la entidad del agente (RN-A4-16)
CREATE OR REPLACE VIEW v_retenciones_area5 AS
SELECT p.id_periodo, p.fecha_fin, a.entidad_federativa,
       SUM(CASE WHEN d.concepto = 'ISR'         THEN d.monto ELSE 0 END) AS isr_retenido,
       SUM(CASE WHEN d.concepto = 'IMSS_OBRERO' THEN d.monto ELSE 0 END) AS imss_obrero,
       SUM(CASE WHEN d.tipo = 'PERCEPCION' AND d.integra_sbc THEN d.monto ELSE 0 END) AS base_isn,
       ROUND(SUM(CASE WHEN d.tipo = 'PERCEPCION' AND d.integra_sbc THEN d.monto ELSE 0 END)
             * COALESCE(fn_parametro('ISN', a.entidad_federativa, p.fecha_fin), 0), 2) AS isn_estimado
FROM nomina_detalle d JOIN periodos_nomina p USING (id_periodo) JOIN agentes_ventas a USING (id_agente)
WHERE p.estatus IN ('AUTORIZADO', 'PAGADO', 'CERRADO')
GROUP BY p.id_periodo, p.fecha_fin, a.entidad_federativa;

-- CONTRATO CON EL ÁREA 6 (I-05): desempeño por agente y zona para dirigir campañas
CREATE OR REPLACE VIEW v_desempeno_agente_zona AS
SELECT z.nombre AS zona, z.region, a.id_agente, a.nombre, c.periodo, c.monto_meta, c.pct_cumplimiento, c.ventas_cobradas
FROM v_cumplimiento_meta c JOIN agentes_ventas a USING (id_agente) LEFT JOIN zonas z USING (id_zona);
