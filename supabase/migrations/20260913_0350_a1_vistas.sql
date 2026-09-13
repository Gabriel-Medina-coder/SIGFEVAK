-- Área 1 · Issues #31, #32 · RN-A1-08, RN-A1-14, RN-A1-17
-- Qué hace: vistas de reporte del área (v_entradas_detalle, v_stock_por_almacen, v_discrepancias_recepcion,
-- v_reabastecimiento, v_ordenes_produccion, v_capital_en_proceso) y vistas de contrato: v_entradas_importacion
-- (área 5, I-04), v_ordenes_produccion (área 6) y v_mano_obra_produccion (área 4, I-06).

-- Detalle de cada entrada con su capital real (RN-A1-08). Reporte financiero con IVA desglosado y factura.
CREATE OR REPLACE VIEW v_entradas_detalle AS
SELECT e.id_entrada, e.fecha, p.id_producto, p.sku, p.nombre, p.tipo, p.categoria, p.marca, p.modelo,
       COALESCE(pr.nombre, e.proveedor) AS proveedor, pr.rfc AS rfc_proveedor, a.nombre AS almacen, l.numero_lote,
       e.cantidad, e.cantidad_esperada, e.estado_mercancia,
       e.moneda, e.tipo_cambio, e.costo_unitario, e.flete_unitario, e.impuestos_unitarios,
       ROUND((e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio, 2)              AS valor_unitario_mxn,
       ROUND((e.costo_unitario + e.flete_unitario + e.impuestos_unitarios) * e.tipo_cambio * e.cantidad, 2) AS capital_entrada_mxn,
       ROUND(e.costo_unitario * e.tipo_cambio * e.cantidad * 0.16, 2)                                        AS iva_estimado_mxn,
       e.numero_orden_compra, e.numero_factura_proveedor, e.fecha_factura_proveedor,
       e.pais_origen, e.documento_importacion_ref, e.id_orden_produccion, e.responsable_recepcion
FROM entradas_producto e
JOIN productos p USING (id_producto)
LEFT JOIN proveedores pr USING (id_proveedor)
LEFT JOIN almacenes a USING (id_almacen)
LEFT JOIN lotes l USING (id_lote)
ORDER BY e.fecha DESC, e.id_entrada DESC;

-- Entradas por almacén (informativa: el stock global sigue en productos.stock)
CREATE OR REPLACE VIEW v_stock_por_almacen AS
SELECT a.id_almacen, a.nombre AS almacen, p.id_producto, p.sku, p.nombre,
       SUM(e.cantidad) AS unidades_ingresadas,
       MAX(e.fecha)    AS ultima_entrada
FROM entradas_producto e JOIN almacenes a USING (id_almacen) JOIN productos p USING (id_producto)
GROUP BY a.id_almacen, a.nombre, p.id_producto, p.sku, p.nombre;

-- Discrepancias de recepción: faltantes, sobrantes y mercancía dañada
CREATE OR REPLACE VIEW v_discrepancias_recepcion AS
SELECT e.id_entrada, e.fecha, p.sku, p.nombre, pr.nombre AS proveedor,
       e.cantidad_esperada, e.cantidad, (e.cantidad - e.cantidad_esperada) AS diferencia,
       e.estado_mercancia, e.numero_factura_proveedor, e.observaciones
FROM entradas_producto e JOIN productos p USING (id_producto) LEFT JOIN proveedores pr USING (id_proveedor)
WHERE (e.cantidad_esperada IS NOT NULL AND e.cantidad <> e.cantidad_esperada)
   OR e.estado_mercancia <> 'BUEN_ESTADO';

-- Reabastecimiento: productos bajo su mínimo
CREATE OR REPLACE VIEW v_reabastecimiento AS
SELECT p.id_producto, p.sku, p.nombre, p.stock, p.stock_minimo, (p.stock_minimo - p.stock) AS faltante
FROM productos p WHERE p.stock_minimo > 0 AND p.stock < p.stock_minimo;

-- Órdenes de producción con consumo teórico vs real, costo y marca de desviación (RN-A1-14, RN-A1-17). Contrato con el área 6.
CREATE OR REPLACE VIEW v_ordenes_produccion AS
WITH teorico AS (
    SELECT o.id_orden, SUM(b.cantidad_por_unidad * o.cantidad_planeada * m.costo_unitario) AS costo_materia_teorico
    FROM ordenes_produccion o
    JOIN bom b ON b.id_producto_destino = o.id_producto_destino
    JOIN materias_primas m ON m.id_materia = b.id_materia
    GROUP BY o.id_orden
), real AS (
    SELECT c.id_orden, SUM(c.cantidad_real * m.costo_unitario) AS costo_materia_real, SUM(c.merma) AS merma_total
    FROM consumo_produccion c JOIN materias_primas m USING (id_materia)
    GROUP BY c.id_orden
)
SELECT o.id_orden, o.folio, o.estado, p.sku, p.nombre AS producto, o.cantidad_planeada, o.cantidad_terminada,
       o.fecha_inicio_programada, o.fecha_fin_programada, o.fecha_inicio_real, o.fecha_fin_real, o.responsable,
       COALESCE(t.costo_materia_teorico, 0) AS costo_materia_teorico,
       COALESCE(r.costo_materia_real, 0)    AS costo_materia_real,
       COALESCE(r.merma_total, 0)           AS merma_total,
       o.costo_mano_obra, o.costos_indirectos,
       CASE WHEN o.cantidad_terminada > 0
            THEN ROUND((COALESCE(r.costo_materia_real, 0) + o.costo_mano_obra + o.costos_indirectos) / o.cantidad_terminada, 2)
       END AS costo_unitario_manufactura,
       qc.aprobadas, qc.rechazadas, qc.motivo_rechazo,
       COALESCE(r.costo_materia_real > 1.2 * t.costo_materia_teorico, FALSE) AS desviacion_consumo
FROM ordenes_produccion o
JOIN productos p ON p.id_producto = o.id_producto_destino
LEFT JOIN teorico t USING (id_orden)
LEFT JOIN real r USING (id_orden)
LEFT JOIN control_calidad qc ON qc.id_orden = o.id_orden
ORDER BY o.id_orden;

-- Capital en proceso: materia consumida en órdenes abiertas + mano de obra + indirectos
CREATE OR REPLACE VIEW v_capital_en_proceso AS
SELECT o.id_orden, o.folio, o.estado,
       COALESCE(SUM(c.cantidad_real * m.costo_unitario), 0) + o.costo_mano_obra + o.costos_indirectos AS capital_en_proceso
FROM ordenes_produccion o
LEFT JOIN consumo_produccion c USING (id_orden)
LEFT JOIN materias_primas m ON m.id_materia = c.id_materia
WHERE o.estado IN ('EN_PROCESO', 'EN_CALIDAD')
GROUP BY o.id_orden, o.folio, o.estado, o.costo_mano_obra, o.costos_indirectos;

-- CONTRATO CON EL ÁREA 5 (I-04): entradas de importación con lo que necesita para pedimentos e impuestos
CREATE OR REPLACE VIEW v_entradas_importacion AS
SELECT e.id_entrada, e.fecha, p.sku, p.nombre, p.tipo, pr.nombre AS proveedor, pr.pais AS pais_proveedor,
       e.pais_origen, e.documento_importacion_ref, e.numero_factura_proveedor,
       e.cantidad, e.moneda, e.tipo_cambio, e.costo_unitario,
       ROUND(e.costo_unitario * e.tipo_cambio * e.cantidad, 2) AS valor_mercancia_mxn,
       e.impuestos_unitarios, ROUND(e.impuestos_unitarios * e.tipo_cambio * e.cantidad, 2) AS impuestos_capturados_mxn
FROM entradas_producto e JOIN productos p USING (id_producto) LEFT JOIN proveedores pr USING (id_proveedor)
WHERE e.pais_origen IS NOT NULL AND e.pais_origen <> 'México';

-- CONTRATO CON EL ÁREA 4 (I-06): mano de obra directa por orden terminada, para bonos de productividad
CREATE OR REPLACE VIEW v_mano_obra_produccion AS
SELECT o.id_orden, o.folio, o.responsable, o.fecha_fin_real, o.cantidad_terminada, o.costo_mano_obra,
       TO_CHAR(o.fecha_fin_real, 'YYYY-MM') AS periodo
FROM ordenes_produccion o WHERE o.estado = 'TERMINADA';
