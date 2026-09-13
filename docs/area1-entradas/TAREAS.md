# Tareas — Área 1 · Entradas y manufactura

Desglose previo a los issues, derivado de `CONTEXTO.md` (tablas, triggers, vistas, cronograma de 5 días) y de las integraciones I-01, I-04 e I-06 de `docs/MODELO_DATOS.md`. El líder lo revisa el domingo 13 (día 1); después cada fila se convierte en un issue con la plantilla "Tarea" y se anota su número.

> **Antes de empezar (líder):** cada integrante agrega su nombre y usuario a `docs/EQUIPOS.md` en su primer PR desde su fork; el líder llena la sección 1 de `EVALUACION.md` con la matriz de habilidades, la tarea corta (consulta del capital del ejemplo 10.1) y los roles, y lo anota en la bitácora de `ESTADO.md` del domingo 13. Ninguna de las dos cosas es un issue de desarrollo. Calendario: dom 13 arranque y acuerdos; lun 14 base de datos; mar 15 vistas, servicios y pantallas de captura; mié 16 flujos e integración con congelamiento a las 18:00; jue 17 cierre y entrega.

Estimación: S = menos de 2 h, M = medio día, L = un día. Roles: Líder, Datos (BD), Lógica (servicios), Frontend, Docs (documentación y pruebas).

Las tareas marcadas con ★ son `buena-primera-tarea`: se resuelven siguiendo el contexto paso a paso y sirven como primer PR.

| # | Título | Tipo | Nivel | Estimación | Depende de | Persona sugerida | RN | Issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Integración con el área 3: acordar D-03 y abrir I-01 (fórmula de capital en `fn_entrada_producto` y `v_entradas_area1`); verificarla una vez aplicada | tipo:integracion | nivel:medio | S | — | Líder | RN-A1-02, RN-A1-08 | # |
| 2 | Integración con el área 5: abrir I-04 (`v_entradas_importacion` a cambio de impuestos aduanales por entrada) y confirmar que la vista le sirve | tipo:integracion | nivel:inicial | S | — | Líder | RN-A1-08 | # |
| 3 | Validación con Almacén y Operaciones: checklist de la sección 11.5 y cierre de las preguntas abiertas 1, 6 y 8 | tipo:docs | nivel:inicial | S | — | Docs | — | # |
| 4 | Migración de tipos y catálogos: enums `estado_mercancia`, `tipo_almacen`, `estado_orden`, `resultado_calidad`; tablas `proveedores` y `almacenes` con RLS ★ | tipo:bd | nivel:inicial | S | 1 | Datos | RN-A1-06 | # |
| 5 | Migración aditiva de `productos` y `entradas_producto`: columnas de SKU y catálogo, columnas de origen, recepción y valor; `CHECK` de moneda y tipo de cambio; `CHECK` de documento de respaldo; índice único parcial de SKU | tipo:bd | nivel:medio | M | 4 | Datos | RN-A1-01, RN-A1-02, RN-A1-07, RN-A1-18 | # |
| 6 | Migración de manufactura: `lotes`, `materias_primas`, `entradas_materia_prima`, `ordenes_produccion`, `bom`, `consumo_produccion`, `control_calidad`, con sus `CHECK`, `UNIQUE (id_orden_produccion)` en entradas y RLS en todas las tablas nuevas | tipo:bd | nivel:medio | L | 4 | Datos | RN-A1-05, RN-A1-09, RN-A1-12, RN-A1-15 | # |
| 7 | Seed `seed_area1.sql`: 2 almacenes, 4 proveedores, 6 productos con SKU, 3 materias primas, 1 BOM, entradas del ejemplo 10.1, una importación en USD y una orden que llega a `TERMINADA` (ejemplo 10.2) | tipo:pruebas | nivel:medio | M | 5, 6 | Docs | RN-A1-08 | # |
| 8 | Trigger `fn_valida_entrada`: almacén de producto terminado, lote del mismo producto, copia del nombre del proveedor, documento de respaldo | tipo:bd | nivel:avanzado | M | 5, 6 | Datos | RN-A1-04, RN-A1-05, RN-A1-06, RN-A1-18 | # |
| 9 | Triggers de materias primas y de orden: `fn_entrada_materia`, `fn_valida_almacen_materia`, `fn_valida_orden` (producto con BOM), `fn_transicion_orden` (máquina de estados sin retroceso) | tipo:bd | nivel:avanzado | M | 6 | Datos | RN-A1-06, RN-A1-09, RN-A1-10, RN-A1-11 | # |
| 10 | Triggers de consumo y calidad: `fn_consumo_materia` (solo `EN_PROCESO`, materia en el BOM, sin stock negativo, marca de desviación mayor a 20 %) y `fn_valida_calidad` (totales, motivo, responsable distinto) | tipo:bd | nivel:avanzado | M | 9 | Datos | RN-A1-09, RN-A1-13, RN-A1-14, RN-A1-15, RN-A1-16 | # |
| 11 | Trigger `fn_cerrar_orden`: al pasar a `TERMINADA` calcula costo unitario de manufactura e inserta la entrada de producto terminado con proveedor "PRODUCCIÓN INTERNA" | tipo:bd | nivel:avanzado | M | 8, 10 | Datos | RN-A1-12, RN-A1-17 | # |
| 12 | Vistas de reporte: `v_entradas_detalle`, `v_stock_por_almacen`, `v_discrepancias_recepcion`, `v_reabastecimiento`, `v_capital_en_proceso` | tipo:bd | nivel:medio | M | 8, 11 | Datos | RN-A1-08 | # |
| 13 | Vistas de contrato: `v_entradas_importacion` (área 5), `v_ordenes_produccion` (área 6), `v_mano_obra_produccion` (área 4) | tipo:bd | nivel:medio | M | 11 | Datos | RN-A1-14, RN-A1-17 | # |
| 14 | Pruebas SQL del área en `supabase/tests/area1/`: entradas (almacén, lote, moneda, documento, proveedor) y manufactura (orden sin BOM, retroceso, consumo, stock negativo, calidad, doble cierre, costo del ejemplo 10.2) | tipo:pruebas | nivel:avanzado | L | 7, 11 | Docs | RN-A1-04 a RN-A1-18 | # |
| 15 | Servicios `src/services/area1/`: `proveedores.js`, `almacenes.js`, `entradas.js`, `produccion.js`, con manejo de errores de Postgres a mensajes legibles | tipo:backend | nivel:avanzado | L | app base de coordinación, 8, 11 | Lógica | RN-A1-03, RN-A1-08, RN-A1-09 a RN-A1-17 | # |
| 16 | Módulo del área en la app compartida (`src/modules/area1-entradas/`, ruta "Entradas" del menú) y pantallas de catálogos de proveedores y almacenes: listado, alta, edición y baja lógica ★ | tipo:frontend | nivel:inicial | M | 15 | Frontend | RN-A1-06 | # |
| 17 | Pantalla de entradas (vía A): formulario de registro con capital estimado en vivo, y listado con 3 `KpiCard` y `Table` desde `v_entradas_detalle`; manejo del rechazo del trigger sin perder lo capturado | tipo:frontend | nivel:avanzado | L | 15, 16 | Frontend | RN-A1-01, RN-A1-07, RN-A1-08, RN-A1-18 | # |
| 18 | Pantalla de orden de producción: alta con BOM y consumo teórico, captura de consumo y control de calidad con botones habilitados según estado, y cierre que muestra el costo unitario y la entrada generada | tipo:frontend | nivel:avanzado | L | 15, 16 | Frontend | RN-A1-10 a RN-A1-17 | # |
| 19 | Pruebas de punta a punta desde la app: entrada del ejemplo 10.1 hasta `v_inventario_actual` y orden del ejemplo 10.2 hasta el inventario; capturas en `evidencias/` | tipo:pruebas | nivel:medio | M | 17, 18 | Docs | RN-A1-08, RN-A1-17 | # |
| 20 | Integración con las áreas 4 y 6: confirmar que consumen `v_mano_obra_produccion` y `v_ordenes_produccion`; verificar que `v_entradas_area1` cuadra con `v_entradas_detalle` | tipo:integracion | nivel:inicial | S | 13, 1 | Líder | — | # |
| 21 | Cierre del área: evidencias por issue, `ESTADO.md` diario, `CONTEXTO.md` actualizado con los acuerdos reales y preguntas abiertas cerradas, reporte final y evaluación final del equipo | tipo:docs | nivel:inicial | M | todo | Líder, Docs | — | # |

## Integraciones que este equipo necesita de otras áreas

| Qué | De quién | Para cuándo | Issue |
| --- | --- | --- | --- |
| Acuerdo D-03 y cambio de fórmula de capital y valor de entrada en `fn_entrada_producto` y `v_entradas_area1` (I-01) | Área 3 | Decisión dom 13 sep; migración lun 14 sep | # |
| Tablas base `productos` y `entradas_producto` creadas en la migración base antes de las migraciones aditivas | Área 3 / Coordinación | Sáb 12 sep (coordinación) | # |
| Monto de impuestos aduanales por entrada para llenar `impuestos_unitarios`; mientras no exista se captura a mano (I-04) | Área 5 | Mié 16 sep | # |
| Definición de devolución a proveedor de mercancía dañada o incompleta (pregunta abierta 7) | Área 3 | Dom 13 sep (decisión) | # |
| App base con menú, componentes compartidos y login | Coordinación | Sáb 12 sep (coordinación) | # |

## Integraciones que este equipo entrega a otras áreas

| Qué | Para quién | Vía (vista) | Issue |
| --- | --- | --- | --- |
| País de origen, documento de importación, valor de mercancía e impuestos por entrada (I-04) | Área 5 | `v_entradas_importacion` | # |
| Mano de obra directa por orden terminada y responsable (I-06) | Área 4 | `v_mano_obra_produccion` | # |
| Volumen proyectado de manufactura y productos bajo stock mínimo | Área 6 | `v_ordenes_produccion`, `v_reabastecimiento` | # |
| Capital real por entrada, IVA estimado y factura del proveedor | Área 2 | `v_entradas_detalle` | # |
| Discrepancias entre cantidad esperada y recibida para reclamaciones | Área 2 | `v_discrepancias_recepcion` | # |
| Capital en materia prima y producción en proceso | Coordinación (resumen general) | `v_capital_en_proceso` | # |
| Stock por almacén de forma informativa | Áreas 3 y 6 | `v_stock_por_almacen` | # |

## Detalle de cada tarea

**1 — Integración con el área 3 (I-01).** Absorbe: acuerdo D-03 y verificación posterior. Aceptación: issue `tipo:integracion` con ambos líderes marcando su casilla; en el issue queda el texto exacto de la fórmula `(costo_unitario + flete_unitario + impuestos_unitarios) × tipo_cambio` y la lista de columnas aditivas; tras aplicar la migración del área 3, una entrada con flete e impuestos deja `capital_inversion` y `valor_entrada` con la fórmula acordada, y una entrada sin flete ni impuestos da el mismo resultado que antes.

**2 — Integración con el área 5 (I-04).** Absorbe: apertura del issue y confirmación de que `v_entradas_importacion` sirve. Aceptación: issue abierto indicando qué columnas devuelve la vista y en qué momento el área 5 entrega los impuestos por entrada; comentario del líder del área 5 confirmando; respuesta a la pregunta abierta 1 registrada.

**3 — Validación con Almacén y Operaciones.** Aceptación: las nueve preguntas de la sección 11.5 tienen respuesta o "pendiente con fecha"; las preguntas abiertas 1, 6 y 8 quedan resueltas en `CONTEXTO.md` sección 16.

**4 — Tipos y catálogos.** Absorbe: enums + `proveedores` + `almacenes`. Archivo `AAAAMMDD_HHMM_a1_tipos_catalogos.sql`. Aceptación: `supabase db reset` pasa y los cuatro tipos existen con sus valores registrados en `docs/MODELO_DATOS.md`; `proveedores` y `almacenes` existen con las columnas de la sección 5, `activo` con default y RLS activo; un almacén sin `tipo` falla.

**5 — Columnas aditivas en `productos` y `entradas_producto`.** Absorbe: ambas migraciones aditivas. Aceptación: un `INSERT` del área 3 con solo `tipo` y `nombre` sigue funcionando; dos productos con el mismo `sku` fallan; `unidad_medida` queda en `PIEZA` por default; un `INSERT` en `entradas_producto` con solo `id_producto`, `cantidad` y `costo_unitario` sigue funcionando; `moneda = 'USD'` con `tipo_cambio = 1` falla (RN-A1-07); una entrada sin factura, orden de compra ni orden de producción falla (RN-A1-18).

**6 — Manufactura.** Absorbe: lotes y materias primas, órdenes y calidad, y RLS de todas las tablas nuevas. Aceptación: `materias_primas.stock` no acepta negativos; `entradas_materia_prima` referencia materia y almacén; `lotes` referencia producto; `control_calidad` rechaza `aprobadas + rechazadas > cantidad_planeada`; una segunda entrada con el mismo `id_orden_produccion` falla por `UNIQUE`; con sesión `authenticated` las nueve tablas nuevas leen y escriben y sin sesión regresan vacío.

**7 — Seed.** Aceptación: corre limpio sobre una base recién creada; `v_entradas_detalle` muestra la entrada de 100 unidades a $200 con flete $20 y capital $22,000; existe una importación en USD con tipo de cambio distinto de 1; una orden llega a `TERMINADA` reproduciendo el ejemplo 10.2.

**8 — `fn_valida_entrada`.** Aceptación: entrada a almacén `INSUMOS` falla; lote de otro producto falla; al insertar con `id_proveedor` el campo texto `proveedor` queda con el nombre del catálogo y `v_kardex` lo muestra; entrada sin documento de respaldo falla.

**9 — Triggers de materias primas y de orden.** Absorbe: `fn_entrada_materia`, `fn_valida_almacen_materia`, `fn_valida_orden`, `fn_transicion_orden`. Aceptación: insertar en `entradas_materia_prima` sube `materias_primas.stock` exactamente en `cantidad`; asignar una materia a un almacén `PRODUCTO_TERMINADO` falla; crear orden para un producto sin BOM falla; `PLANEADA → EN_PROCESO → EN_CALIDAD → TERMINADA` pasa; `EN_CALIDAD → EN_PROCESO` falla; `CANCELADA` desde `EN_PROCESO` pasa y desde `TERMINADA` falla.

**10 — Triggers de consumo y calidad.** Absorbe: `fn_consumo_materia` y `fn_valida_calidad`. Aceptación: consumo en orden `PLANEADA` falla; materia fuera del BOM falla; consumo mayor al stock falla con mensaje RN-A1-09; consumo mayor al teórico en más de 20 % se guarda y `v_ordenes_produccion` lo marca como desviación; `rechazadas > 0` sin motivo falla; responsable igual al de la orden falla; totales dentro de lo planeado pasan.

**11 — `fn_cerrar_orden`.** Aceptación: al pasar a `TERMINADA` aparece una fila en `entradas_producto` con `id_orden_produccion`, proveedor "PRODUCCIÓN INTERNA", cantidad igual a `aprobadas` y `costo_unitario` igual al del ejemplo 10.2; el trigger del área 3 sube stock, volumen y capital del producto terminado; cerrar dos veces falla.

**12 — Vistas de reporte.** Aceptación: `v_entradas_detalle` calcula `capital_entrada_mxn` e `iva_estimado_mxn` según RN-A1-08; `v_reabastecimiento` lista solo productos con `stock < stock_minimo`; `v_discrepancias_recepcion` lista solo entradas con diferencia entre esperado y recibido; `v_capital_en_proceso` suma materia prima y órdenes en proceso.

**13 — Vistas de contrato.** Aceptación: `v_entradas_importacion` devuelve país de origen, documento e impuestos por entrada; `v_ordenes_produccion` incluye la marca de desviación; `v_mano_obra_produccion` devuelve costo de mano de obra y responsable por orden terminada; las tres firmas quedan registradas en `docs/MODELO_DATOS.md`.

**14 — Pruebas SQL del área.** Absorbe: pruebas de entradas (cinco casos) y de manufactura (siete casos), un archivo por regla en `supabase/tests/area1/`. Aceptación: los doce archivos corren sin `RAISE EXCEPTION` inesperado, cada uno indica qué RN verifica y el caso de costo unitario reproduce el número del ejemplo 10.2 al centavo.

**15 — Servicios del área.** Absorbe: catálogos, entradas, producción y manejo de errores. Aceptación: funciones `listarProveedores`, `crearProveedor`, `editarProveedor`, `darDeBajaProveedor` y equivalentes de almacenes; `registrarEntrada` no manda `stock`, `volumen`, `capital_inversion` ni `valor_entrada` y `listarEntradas` lee `v_entradas_detalle`; `crearOrden`, `cambiarEstadoOrden`, `capturarConsumo`, `registrarCalidad`, `cerrarOrden` exponen los errores del trigger sin tragárselos; un mensaje `RN-A1-09` se muestra como "Stock insuficiente de <materia> (disponible: n)", un `RN-A3-01` como "Stock insuficiente para <producto>" y un `CHECK` de moneda como "Indica el tipo de cambio para USD"; ningún componente llama a `supabase.from()` directo.

**16 — Módulo y catálogos.** Absorbe: módulo en la app, pantalla de proveedores y pantalla de almacenes. Aceptación: la ruta "Entradas de Producción" del menú abre el módulo y una consulta a `v_entradas_detalle` regresa datos del seed; tabla de proveedores con nombre, RFC, país, contacto y `Tag` activo/inactivo, alta y edición con validación de RFC opcional y baja lógica; tabla de almacenes con nombre, tipo y ubicación, tipo con `Tag` (`accent` para insumos, `muted` para producto terminado).

**17 — Pantalla de entradas.** Absorbe: formulario de registro y listado. Aceptación: el capital estimado se recalcula en vivo con `Mono` al cambiar costo, flete, impuestos, cantidad o tipo de cambio; al elegir USD el tipo de cambio es obligatorio; no se puede guardar sin factura del proveedor u orden de compra; las tres `KpiCard` (capital ingresado, unidades, registros del mes) coinciden con `v_entradas_detalle`; un rechazo del trigger muestra el mensaje de la tarea 15 y conserva el formulario; el stock mostrado después de guardar viene de `productos`, no del cálculo local.

**18 — Pantalla de orden de producción.** Absorbe: alta con BOM, consumo y calidad, cierre. Aceptación: al elegir el producto se muestra su BOM y el consumo teórico para la cantidad planeada, y un producto sin BOM no se puede seleccionar; los botones de consumo solo se habilitan en `EN_PROCESO` y el de calidad solo en `EN_CALIDAD`; el estado se muestra con `Tag` según la guía de estilo y la desviación mayor a 20 % aparece resaltada; tras cerrar, la pantalla muestra el costo unitario de manufactura y un enlace a la entrada generada, y la orden ya no acepta cambios.

**19 — Punta a punta.** Aceptación: capturas en `evidencias/issue-19-*.png` del ejemplo 10.1 desde la app con `v_inventario_actual` actualizado, y del ejemplo 10.2 desde la creación de la orden hasta el inventario.

**20 — Integración con las áreas 4 y 6.** Aceptación: comentario de cada líder en el issue de integración confirmando que la vista cubre lo que necesita; `v_entradas_area1` y `v_entradas_detalle` dan el mismo capital por periodo.

**21 — Cierre del área.** Absorbe: evidencias y bitácora, contexto actualizado, reporte final. Aceptación: cada issue cerrado tiene su archivo en `evidencias/` con el número de issue; `ESTADO.md` actualizado cada día al cierre con semáforo; ninguna pregunta abierta sin respuesta o sin justificación y las decisiones tomadas durante los issues están en la sección 7 o 16 de `CONTEXTO.md`; `REPORTE_FINAL.md` con la plantilla de `docs/plantillas/REPORTE_FINAL_LIDER.md`, matriz final y registro de cambios de asignación, entregado antes de las 10:00 del viernes 18.
