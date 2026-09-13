# Tareas — Área 3 · Inventario

Desglose previo a los issues, derivado de `docs/area3-inventario/CONTEXTO.md` (tablas núcleo, tres triggers, RLS, seis vistas, seed, pruebas de RN-A3-01 y RN-A3-04) y de las integraciones que le tocan al área en `docs/MODELO_DATOS.md` (I-01, I-09, I-11). El líder lo revisa el sábado 12; después cada fila se convierte en un issue con la plantilla "Tarea" y se anota su número.

Estimación: S = menos de 2 h, M = medio día, L = un día. Roles según el contexto: Líder, Modelador/DBA, Captura y catálogos, Consultas y reportes, Documentación y enlace.

> **Antes de empezar (líder, domingo 13, día 1):** cada integrante hace fork, configura `upstream` y el hook de commit, y agrega su línea en `docs/EQUIPOS.md` por PR; el líder llena la sección 1 de `EVALUACION.md` (matriz de habilidades, tarea corta de prueba, roles según el contexto sección 14). Esto no es un issue de desarrollo.

> La migración base con los enums compartidos y las tablas base (`usuarios`, `clientes`, `agentes_ventas`, `facturas`, `detalle_factura`) la hace la coordinación. El área 3 crea sus tres tablas (`productos`, `entradas_producto`, `ajustes_inventario`), sus triggers, sus vistas y su RLS. Por I-09, la migración base **no** crea `marketing` ni `clientes_marketing`.

Orden por día (5 días, domingo 13 a jueves 17): dom 13 arranque, acuerdos I-01, I-09 e I-11 y asignación; lun 14 tablas, seed, triggers, RLS y pruebas SQL; mar 15 vistas, servicios, módulo, catálogo, entradas y kardex; mié 16 conciliación, reportes y punta a punta (congelamiento 18:00); jue 17 correcciones, evidencias y cierre. El sábado 12 es de coordinación; el viernes 18 no forma parte del plan.

| # | Título | Tipo | Nivel | Estimación | Depende de | Persona sugerida | RN | Issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Integración con el área 1: fórmula de capital con flete, impuestos y tipo de cambio (I-01) | tipo:integracion | nivel:medio | S | — | Líder | RN-A3-05, RN-A3-08 | #1 |
| 2 | Integración con el área 6: la migración base no crea `marketing` ni `clientes_marketing`; baja lógica `activo` en `productos` (I-09) | tipo:integracion | nivel:inicial | S | — | Líder | RN-A3-09 | #2 |
| 3 | Integración con el área 2: qué pasa con el stock al cancelar una factura (I-11, pregunta abierta 3) | tipo:integracion | nivel:medio | S | — | Líder | RN-A3-06, RN-A3-07 | #3 |
| 4 | Migración de tablas del área y RLS: `productos`, `entradas_producto`, `ajustes_inventario` con sus CHECK, columna generada, índices y políticas — `buena-primera-tarea` | tipo:bd | nivel:medio | M | 2 | Modelador/DBA | RN-A3-01, RN-A3-02, RN-A3-04, RN-A3-05, RN-A3-09 | #4 |
| 5 | Triggers de entrada, salida y ajuste (`fn_entrada_producto`, `fn_salida_producto`, `fn_ajuste_inventario`) con la fórmula acordada en I-01 | tipo:bd | nivel:avanzado | L | 1, 4 | Modelador/DBA | RN-A3-01, RN-A3-05, RN-A3-06, RN-A3-07, RN-A3-08 | #5 |
| 6 | Vistas del área: `v_inventario_actual`, `v_kardex`, `v_rotacion`, `v_discrepancias` | tipo:bd | nivel:medio | M | 5 | Consultas y reportes | RN-A3-05, RN-A3-07 | #6 |
| 7 | Vista de contrato `v_entradas_area1` con la fórmula de I-01; firma publicada en `docs/MODELO_DATOS.md` | tipo:bd | nivel:medio | S | 1, 6 | Consultas y reportes | RN-A3-08 | #7 |
| 8 | Vista de contrato `v_salidas_area2`; firma publicada en `docs/MODELO_DATOS.md` | tipo:bd | nivel:inicial | S | 6 | Consultas y reportes | — | #8 |
| 9 | Seed `seed_area3.sql` (20 productos y 10 movimientos, idempotente) y verificación de `supabase db reset` limpio sin escrituras directas a `stock` | tipo:pruebas | nivel:inicial | M | 5 | Captura y catálogos | RN-A3-04, RN-A3-06 | #9 |
| 10 | Pruebas SQL en `supabase/tests/area3/`: stock no negativo, cantidad positiva, entrada, salida y ajuste | tipo:pruebas | nivel:medio | M | 5, 9 | Modelador/DBA | RN-A3-01, RN-A3-04, RN-A3-05, RN-A3-07, RN-A3-08 | #10 |
| 11 | Módulo del área en la app compartida: `src/modules/area3-inventario/` y ruta "Base de Productos" en el menú — `buena-primera-tarea` | tipo:frontend | nivel:inicial | S | app base de coordinación | Consultas y reportes | — | #11 |
| 12 | Servicios `src/services/area3/inventario.js` y manejo centralizado de errores de Postgres a mensajes legibles | tipo:frontend | nivel:medio | M | 11, 6 | Consultas y reportes | RN-A3-01, RN-A3-04, RN-A3-06 | #12 |
| 13 | Pantalla de catálogo (KPI, tabla desde `v_inventario_actual`, etiquetas de estado) con alta y edición de producto | tipo:frontend | nivel:medio | M | 12 | Consultas y reportes + Captura y catálogos | RN-A3-01, RN-A3-05, RN-A3-06 | #13 |
| 14 | Formulario de entrada de producto: producto, cantidad, costo, proveedor, documento; el trigger hace el resto | tipo:frontend | nivel:medio | M | 12, 5 | Captura y catálogos | RN-A3-04, RN-A3-06 | #14 |
| 15 | Pantalla de kardex por producto desde `v_kardex`, con filtro de fechas | tipo:frontend | nivel:medio | M | 12, 6 | Consultas y reportes | RN-A3-08 | #15 |
| 16 | Pantalla de conciliación: conteo físico contra stock del sistema y registro del ajuste con motivo y responsable | tipo:frontend | nivel:avanzado | M | 12, 5 | Captura y catálogos | RN-A3-07 | #16 |
| 17 | Reportes de discrepancias (`v_discrepancias`) y rotación (`v_rotacion`) | tipo:frontend | nivel:inicial | S | 15 | Consultas y reportes | RN-A3-07 | #17 |
| 18 | Pruebas de punta a punta con las áreas 1 y 2 y validación de los cinco reportes contra el seed, con evidencias | tipo:pruebas | nivel:medio | M | 7, 8, 10, 13 a 17 | Líder + Consultas y reportes | RN-A3-01, RN-A3-03, RN-A3-05, RN-A3-08 | #18 |
| 19 | Cierre: contexto actualizado con los acuerdos de I-01, I-09 e I-11, evidencias por issue, `ESTADO.md` diario, reporte final y evaluación final del equipo | tipo:docs | nivel:inicial | M | todo | Líder + Documentación y enlace | — | #19 |

## Integraciones que este equipo necesita de otras áreas

| Qué | De quién | Para cuándo | Issue |
| --- | --- | --- | --- |
| Migración base con enums compartidos (`tipo_producto`, `estado_pago`, `tipo_permiso`) y tablas `usuarios`, `clientes`, `agentes_ventas`, `facturas`, `detalle_factura` | Coordinación | Sáb 12 sep (coordinación) | # |
| Columnas aditivas `flete_unitario`, `impuestos_unitarios`, `tipo_cambio` en `entradas_producto` (D-03), para que la fórmula de I-01 tenga qué leer | Área 1 | Lun 14 sep | # |
| Definición de devolución o cancelación de factura respecto al stock (I-11) | Área 2 | Dom 13 sep (decisión) | # |
| App base con menú y módulo vacío por área | Coordinación | Sáb 12 sep (coordinación) | # |

## Integraciones que este equipo entrega a otras áreas

| Qué | Para quién | Vía (vista) | Issue |
| --- | --- | --- | --- |
| Volumen, capital de inversión y valor promedio por periodo y tipo, con la fórmula de I-01 | Área 1 | `v_entradas_area1` | # |
| Validación y descuento de stock al insertar renglones de factura | Área 2 | Trigger `fn_salida_producto` sobre `detalle_factura` | # |
| Unidades y monto facturado por cliente | Áreas 2 y 4 | `v_salidas_area2` | # |
| Unidades vendidas y porcentaje de rotación por producto | Áreas 4 y 6 | `v_rotacion` | # |
| Stock, volumen y valor de inventario por producto | Todas, Coordinación (resumen general) | `v_inventario_actual` | # |
| No crear `marketing` ni `clientes_marketing`; baja lógica en `productos` | Área 6 | Migración base y columna `activo` | # |

## Detalle de cada tarea

**1 — Integración I-01 con el área 1.** Aceptación: issue `tipo:integracion` con ambos líderes de acuerdo en que `fn_entrada_producto` y `v_entradas_area1` pasan a `(costo_unitario + flete_unitario + impuestos_unitarios) × tipo_cambio`, compatible hacia atrás porque los defaults son 0 y 1; acuerdo anotado en `docs/MODELO_DATOS.md`.

**2 — Integración I-09 con el área 6.** Aceptación: la sección 10 del contexto marca `marketing` y `clientes_marketing` como no creadas; `productos` recibe `activo BOOLEAN NOT NULL DEFAULT TRUE`; el área 6 confirma en el issue.

**3 — Integración I-11 con el área 2.** Aceptación: decisión escrita en ambos contextos: cancelar una factura no reintegra stock y una devolución se registra como ajuste con motivo `DEVOLUCION`, o se define otra regla; la pregunta abierta 3 queda cerrada.

**4 — Migración de tablas del área y RLS.** Absorbe: tabla `productos`, tablas `entradas_producto` y `ajustes_inventario`, índices y políticas RLS. Archivos `supabase/migrations/AAAAMMDD_HHMM_a3_tablas_inventario.sql` y `..._a3_rls.sql` con encabezado de área, issue y RN. Aceptación: aplica sin error; `INSERT` con stock negativo falla por `ck_stock_no_negativo`; dos productos con el mismo nombre y tipo fallan por `uq_producto`; `productos` tiene `activo` con default `TRUE`; `entradas_producto` rechaza `cantidad <= 0` y `costo_unitario < 0`; `ajustes_inventario.diferencia` se calcula sola como `conteo_fisico - stock_sistema`; existen `ix_entradas_producto`, `ix_entradas_fecha`, `ix_detalle_producto`, `ix_detalle_factura`; con la llave `anon` sin sesión las tablas del área y `detalle_factura` regresan vacío o rechazan escritura, y con usuario autenticado leen y escriben.

**5 — Triggers de entrada, salida y ajuste.** Absorbe: `fn_entrada_producto`, `fn_salida_producto`, `fn_ajuste_inventario`, en una migración `..._a3_triggers.sql`; cada función lleva comentario con sus RN. Aceptación: una entrada de 100 unidades a costo 380 sube `stock` y `volumen` en 100, `capital_inversion` en 38,000 (o el valor con flete e impuestos si vienen) y deja `valor_entrada = 380`; un renglón de `detalle_factura` con cantidad mayor al stock falla con mensaje que empieza por `RN-A3-01` e indica producto, disponible y solicitado, y un renglón válido descuenta exactamente esa cantidad usando `FOR UPDATE`; un ajuste con `conteo_fisico = 95` sobre stock 100 deja `stock = 95` y la fila del ajuste conserva `stock_sistema = 100` y `diferencia = -5`.

**6 — Vistas del área.** Aceptación: `v_inventario_actual` da `valor_inventario = stock × valor_entrada` y `unidades_vendidas_historico = volumen - stock`; `v_kardex` muestra entradas y salidas en una sola línea de tiempo por producto; `v_rotacion` calcula el porcentaje vendido; `v_discrepancias` solo lista ajustes con diferencia distinta de cero.

**7 — Vista de contrato `v_entradas_area1`.** Aceptación: agrupa por periodo `AAAA-MM` y tipo con la fórmula de I-01; la firma está en `docs/MODELO_DATOS.md` y no cambia después; el área 1 la consulta y confirma en el issue.

**8 — Vista de contrato `v_salidas_area2`.** Aceptación: da número de facturas, unidades y monto por cliente; la firma está en `docs/MODELO_DATOS.md` y no cambia después; las áreas 2 y 4 la consultan.

**9 — Seed y `db reset` limpio.** Absorbe: seed de 20 productos y 10 movimientos; verificación de reinicio limpio. Aceptación: `supabase/seed/seed_area3.sql` inserta 20 productos (electrónicos y de manufactura) y 10 movimientos con `ON CONFLICT DO NOTHING`; corre dos veces sin duplicar; incluye un producto con stock bajo y otro agotado para las etiquetas del catálogo; captura de la consola de `supabase db reset` sin errores en `evidencias/`; la búsqueda de `UPDATE productos SET stock` en migraciones y seed devuelve solo las tres funciones del área.

**10 — Pruebas SQL.** Absorbe: `rn01_stock_no_negativo.sql`, `rn04_cantidad_positiva.sql` y las pruebas de entrada, salida y ajuste. Aceptación: cinco archivos en `supabase/tests/area3/`, cada uno cita su RN en el encabezado y falla con `RAISE EXCEPTION` solo si la regla no se cumple; una venta mayor al stock es rechazada; inserts con cantidad 0 y -1 en entradas y en detalle fallan por `CHECK`; una entrada de 100 sube stock y volumen; una venta de 30 solo baja stock; un ajuste conserva `stock_sistema` y `conteo_fisico`; los cinco corren limpios contra el seed.

**11 — Módulo en la app.** Aceptación: la ruta "Base de Productos" del menú abre el módulo y una consulta a `v_inventario_actual` regresa datos del seed.

**12 — Servicios y errores.** Absorbe: capa de servicios y traducción de errores de Postgres. Aceptación: funciones `obtenerInventario`, `registrarEntrada`, `registrarAjuste`, `obtenerKardex`, `obtenerRotacion`, `obtenerDiscrepancias` en español; ningún componente importa `supabase` directamente; ningún servicio envía `stock`, `volumen` ni `capital_inversion`; el intento de venta excedida desde el área 2 y una cantidad inválida desde el área 3 muestran texto en español, no el error crudo de Postgres.

**13 — Catálogo con alta y edición de producto.** Absorbe: pantalla de catálogo y formulario de producto. Aceptación: tres `KpiCard` (SKUs, unidades en almacén, rotación) con cifras que coinciden con `v_inventario_actual`; `Panel` + `Table` con `Tag` verde para disponible, ámbar para menos de 100 unidades, rojo para 0, como en `docs/referencia-ui/App.jsx`; el formulario solo pide tipo, nombre y `valor_entrada`; el producto nuevo aparece con stock 0.

**14 — Entrada de producto.** Aceptación: al guardar, el catálogo refleja el nuevo stock y capital sin que el frontend los calcule; cantidad 0 muestra mensaje legible.

**15 — Kardex.** Aceptación: entradas en verde y salidas en gris, orden cronológico, referencia de proveedor o cliente, cantidades y precios con `Mono`; filtro por rango de fechas.

**16 — Conciliación.** Aceptación: la pantalla muestra el stock del sistema antes de capturar el conteo; al guardar el ajuste, el stock cambia y la discrepancia aparece en el reporte; si el conteo coincide, no se crea ajuste.

**17 — Reportes.** Aceptación: discrepancias ordenadas por fecha descendente con diferencia en rojo si es negativa; rotación ordenada por porcentaje.

**18 — Pruebas de punta a punta y validación de reportes.** Absorbe: prueba con el área 1, prueba con el área 2 y validación de cifras de los cinco reportes. Aceptación: una entrada capturada desde el módulo del área 1 con flete 20 e impuestos 0 sobre costo 200 y 100 unidades deja `capital_inversion` en 22,000; desde el módulo del área 2, un renglón válido baja el stock y uno excedido muestra "stock insuficiente" sin perder lo capturado; cinco capturas nombradas `issue-NN-*.png` en `evidencias/`, cada una con la consulta SQL que la respalda; capturas de ambas áreas.

**19 — Cierre.** Absorbe: contexto actualizado, evidencias y bitácora, reporte final. Aceptación: las preguntas abiertas 1 a 5 tienen respuesta o justificación de por qué se posponen; I-01, I-09 e I-11 aparecen como cerradas; `ESTADO.md` con entrada diaria del domingo 13 al jueves 17; cada issue cerrado enlaza su evidencia; `REPORTE_FINAL.md` con la plantilla de `docs/plantillas/`, entregado antes de las 10:00 del viernes 18, con la matriz final de evaluación y el registro de control de cambios.
