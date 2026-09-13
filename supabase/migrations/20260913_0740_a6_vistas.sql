-- Área 6 · Issues #114, #115, #116 · RN-A6-02, RN-A6-11, RN-A6-12, RN-A6-14
-- Qué hace: vistas de contrato con la coordinación (v_campana_resumen, v_costos_por_canal), ventas atribuidas
-- reales sobre facturas pagadas del área 2 (v_ventas_atribuidas_campana), desempeño del marketing directo
-- (v_directo_desempeno) y productos de baja rotación sobre v_rotacion del área 3.

-- RN-A6-11, RN-A6-12: el costo total y el ROI se calculan aquí, nunca se almacenan
CREATE OR REPLACE VIEW v_campana_resumen AS
SELECT c.id_campana, c.nombre, c.tipo_marketing, c.estatus, c.fecha_inicio, c.fecha_fin,
       c.presupuesto_asignado,
       COALESCE(g.gasto_total, 0)                                            AS gasto_total,
       c.presupuesto_asignado - COALESCE(g.gasto_total, 0)                   AS presupuesto_restante,
       CASE WHEN c.presupuesto_asignado > 0
            THEN ROUND(COALESCE(g.gasto_total, 0) / c.presupuesto_asignado * 100, 2) ELSE 0 END AS pct_ejercido,
       COALESCE(m.leads_generados, 0)                                        AS leads_generados,
       COALESCE(m.conversiones, 0)                                           AS conversiones,
       COALESCE(m.ingreso_atribuido, 0)                                      AS ingreso_atribuido,
       CASE WHEN COALESCE(g.gasto_total, 0) > 0
            THEN ROUND((COALESCE(m.ingreso_atribuido, 0) - g.gasto_total) / g.gasto_total, 4)
            ELSE NULL END                                                    AS roi
FROM campanas c
LEFT JOIN (SELECT id_campana, SUM(monto) AS gasto_total FROM costos_marketing GROUP BY id_campana) g USING (id_campana)
LEFT JOIN (SELECT id_campana, SUM(leads_generados) AS leads_generados, SUM(conversiones) AS conversiones,
                  SUM(ingreso_atribuido) AS ingreso_atribuido
             FROM metricas_marketing GROUP BY id_campana) m USING (id_campana);

CREATE OR REPLACE VIEW v_costos_por_canal AS
SELECT ca.id_canal, ca.nombre AS canal, ca.categoria,
       COUNT(DISTINCT co.id_campana) AS campanas_relacionadas,
       COALESCE(SUM(co.monto), 0)    AS gasto_total
FROM canales_marketing ca
LEFT JOIN costos_marketing co USING (id_canal)
GROUP BY ca.id_canal, ca.nombre, ca.categoria
ORDER BY gasto_total DESC;

-- Desempeño del marketing directo por campaña (RN-A6-02)
CREATE OR REPLACE VIEW v_directo_desempeno AS
SELECT c.id_campana, c.nombre,
       COUNT(cc.id_cliente)                                                                            AS total_objetivo,
       COUNT(cc.id_cliente) FILTER (WHERE cc.estado_contacto IN ('CONTACTADO', 'RESPONDIO', 'CONVERTIDO')) AS total_contactados,
       COUNT(cc.id_cliente) FILTER (WHERE cc.estado_contacto = 'CONVERTIDO')                          AS total_convertidos,
       CASE WHEN COUNT(cc.id_cliente) > 0
            THEN ROUND(COUNT(cc.id_cliente) FILTER (WHERE cc.estado_contacto = 'CONVERTIDO')::numeric
                       / COUNT(cc.id_cliente) * 100, 2) ELSE 0 END                                    AS tasa_conversion_pct
FROM campanas c
JOIN campana_clientes cc USING (id_campana)
WHERE c.tipo_marketing = 'DIRECTO'
GROUP BY c.id_campana, c.nombre;

-- RN-A6-14: ventas atribuidas reales = facturas PAGADO de los clientes objetivo dentro de la vigencia
CREATE OR REPLACE VIEW v_ventas_atribuidas_campana AS
SELECT c.id_campana, c.nombre, c.tipo_marketing,
       COUNT(DISTINCT f.id_factura)            AS facturas_atribuidas,
       COALESCE(SUM(f.valor_total - f.iva), 0) AS ventas_atribuidas_sin_iva,
       COALESCE(g.gasto_total, 0)              AS gasto_total,
       CASE WHEN COALESCE(g.gasto_total, 0) > 0
            THEN ROUND((COALESCE(SUM(f.valor_total - f.iva), 0) - g.gasto_total) / g.gasto_total, 4)
            ELSE NULL END                      AS roi_real
FROM campanas c
LEFT JOIN campana_clientes cc USING (id_campana)
LEFT JOIN facturas f ON f.id_cliente = cc.id_cliente
                    AND f.estado_pago = 'PAGADO'
                    AND f.fecha >= c.fecha_inicio
                    AND f.fecha <= COALESCE(c.fecha_fin, CURRENT_DATE)
LEFT JOIN (SELECT id_campana, SUM(monto) AS gasto_total FROM costos_marketing GROUP BY id_campana) g USING (id_campana)
WHERE c.tipo_marketing = 'DIRECTO'
GROUP BY c.id_campana, c.nombre, c.tipo_marketing, g.gasto_total;

-- Productos de baja rotación (v_rotacion del área 3) y si ya tienen campaña vigente
CREATE OR REPLACE VIEW v_productos_baja_rotacion_campana AS
SELECT r.id_producto, r.nombre, r.tipo, r.stock, r.porcentaje_rotacion,
       COUNT(cp.id_campana) FILTER (WHERE c.estatus IN ('PLANEADA', 'ACTIVA')) AS campanas_vigentes
FROM v_rotacion r
LEFT JOIN campana_productos cp USING (id_producto)
LEFT JOIN campanas c USING (id_campana)
WHERE r.porcentaje_rotacion < 30
GROUP BY r.id_producto, r.nombre, r.tipo, r.stock, r.porcentaje_rotacion
ORDER BY r.porcentaje_rotacion;
