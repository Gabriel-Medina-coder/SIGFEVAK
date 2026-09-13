-- Área 5 · Issues #92, #93, #95 · RN-A5-13, RN-A5-14
-- Qué hace: vistas de reporte (v_obligaciones_pendientes, v_obligaciones_vencidas, v_calendario_fiscal,
-- v_pagos_por_institucion, v_alertas_activas) y vistas de contrato: v_tasas_isn (área 4, I-03),
-- v_impuestos_importacion_producto (área 1, I-04) y v_resumen_fiscal (coordinación).

CREATE OR REPLACE VIEW v_obligaciones_pendientes AS
SELECT o.id_obligacion, t.clave, t.nombre AS obligacion, i.siglas AS institucion, i.ambito,
       o.periodo, o.fecha_vencimiento, (o.fecha_vencimiento - CURRENT_DATE) AS dias_restantes,
       o.monto_estimado, o.monto_final, o.estado, o.entidad, o.id_responsable
FROM obligaciones o
JOIN tipos_obligacion t USING (id_tipo_obligacion)
JOIN instituciones i USING (id_institucion)
WHERE o.activo AND o.estado NOT IN ('CONCILIADO', 'CERRADO')
ORDER BY o.fecha_vencimiento;

-- RF-16
CREATE OR REPLACE VIEW v_obligaciones_vencidas AS
SELECT * FROM v_obligaciones_pendientes WHERE estado = 'VENCIDO' OR dias_restantes < 0;

CREATE OR REPLACE VIEW v_calendario_fiscal AS
SELECT * FROM v_obligaciones_pendientes
WHERE fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + 30;

-- RF-17
CREATE OR REPLACE VIEW v_pagos_por_institucion AS
SELECT i.siglas AS institucion, i.ambito, TO_CHAR(p.fecha_pago, 'YYYY-MM') AS periodo_pago,
       t.clave, COUNT(*) AS numero_pagos, SUM(p.monto) AS monto_pagado
FROM pagos_obligacion p
JOIN obligaciones o USING (id_obligacion)
JOIN tipos_obligacion t USING (id_tipo_obligacion)
JOIN instituciones i USING (id_institucion)
WHERE p.estado_pago = 'PAGADO'
GROUP BY i.siglas, i.ambito, periodo_pago, t.clave
ORDER BY periodo_pago DESC, i.siglas;

CREATE OR REPLACE VIEW v_alertas_activas AS
SELECT a.id_alerta, a.fecha_alerta, a.dias_anticipacion, a.nivel, a.mensaje, a.estado_envio, a.id_usuario,
       o.id_obligacion, t.nombre AS obligacion, o.fecha_vencimiento, o.estado
FROM alertas a JOIN obligaciones o USING (id_obligacion) JOIN tipos_obligacion t USING (id_tipo_obligacion)
WHERE a.estado_envio <> 'ATENDIDA' AND a.fecha_alerta <= CURRENT_DATE
ORDER BY a.nivel DESC, a.fecha_alerta;

-- CONTRATO CON EL ÁREA 4 (I-03): tasa de ISN vigente por entidad
CREATE OR REPLACE VIEW v_tasas_isn AS
SELECT entidad, valor AS tasa_isn, vigencia_inicio, vigencia_fin
FROM parametros_fiscales
WHERE clave = 'TASA_ISN' AND (vigencia_fin IS NULL OR vigencia_fin >= CURRENT_DATE);

-- CONTRATO CON EL ÁREA 1 (I-04): impuestos de importación por producto y por unidad (RN-A5-13)
CREATE OR REPLACE VIEW v_impuestos_importacion_producto AS
SELECT i.id_importacion, i.numero_pedimento, i.id_entrada, i.fecha_importacion, i.pais_origen,
       pi.id_producto, pi.nombre, pi.fraccion_arancelaria, pi.nico, pi.cantidad,
       pi.tasa_igi, pi.igi_producto,
       ROUND(i.dta * pi.valor_total / NULLIF(i.valor_aduanero, 0), 2) AS dta_producto,
       ROUND((pi.valor_total + pi.igi_producto + i.dta * pi.valor_total / NULLIF(i.valor_aduanero, 0))
             * fn_parametro_fiscal('TASA_IVA', NULL, NULL, i.fecha_importacion), 2) AS iva_importacion_producto,
       ROUND((pi.igi_producto + i.dta * pi.valor_total / NULLIF(i.valor_aduanero, 0)) / pi.cantidad, 2) AS impuestos_por_unidad_sin_iva
FROM productos_importados pi JOIN importaciones i USING (id_importacion);

-- Resumen para el tablero general (coordinación)
CREATE OR REPLACE VIEW v_resumen_fiscal AS
SELECT
  (SELECT COALESCE(SUM(COALESCE(monto_final, monto_estimado)), 0) FROM v_obligaciones_pendientes) AS monto_pendiente,
  (SELECT COUNT(*) FROM v_obligaciones_pendientes) AS obligaciones_pendientes,
  (SELECT MIN(fecha_vencimiento) FROM v_obligaciones_pendientes WHERE fecha_vencimiento >= CURRENT_DATE) AS proximo_vencimiento,
  (SELECT COUNT(*) FROM v_obligaciones_vencidas) AS vencidas,
  (SELECT COALESCE(SUM(monto_pagado), 0) FROM v_pagos_por_institucion WHERE periodo_pago LIKE TO_CHAR(CURRENT_DATE, 'YYYY') || '%') AS pagado_en_el_anio,
  (SELECT COUNT(*) FROM v_alertas_activas) AS alertas_activas;
