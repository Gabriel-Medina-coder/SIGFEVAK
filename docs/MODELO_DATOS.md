# Modelo de datos global

Todas las tablas de las seis áreas en una sola base PostgreSQL (D-02). Este archivo dice **quién es dueño de qué**; el detalle de columnas está en el `CONTEXTO.md` de cada área. Cuando dos áreas discrepan, este archivo es el árbitro y el coordinador lo actualiza tras cada issue de integración.

## Reglas

1. Cada tabla tiene exactamente un área dueña. Solo esa área escribe en ella.
2. Las otras áreas leen por **vistas** `v_*`, nunca por la tabla.
3. Ampliar una tabla de otra área es siempre **aditivo**: columnas opcionales o con default, nunca cambiar ni quitar.
4. Los valores de enum se registran aquí. Nadie agrega valores sin actualizar esta lista.

## Tablas por área

| Tabla | Dueña | Quién más escribe | Origen |
| --- | --- | --- | --- |
| `usuarios` | Coordinador (a00) | — | Espejo de Supabase Auth: `id_usuario UUID` = `auth.users.id`, `nombre`, `correo`, `rol rol_usuario`, `area SMALLINT`, `activo`. La crea la migración base. Registro público cerrado: las cuentas las crea el coordinador |
| `productos` | Área 3 | Área 1 agrega columnas: `sku`, `codigo_barras`, `categoria`, `marca`, `modelo`, `unidad_medida`, `precio_venta_sugerido`, `stock_minimo` | Modelo base + D-03 |
| `entradas_producto` | Área 3 | Área 1 agrega columnas: `id_proveedor`, `id_almacen`, `id_lote`, `id_orden_produccion`, `cantidad_esperada`, `estado_mercancia`, `flete_unitario`, `impuestos_unitarios`, `moneda`, `tipo_cambio`, `pais_origen`, `numero_orden_compra`, `numero_factura_proveedor`, `fecha_factura_proveedor`, `documento_importacion_ref`, `responsable_recepcion`, `observaciones`; y un trigger de validación `fn_valida_entrada` | Modelo base + D-03 |
| `ajustes_inventario` | Área 3 | — | Área 3 |
| `proveedores`, `almacenes`, `lotes`, `materias_primas`, `entradas_materia_prima`, `ordenes_produccion`, `bom`, `consumo_produccion`, `control_calidad` | Área 1 | — | D-03; detalle en `docs/area1-entradas/CONTEXTO.md` |
| `clientes` | Área 2 | — | Modelo base + Área 2 agrega: `numero_comercializador` (folio `COM-000001`), `dias_credito`, `activo` (baja lógica), CHECK de RFC. Detalle en `docs/area2-contabilidad/CONTEXTO.md` |
| `facturas` | Área 2 | — | Modelo base + Área 2 agrega: `folio` (`FAC-000001`), `subtotal`, `fecha_vencimiento` (fecha + días de crédito), `fecha_cobro` (la llena el trigger al pasar a PAGADO), `uuid_cfdi` opcional. `valor_total` e `iva` se recalculan por trigger desde `detalle_factura`; nadie los escribe a mano |
| `detalle_factura` | Área 2 crea el renglón | Área 3 valida stock y lo descuenta por trigger | Modelo base |
| `agentes_ventas` | Área 3 define las 4 columnas base; Área 4 administra | Área 4 agrega columnas (rfc, curp, nss, fecha_ingreso, zona, esquema, salario_diario, entidad, clabe, estatus) | Modelo base + Área 4 |
| `zonas`, `esquemas_compensacion`, `tramos_comision`, `metas`, `bonos_catalogo`, `bonos_asignados`, `periodos_nomina`, `nomina_detalle`, `ajustes_comision`, `parametros_legales`, `bitacora_nomina` | Área 4 | — | Área 4 |
| `instituciones`, `tipos_obligacion`, `parametros_fiscales`, `obligaciones`, `declaraciones`, `pagos_obligacion`, `documentos_fiscales`, `alertas`, `importaciones`, `productos_importados`, `licencias_permisos`, `bitacora_fiscal` | Área 5 | — | Detalle en `docs/area5-fiscal/CONTEXTO.md`. No existe tabla `cfdi` (el UUID vive en `facturas`, Área 2) ni `impuesto_nomina` (el ISN lo calcula el Área 4 y el Área 5 registra la obligación) |
| `impuestos_licencias` | Área 5 | — | Modelo base. Liga producto ↔ permiso; `licencias_permisos` es la licencia de la empresa |
| `canales_marketing`, `proveedores_marketing`, `campanas`, `costos_marketing`, `metricas_marketing`, `campana_productos`, `campana_clientes`, `investigaciones_mercado` | Área 6 | — | Diseño del equipo del Área 6, detalle en `docs/area6-marketing/CONTEXTO.md`. **Sustituyen** a las tablas marcador `marketing` y `clientes_marketing` del modelo base (I-09). FK de solo lectura a `productos`, `clientes`, `facturas` y `usuarios` |

## Vistas de contrato

| Vista | Publica | Consumen | Qué da |
| --- | --- | --- | --- |
| `v_inventario_actual` | Área 3 | Todas | Stock, volumen, valor de inventario por producto |
| `v_kardex` | Área 3 | 1, 2 | Entradas y salidas en una línea de tiempo |
| `v_rotacion` | Área 3 | 4, 6 | Unidades vendidas y porcentaje de rotación |
| `v_discrepancias` | Área 3 | — | Ajustes de conciliación |
| `v_entradas_area1` | Área 3 | 1 | Volumen, capital y valor promedio por periodo y tipo. Con I-01 recalcula capital con flete e impuestos |
| `v_entradas_detalle` | Área 1 | 2 | Capital real por entrada, IVA estimado, factura del proveedor |
| `v_stock_por_almacen` | Área 1 | 3, 6 | Informativa; el stock global sigue en `productos.stock` |
| `v_discrepancias_recepcion` | Área 1 | 2 | Cantidad esperada vs recibida, para reclamaciones |
| `v_reabastecimiento` | Área 1 | 3, 6 | Productos bajo `stock_minimo` |
| `v_ordenes_produccion` | Área 1 | 6 | Volumen proyectado de manufactura |
| `v_capital_en_proceso` | Área 1 | Coordinación | Capital en materia prima y producción en proceso |
| `v_entradas_importacion` | Área 1 | 5 | País de origen, documento de importación, valor e impuestos por entrada (I-04) |
| `v_mano_obra_produccion` | Área 1 | 4 | Mano de obra directa por orden, para bonos de productividad |
| `v_salidas_area2` | Área 3 define, Área 2 mantiene | 2, 4 | Unidades y monto facturado por cliente |
| `v_clientes_resumen` | Área 2 | 2, Coordinación | Comercializadores con facturas, monto facturado, pendiente y vencido |
| `v_facturas_pendientes` | Área 2 | 2, Coordinación | Facturas por cobrar con vencimiento y días vencidos |
| `v_ventas_agente` | Área 2 | 2 | Reporte interno: monto facturado por agente con IVA, todos los estados |
| `v_cartera_agente` | Área 2 | 4 | Cartera vencida por agente, para el bono de cobranza sana (I-02) |
| `v_clientes_activos` | Área 2 | 6 | Clientes con `activo = true` (I-10) |
| `v_ventas_cobradas_agente` | Área 4 | 4 | Facturas pagadas por agente y mes de cobro |
| `v_cumplimiento_meta` | Área 4 | 4, 6 | Ventas cobradas vs meta por agente |
| `v_retenciones_area5` | Área 4 | 5 | ISR retenido, IMSS obrero, base ISN e ISN estimado con la tasa de la entidad, por entidad y periodo |
| `v_desempeno_agente_zona` | Área 4 | 6 | Cumplimiento por agente y zona |
| `v_nomina_totales` | Área 4 | 4 | Percepciones, deducciones y neto por agente y periodo |
| `v_recibo_nomina` | Área 4 | 4 | Recibo por agente con claves SAT |
| `v_sbc_bimestral` | Área 4 | 4 | Base para el salario base de cotización bimestral |
| `v_clientes_nuevos_agente` | Área 4 | 4 | Primera compra pagada de cada cliente por agente |
| `v_obligaciones_pendientes`, `v_obligaciones_vencidas`, `v_calendario_fiscal`, `v_alertas_activas`, `v_licencias_por_vencer` | Área 5 | 5, tablero | Obligaciones por estado, próximos 30 días, alertas, licencias |
| `v_pagos_por_institucion` | Área 5 | 5, Coordinación | Pagos por institución y periodo |
| `v_tasas_isn` | Área 5 | 4 | Tasa de ISN por entidad (I-03) |
| `v_impuestos_importacion_producto` | Área 5 | 1 | IGI, DTA e IVA de importación por producto y entrada (I-04) |
| `v_resumen_fiscal` | Área 5 | Coordinación | KPI para el resumen general |
| `v_iva_trasladado_periodo` | Área 2 | 5 | IVA trasladado, subtotal y UUID de CFDI por mes de facturas no canceladas (I-07) |
| `v_campana_resumen` | Área 6 | 6, Coordinación | Presupuesto, gasto, % ejercido, leads, conversiones y ROI por campaña |
| `v_costos_por_canal` | Área 6 | 6, Coordinación | Gasto total por canal |
| `v_directo_desempeno` | Área 6 | 6 | Clientes objetivo, contactados, convertidos y tasa de conversión de campañas directas |
| `v_ventas_atribuidas_campana` | Área 6 | 6 | ROI real: facturas pagadas de clientes de la campaña dentro de su vigencia (lee `facturas` del Área 2) |
| `v_productos_baja_rotacion_campana` | Área 6 (opcional) | 6 | Candidatos a campaña desde `v_rotacion` del Área 3 |

## Seguridad de acceso

RLS activo en toda tabla. Sin sesión no se lee ni ejecuta nada (D-11). La escritura está limitada por rol en la base, reflejando `src/lib/permisos.js` (D-13, migraciones `0930` y `0940`): cada tabla solo la escribe el rol de su módulo, más ADMINISTRADOR; los parámetros y catálogos solo ADMINISTRADOR; `usuarios` es legible solo en la fila propia; `productos.stock` solo lo mueven los triggers de inventario. La lectura entre áreas queda abierta a `authenticated` por las vistas de contrato. Detalle en `docs/SEGURIDAD.md`.

## Enums registrados

| Tipo | Valores | Dueña |
| --- | --- | --- |
| `tipo_producto` | `ELECTRONICO`, `MANUFACTURA` | Área 3 |
| `estado_mercancia` | `BUEN_ESTADO`, `DANADO`, `INCOMPLETO` | Área 1 |
| `tipo_almacen` | `INSUMOS`, `PRODUCTO_TERMINADO` | Área 1 |
| `estado_orden` | `PLANEADA`, `EN_PROCESO`, `EN_CALIDAD`, `TERMINADA`, `CANCELADA` | Área 1 |
| `resultado_calidad` | `APROBADO`, `RECHAZADO` | Área 1 |
| `tipo_marketing` | `EXTERNO`, `DIRECTO` | Área 6 |
| `categoria_canal` | `TRADICIONAL`, `DIGITAL`, `DIRECTO`, `EVENTOS` | Área 6 |
| `tipo_proveedor_marketing` | `AGENCIA`, `MEDIO`, `FREELANCER`, `PLATAFORMA_DIGITAL`, `ESTUDIO_MERCADO`, `OTRO` | Área 6 |
| `estatus_campana` | `PLANEADA`, `ACTIVA`, `PAUSADA`, `FINALIZADA`, `CANCELADA` | Área 6 |
| `estado_contacto` | `OBJETIVO`, `CONTACTADO`, `RESPONDIO`, `CONVERTIDO`, `NO_INTERESADO` | Área 6 |
| `tipo_investigacion` | `ENCUESTA`, `FOCUS_GROUP`, `ANALISIS_MERCADO`, `BENCHMARKING_COMPETENCIA`, `ESTUDIO_SATISFACCION`, `OTRO` | Área 6 |
| `estado_investigacion` | `PLANEADA`, `EN_CURSO`, `FINALIZADA`, `CANCELADA` | Área 6 |
| `estado_pago` | `PENDIENTE`, `PARCIAL`, `PAGADO`, `CANCELADO` | Área 2 |
| `tipo_permiso` | `LICENCIA`, `PERMISO`, `ADUANAL`, `IMPUESTO` | Área 5 |
| `zona_salarial` | `GENERAL`, `ZLFN` | Área 4 |
| `estatus_agente` | `ACTIVO`, `BAJA`, `SUSPENDIDO` | Área 4 |
| `periodicidad`, `tipo_periodo` | `QUINCENAL`, `MENSUAL` | Área 4 |
| `estatus_periodo` | `ABIERTO`, `CALCULADO`, `REVISADO`, `AUTORIZADO`, `PAGADO`, `CERRADO` | Área 4 |
| `tipo_concepto` | `PERCEPCION`, `DEDUCCION` | Área 4 |
| `estado_obligacion` | `PENDIENTE`, `CALCULADO`, `PRESENTADO`, `LINEA_GENERADA`, `AUTORIZADO`, `PAGADO`, `CONCILIADO`, `CERRADO`, `VENCIDO` | Área 5 |
| `ambito_institucion` | `FEDERAL`, `ESTATAL`, `MUNICIPAL` | Área 5 |
| `frecuencia_obligacion` | `MENSUAL`, `BIMESTRAL`, `TRIMESTRAL`, `ANUAL`, `POR_OPERACION`, `SEGUN_VIGENCIA` | Área 5 |
| `nivel_alerta` | `PREVENTIVA`, `ALTA`, `CRITICA`, `VENCIDA` | Área 5 |
| `estado_envio_alerta` | `PENDIENTE`, `MOSTRADA`, `ATENDIDA` | Área 5 |
| `metodo_pago_fiscal` | `TRANSFERENCIA`, `SPEI`, `VENTANILLA`, `TARJETA`, `PORTAL` | Área 5 |
| `tipo_documento_fiscal` | `ACUSE_SAT`, `COMPROBANTE_BANCARIO`, `CFDI`, `PEDIMENTO`, `MANIFESTACION_E2`, `LICENCIA_FUNCIONAMIENTO`, `USO_SUELO`, `DICTAMEN_PROTECCION_CIVIL`, `REGISTRO_SIEM`, `OTRO` | Área 5 |
| `estado_licencia` | `EN_TRAMITE`, `VIGENTE`, `POR_VENCER`, `VENCIDA` | Área 5 |
| `rol_usuario` | `ADMINISTRADOR`, `CONTADOR`, `COMERCIO_EXTERIOR`, `AUTORIZADOR`, `GERENTE_VENTAS`, `ALMACEN`, `MARKETING`, `CAPTURISTA` | Coordinador. Cerrado: cubre los 4 usuarios del Área 5, la separación de funciones del Área 4 (gerente revisa, autorizador autoriza) y un rol operativo para las áreas 1, 3 y 6 |

## Integraciones pendientes

| # | Pide | A | Qué | Estado |
| --- | --- | --- | --- | --- |
| I-01 | Área 1 | Área 3 | Columnas aditivas en `productos` y `entradas_producto` (las hace el Área 1); cambio de fórmula en `fn_entrada_producto` y en `v_entradas_area1` a `(costo + flete + impuestos) × tipo_cambio` (lo hace el Área 3). Compatible hacia atrás por los defaults | Cerrada dom 13 (#1): `entradas_producto` nace con `flete_unitario`, `impuestos_unitarios` y `tipo_cambio`; `fn_entrada_producto` y `v_entradas_area1` ya usan la fórmula |
| I-02 | Área 4 | Área 2 | `fecha_cobro`, `fecha_vencimiento` y `subtotal` en `facturas`; `id_agente` ya es obligatorio; `v_cartera_agente` | Cerrada dom 13 (#42): columnas y vista aplicadas; el seed reproduce el ejemplo del Área 4 (Jorge Mendoza cobra 560,000 sin IVA en 2026-09, 2 clientes nuevos, cartera vencida 3 %) |
| I-03 | Área 4 | Área 5 | Tasas de ISN por estado cargadas en `parametros_legales` | Cerrada dom 13 (#62, #83): el Área 5 publica `v_tasas_isn` (Chiapas 0.02) y consume `v_retenciones_area5`; la obligación ISN del bimestre sep-oct se genera con la base del Área 4 (871.60) |
| I-04 | Área 5 ↔ Área 1 | ambas | El Área 1 publica `v_entradas_importacion`; el Área 5 devuelve el monto de impuestos aduanales por entrada (IGI, DTA, IVA de importación) para llenar `impuestos_unitarios`. Mientras no exista, se captura a mano con default 0 | Cerrada dom 13 (#21, #84): `v_entradas_importacion` y `v_impuestos_importacion_producto` publicadas; el pedimento del seed liga la entrada SZ-2026-0917; el IVA acreditable de compras se captura a mano (pregunta abierta 3 del Área 5) |
| I-06 | Área 4 | Área 1 | `v_mano_obra_produccion` para bonos de productividad; solo lectura, ya publicada | Cerrada dom 13 (#63): vista publicada por el Área 1; el Área 4 la documenta como insumo futuro |
| I-07 | Área 5 | Área 2 | `v_iva_trasladado_periodo`: IVA trasladado y UUID de CFDI por mes, para la obligación mensual de IVA | Cerrada dom 13 (#43): vista aplicada; `uuid_cfdi` opcional en `facturas` |
| I-08 | Área 5 | Coordinador | Tabla `usuarios` con `id_usuario UUID` y `rol`, referenciada desde obligaciones, pagos, alertas y bitácora; `pg_cron` para alertas o botón manual "Actualizar alertas" | Cerrada dom 13 (#86): `usuarios` con `rol_usuario` y cuentas de prueba por rol existen desde la migración base; las funciones diarias se disparan con el botón de administración (sin `pg_cron`) |
| I-09 | Área 6 | Área 3 | La migración base **no crea** `marketing` ni `clientes_marketing`; el Área 6 crea sus ocho tablas. Baja lógica en `productos` (columna `activo`) en vez de borrado físico | Cerrada dom 13 (#2): la base no crea `marketing` ni `clientes_marketing`; `productos.activo` existe |
| I-10 | Área 6 | Área 2 | Columna `activo` y baja lógica en `clientes`; lectura de `facturas` pagadas; `v_clientes_activos` | Cerrada dom 13 (#44): `clientes.activo`, trigger que impide facturar a inactivos y `v_clientes_activos` aplicados |
| I-05 | Área 6 | Área 4 | `v_desempeno_agente_zona` | Cerrada dom 13 (#63): vista aplicada con zona, región, meta, cumplimiento y ventas cobradas por agente y periodo |
| I-11 | Área 2 | Área 3 | Definir si cancelar una factura reintegra stock (pregunta abierta 2 del Área 2 y 3 del Área 3). Hoy no se reintegra; una devolución sería un ajuste de inventario | Cerrada dom 13 (#3): cancelar no reintegra stock; una devolución se registra como `ajustes_inventario` con motivo `DEVOLUCION` |
| I-12 | Área 2 | Área 4 | Un solo seed de `agentes_ventas` para no duplicar agentes entre las dos áreas | Cerrada dom 13 (#61): los 5 agentes viven en el seed base; el Área 4 solo les agrega datos laborales |
| I-13 | Área 2 | Área 1 | Leer `productos.precio_venta_sugerido` para precargar el precio unitario del renglón | Solo lectura, sin issue |
