-- Área 3 · Issue #39 · RN-A3-08
-- Qué hace: v_entradas_area1 suma el capital redondeado a centavos por entrada, igual que productos.capital_inversion
-- (DECIMAL(14,2) en cada inserción) y que v_entradas_detalle del área 1. Antes sumaba sin redondear y difería un centavo.

CREATE OR REPLACE VIEW v_entradas_area1 WITH (security_invoker = true) AS
SELECT TO_CHAR(e.fecha, 'YYYY-MM') AS periodo, p.tipo,
       SUM(e.cantidad)                                                                                  AS volumen_comercializacion,
       SUM(ROUND(e.cantidad * (e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio, 2)) AS capital_inversion,
       ROUND(AVG((e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio), 2)     AS valor_promedio_entrada
FROM entradas_producto e JOIN productos p USING (id_producto)
GROUP BY periodo, p.tipo ORDER BY periodo;
