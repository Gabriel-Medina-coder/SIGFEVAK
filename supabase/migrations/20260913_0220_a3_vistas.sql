-- Área 3 · Issues #6, #7, #8 · RN-A3-05, RN-A3-07, RN-A3-08
-- Qué hace: las cuatro vistas del área y las dos vistas de contrato (v_entradas_area1 con la fórmula
-- de I-01, v_salidas_area2). Las otras áreas consumen estas vistas, nunca las tablas.

-- Inventario actual con su valor. Reporte principal del área 3.
CREATE OR REPLACE VIEW v_inventario_actual AS
SELECT p.id_producto, p.nombre, p.tipo, p.activo, p.stock, p.volumen,
       p.valor_entrada, p.capital_inversion,
       (p.stock * p.valor_entrada) AS valor_inventario,
       (p.volumen - p.stock)       AS unidades_vendidas_historico
FROM productos p
ORDER BY p.nombre;

-- Kardex: entradas y salidas en una sola línea de tiempo por producto.
CREATE OR REPLACE VIEW v_kardex AS
SELECT p.id_producto, p.nombre, e.fecha, 'ENTRADA'::text AS movimiento,
       e.cantidad, e.costo_unitario AS precio,
       COALESCE(e.proveedor, e.documento_ref) AS referencia
FROM entradas_producto e JOIN productos p USING (id_producto)
UNION ALL
SELECT p.id_producto, p.nombre, f.fecha, 'SALIDA'::text AS movimiento,
       d.cantidad, d.precio_unitario AS precio,
       c.nombre_empresa AS referencia
FROM detalle_factura d
JOIN facturas f  USING (id_factura)
JOIN clientes c  USING (id_cliente)
JOIN productos p USING (id_producto)
ORDER BY id_producto, fecha;

-- Rotación de inventario: qué se mueve y qué está estancado.
CREATE OR REPLACE VIEW v_rotacion AS
SELECT p.id_producto, p.nombre, p.tipo, p.volumen, p.stock,
       (p.volumen - p.stock) AS vendido,
       CASE WHEN p.volumen = 0 THEN 0
            ELSE ROUND(((p.volumen - p.stock)::numeric / p.volumen) * 100, 1)
       END AS porcentaje_rotacion
FROM productos p
ORDER BY porcentaje_rotacion DESC;

-- Discrepancias acumuladas de conciliación.
CREATE OR REPLACE VIEW v_discrepancias AS
SELECT a.id_ajuste, a.fecha, p.id_producto, p.nombre, a.stock_sistema, a.conteo_fisico,
       a.diferencia, a.motivo, a.responsable
FROM ajustes_inventario a JOIN productos p USING (id_producto)
WHERE a.diferencia <> 0
ORDER BY a.fecha DESC;

-- CONTRATO CON EL ÁREA 1: valor, capital de inversión y volumen por periodo, con la fórmula de I-01.
CREATE OR REPLACE VIEW v_entradas_area1 AS
SELECT TO_CHAR(e.fecha, 'YYYY-MM') AS periodo, p.tipo,
       SUM(e.cantidad)                                                                    AS volumen_comercializacion,
       SUM(e.cantidad * (e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio) AS capital_inversion,
       ROUND(AVG((e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio), 2)   AS valor_promedio_entrada
FROM entradas_producto e JOIN productos p USING (id_producto)
GROUP BY periodo, p.tipo ORDER BY periodo;

-- CONTRATO CON EL ÁREA 2: unidades y monto facturado por cliente.
CREATE OR REPLACE VIEW v_salidas_area2 AS
SELECT c.id_cliente, c.nombre_empresa, c.rfc, c.estado,
       COUNT(DISTINCT f.id_factura) AS numero_facturas,
       SUM(d.cantidad)              AS unidades,
       SUM(d.importe)               AS monto_facturado
FROM detalle_factura d
JOIN facturas f USING (id_factura)
JOIN clientes c USING (id_cliente)
GROUP BY c.id_cliente, c.nombre_empresa, c.rfc, c.estado;
