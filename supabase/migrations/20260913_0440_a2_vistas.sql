-- Área 2 · Issues #49, #50 · RN-A2-09, RN-A2-10
-- Qué hace: vistas del equipo (v_clientes_resumen, v_facturas_pendientes, v_ventas_agente) y vistas de
-- contrato: v_cartera_agente (área 4, I-02), v_iva_trasladado_periodo (área 5, I-07), v_clientes_activos
-- (área 6, I-10). v_salidas_area2 la definió el área 3 y no cambia.

-- Resumen por comercializador: cuántos hay, cuánto han comprado, cuánto deben.
CREATE OR REPLACE VIEW v_clientes_resumen AS
SELECT c.id_cliente, c.numero_comercializador, c.nombre_empresa, c.rfc, c.estado, c.activo, c.dias_credito,
       COUNT(DISTINCT f.id_factura) FILTER (WHERE f.estado_pago <> 'CANCELADO')                        AS numero_facturas,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago <> 'CANCELADO'), 0)                     AS monto_total_facturado,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')), 0)         AS monto_pendiente,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')
                                             AND f.fecha_vencimiento < CURRENT_DATE), 0)              AS monto_vencido
FROM clientes c
LEFT JOIN facturas f USING (id_cliente)
GROUP BY c.id_cliente, c.numero_comercializador, c.nombre_empresa, c.rfc, c.estado, c.activo, c.dias_credito
ORDER BY monto_total_facturado DESC;

-- Facturas con cobro pendiente, para el módulo de seguimiento.
CREATE OR REPLACE VIEW v_facturas_pendientes AS
SELECT f.id_factura, f.folio, c.numero_comercializador, c.nombre_empresa, a.nombre AS agente,
       f.fecha, f.fecha_vencimiento,
       GREATEST(CURRENT_DATE - f.fecha_vencimiento, 0)                                                  AS dias_vencidos,
       f.subtotal, f.iva, f.valor_total, f.estado_pago
FROM facturas f
JOIN clientes c USING (id_cliente)
JOIN agentes_ventas a USING (id_agente)
WHERE f.estado_pago IN ('PENDIENTE', 'PARCIAL')
ORDER BY f.fecha_vencimiento;

-- Ventas por agente, reporte interno del área 2 (con IVA, todos los estados salvo cancelado).
CREATE OR REPLACE VIEW v_ventas_agente AS
SELECT a.id_agente, a.nombre,
       COUNT(DISTINCT f.id_factura) FILTER (WHERE f.estado_pago <> 'CANCELADO')                        AS numero_facturas,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago <> 'CANCELADO'), 0)                     AS monto_vendido,
       COALESCE(SUM(f.subtotal)    FILTER (WHERE f.estado_pago = 'PAGADO'), 0)                         AS monto_cobrado_sin_iva
FROM agentes_ventas a
LEFT JOIN facturas f USING (id_agente)
GROUP BY a.id_agente, a.nombre;

-- CONTRATO CON EL ÁREA 4 (I-02): cartera por agente para el bono de cobranza sana (RN-A2-09).
CREATE OR REPLACE VIEW v_cartera_agente AS
SELECT f.id_agente,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')), 0)         AS cartera_total,
       COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')
                                             AND f.fecha_vencimiento < CURRENT_DATE), 0)              AS cartera_vencida,
       CASE WHEN COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')), 0) = 0 THEN 0
            ELSE ROUND(COALESCE(SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')
                                                             AND f.fecha_vencimiento < CURRENT_DATE), 0)
                       / SUM(f.valor_total) FILTER (WHERE f.estado_pago IN ('PENDIENTE','PARCIAL')) * 100, 2)
       END                                                                                              AS pct_vencida
FROM facturas f
GROUP BY f.id_agente;

-- CONTRATO CON EL ÁREA 5 (I-07): IVA trasladado por mes para la obligación mensual de IVA.
CREATE OR REPLACE VIEW v_iva_trasladado_periodo AS
SELECT TO_CHAR(f.fecha, 'YYYY-MM')                          AS periodo,
       COUNT(*)                                             AS numero_facturas,
       COUNT(f.uuid_cfdi)                                   AS facturas_con_cfdi,
       SUM(f.subtotal)                                      AS subtotal,
       SUM(f.iva)                                           AS iva_trasladado,
       SUM(f.valor_total)                                   AS total
FROM facturas f
WHERE f.estado_pago <> 'CANCELADO'
GROUP BY periodo
ORDER BY periodo;

-- CONTRATO CON EL ÁREA 6 (I-10): clientes vigentes para campañas directas (RN-A2-10).
CREATE OR REPLACE VIEW v_clientes_activos AS
SELECT id_cliente, numero_comercializador, nombre_empresa, rfc, estado
FROM clientes
WHERE activo
ORDER BY nombre_empresa;
