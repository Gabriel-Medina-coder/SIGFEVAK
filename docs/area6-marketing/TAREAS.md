# Tareas — Área 6 · Marketing

Desglose previo a los issues, derivado de `CONTEXTO.md` (ocho tablas, triggers, vistas, cinco pantallas, los dos ejemplos de la sección 10 como pruebas de aceptación) y de las integraciones I-05, I-09 e I-10 de `docs/MODELO_DATOS.md`. El líder lo revisa el domingo 13 al arrancar; después cada fila se convierte en un issue con la plantilla "Tarea" y se anota su número.

> **Antes de empezar (líder):** cada integrante agrega su línea en `docs/EQUIPOS.md` con un primer PR desde su fork y activa el hook de commit; el líder llena la matriz de habilidades en `EVALUACION.md`, asigna los roles y aplica una tarea corta de prueba (por ejemplo, la consulta que calcula `pct_ejercido` del caso A). Nada de esto es un issue de desarrollo.

Estimación: S = menos de 2 h, M = medio día, L = un día. Roles: Líder, Dev-BD, Dev-Frontend, QA-Docs, Especialista (parcial; si no hay, lo cubre QA-Docs o el líder).

| # | Título | Tipo | Nivel | Estimación | Depende de | Persona sugerida | RN | Issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Integración I-09 con el área 3: la migración base no crea `marketing` ni `clientes_marketing`; baja lógica en `productos`; lectura de `productos` y `v_rotacion` | tipo:integracion | nivel:medio | S | — | Líder | RN-A6-08 | #105 |
| 2 | Integración I-10 con el área 2: columna `activo` en `clientes`, baja lógica, `v_clientes_activos`, seed con los clientes del caso B y validación de `v_ventas_atribuidas_campana` sobre `facturas` pagadas | tipo:integracion | nivel:medio | S | — | Líder | RN-A6-07, RN-A6-08, RN-A6-14 | #106 |
| 3 | Integración I-05 con el área 4 y la coordinación: lectura de `v_desempeno_agente_zona`, respuesta a la pregunta abierta 4, tabla `usuarios` con roles `MARKETING` y `ADMINISTRADOR`, y validación de que `v_campana_resumen` y `v_costos_por_canal` alimentan el resumen general | tipo:integracion | nivel:inicial | S | — | Líder | RN-A6-05, RN-A6-06 | #107 |
| 4 | Migración de enums y catálogos: `categoria_canal`, `tipo_proveedor_marketing`, `estatus_campana`, `estado_contacto`, `tipo_investigacion`, `estado_investigacion`; `canales_marketing` y `proveedores_marketing` con `activo` y auditoría · `buena-primera-tarea` | tipo:bd | nivel:inicial | S | 1 | Dev-BD | RN-A6-01, RN-A6-09 | #108 |
| 5 | Migración de tablas de operación: `campanas`, `costos_marketing`, `metricas_marketing`, `investigaciones_mercado`, `campana_productos` y `campana_clientes` | tipo:bd | nivel:medio | L | 4, 2 | Dev-BD | RN-A6-01, RN-A6-04, RN-A6-07, RN-A6-10, RN-A6-16 | #109 |
| 6 | Índices, RLS mínima y trigger `fn_a6_set_actualizado_en` en las ocho tablas; endurecimiento opcional de RLS por rol con `fn_a6_usuario_tiene_rol` si `usuarios` está poblada el miércoles 16 | tipo:bd | nivel:inicial | S | 5 | Dev-BD | RN-A6-05, RN-A6-06, RN-A6-09 | #110 |
| 7 | Triggers de presupuesto y campaña directa: `fn_a6_validar_presupuesto` en `costos_marketing` y `fn_a6_validar_campana_directa` en `campana_clientes` | tipo:bd | nivel:avanzado | M | 5 | Dev-BD | RN-A6-02, RN-A6-03, RN-A6-11 | #111 |
| 8 | Triggers `fn_a6_bloquea_campana_cerrada` (costos y métricas) y `fn_a6_valida_activacion` (campaña directa sin clientes) | tipo:bd | nivel:avanzado | M | 5 | Dev-BD | RN-A6-13, RN-A6-15 | #112 |
| 9 | Seed `seed_area6.sql`: 6 canales, 3 proveedores, 4 campañas, clientes objetivo, 2 investigaciones; reproduce los casos A y B | tipo:pruebas | nivel:medio | M | 6, 7, 8, seed del área 2 | Especialista | RN-A6-01 a RN-A6-16 | #113 |
| 10 | Vistas de contrato `v_campana_resumen` y `v_costos_por_canal` (coordinación, resumen general) | tipo:bd | nivel:medio | M | 9 | Dev-BD | RN-A6-11, RN-A6-12 | #114 |
| 11 | Vista `v_ventas_atribuidas_campana` sobre `facturas` pagadas del área 2 | tipo:bd | nivel:avanzado | M | 9, 2 | Dev-BD | RN-A6-14 | #115 |
| 12 | Vistas internas `v_directo_desempeno` y, opcional, `v_productos_baja_rotacion_campana` sobre `v_rotacion` del área 3 | tipo:bd | nivel:medio | S | 9, 10 | Dev-BD | RN-A6-02 | #116 |
| 13 | Pruebas SQL en `supabase/tests/area6/`: caso A (presupuesto y ROI), caso B (directo y ROI real) y casos límite (campaña cerrada, `actualizado_en`, `RESTRICT`, `SET NULL`, `CHECK` de fechas) | tipo:pruebas | nivel:medio | M | 7, 8, 10, 11, 12 | QA-Docs | RN-A6-02 a RN-A6-04, RN-A6-09 a RN-A6-16 | #117 |
| 14 | Módulo del área en la app compartida: `src/modules/area6-marketing/` y ruta "Marketing" en el menú · `buena-primera-tarea` | tipo:frontend | nivel:inicial | S | app base de coordinación | Dev-Frontend | — | #118 |
| 15 | Servicios `src/services/area6/` (`campanas.js`, `costos.js`, `metricas.js`, `investigaciones.js`, `catalogos.js`, `referencias.js`) y traducción de errores de Postgres a mensajes legibles | tipo:frontend | nivel:medio | M | 14 | Dev-Frontend | RN-A6-02, RN-A6-03, RN-A6-13, RN-A6-15 | #119 |
| 16 | Pantalla 1, dashboard: seis `KpiCard`, gráfica de gasto por canal, `Panel` con `Table` de campañas recientes, filtro por fechas | tipo:frontend | nivel:medio | M | 10, 15 | Dev-Frontend | RN-A6-11, RN-A6-12 | #120 |
| 17 | Pantalla 2, campañas: listado con filtros por tipo, estado, canal y fechas; alta con formulario base | tipo:frontend | nivel:medio | M | 15 | Dev-Frontend | RN-A6-01, RN-A6-10 | #121 |
| 18 | Pantalla 2, detalle de campaña por pestañas: general, costos (alta y total vs presupuesto), métricas por periodo, clientes objetivo (solo DIRECTO) y productos promovidos | tipo:frontend | nivel:avanzado | L | 17, 2 | Dev-Frontend | RN-A6-02, RN-A6-03, RN-A6-07, RN-A6-13, RN-A6-15 | #122 |
| 19 | Pantallas 3 y 5: costos (tabla global con filtros y totales por periodo) y catálogos de canales y proveedores (rol ADMINISTRADOR, alta, edición y baja lógica) | tipo:frontend | nivel:inicial | M | 15 | Dev-Frontend | RN-A6-06 | #123 |
| 20 | Pantalla 4, investigación de mercado: listado con `Tag` por tipo y detalle con metodología, muestra, hallazgos y enlace | tipo:frontend | nivel:medio | M | 15 | Dev-Frontend | RN-A6-16 | #124 |
| 21 | Prueba de punta a punta desde la app: crear campaña directa, rechazo al activar sin clientes, agregar clientes, activar, registrar costos y contactos, ver `v_directo_desempeno` y ROI real | tipo:pruebas | nivel:medio | M | 18, 11 | QA-Docs | RN-A6-14, RN-A6-15 | #125 |
| 22 | Cierre: evidencias por issue en `evidencias/`, `ESTADO.md` diario, preguntas abiertas cerradas en `CONTEXTO.md`, reporte final y evaluación final del líder, ensayo de la demostración | tipo:docs | nivel:inicial | M | todo | Líder, QA-Docs | — | #126 |

## Integraciones que este equipo necesita de otras áreas

| Qué | De quién | Para cuándo | Issue |
| --- | --- | --- | --- |
| La migración base no crea `marketing` ni `clientes_marketing`; baja lógica en `productos` (I-09) | Área 3 / Coordinación | Dom 13 sep | # |
| Columna `activo` en `clientes`, baja lógica y `v_clientes_activos` (I-10) | Área 2 | Mar 15 sep | # |
| Seed del área 2 con los clientes que usa el caso B (Elektra Mayoreo, TechMex CDMX, Norte Digital, Distribuidora Bajío, RadioShack México) y las dos facturas `PAGADO` de los convertidos | Área 2 | Lun 14 sep | # |
| `productos` y `v_rotacion` para selector de productos y candidatos a campaña | Área 3 | Mar 15 sep | # |
| `v_desempeno_agente_zona` para dirigir campañas por zona (I-05) | Área 4 | Ya publicada | # |
| Tabla `usuarios` con roles `MARKETING` y `ADMINISTRADOR`; login y sesión | Coordinación | Sáb 12 sep (antes del arranque) | # |
| App base con menú y módulo vacío del área | Coordinación | Sáb 12 sep (antes del arranque) | # |

## Integraciones que este equipo entrega a otras áreas

| Qué | Para quién | Vía (vista) | Issue |
| --- | --- | --- | --- |
| Presupuesto, gasto, % ejercido, leads, conversiones y ROI por campaña | Coordinación (resumen general) | `v_campana_resumen` | # |
| Gasto total por canal | Coordinación (resumen general) | `v_costos_por_canal` | # |
| Desempeño del marketing directo | Área 6, Coordinación | `v_directo_desempeno` | # |
| Ventas atribuidas reales por campaña | Área 6 | `v_ventas_atribuidas_campana` | # |

## Detalle de cada tarea

**1 — Integración I-09 (área 3).** Absorbe el acuerdo sobre las tablas marcador, la baja lógica en `productos` y la lectura de `productos` y `v_rotacion` para selectores y candidatos. Aceptación: issue `tipo:integracion` con ambos líderes marcando su casilla; el acuerdo escrito en `docs/MODELO_DATOS.md`; el DDL del área 3 no crea `marketing` ni `clientes_marketing`.

**2 — Integración I-10 (área 2).** Absorbe la columna `activo`, `v_clientes_activos`, el seed del caso B y la validación de contrato de `v_ventas_atribuidas_campana`. Aceptación: issue con ambas casillas marcadas; confirmación escrita del líder del área 2 de que la vista usa correctamente `facturas` en `PAGADO` dentro de la vigencia; los cinco clientes y las dos facturas pagadas del caso B están en el seed del área 2.

**3 — Integración I-05 (área 4) y coordinación.** Absorbe la lectura de `v_desempeno_agente_zona`, la pregunta abierta 4, la tabla `usuarios` con los roles del área y la validación de las vistas del resumen general. Aceptación: la pregunta abierta 4 tiene respuesta; los roles `MARKETING` y `ADMINISTRADOR` existen en `rol_usuario`; la coordinación confirma que `v_campana_resumen` y `v_costos_por_canal` alimentan el resumen general.

**4 — Enums y catálogos.** Absorbe la migración de los seis enums y la de catálogos. Migración `AAAAMMDD_HHMM_a6_enums_catalogos.sql` con los seis tipos de la sección 8 (`tipo_marketing` y `estado_pago` se reutilizan del modelo base), `canales_marketing` (nombre único, categoría, activo) y `proveedores_marketing` (razón social, RFC, tipo, contacto, activo). Aceptación: aplica sin error; los seis tipos muestran los valores exactos de `docs/MODELO_DATOS.md`; insertar un canal con nombre repetido falla por `UNIQUE`; `creado_en` y `actualizado_en` se llenan solos.

**5 — Tablas de operación.** Absorbe campañas, costos y métricas, investigaciones y uniones. `campanas` con `tipo_marketing`, objetivo, fechas, `presupuesto_asignado`, moneda, `estatus` default `PLANEADA`, `id_responsable` y `creado_por` a `usuarios`; `costos_marketing` con FK a campaña `ON DELETE RESTRICT`, canal, proveedor opcional, `id_factura` opcional a `facturas`, `estado_pago` del enum base; `metricas_marketing` con canal opcional y `CHECK (periodo_fin >= periodo_inicio)`; `investigaciones_mercado` con `id_campana` opcional `ON DELETE SET NULL`; `campana_productos` (FK a `productos`) y `campana_clientes` (FK a `clientes`, canal, estado de contacto) con llave primaria compuesta. Aceptación: `fecha_fin < fecha_inicio` falla por `CHECK` (RN-A6-10); presupuesto negativo falla; borrar una campaña con costos falla (RN-A6-04); un costo con monto 0 falla; borrar la campaña de una investigación deja `id_campana` nulo y conserva la fila (RN-A6-16); `id_producto` o `id_cliente` inexistentes se rechazan (RN-A6-07).

**6 — Índices, RLS y `actualizado_en`.** Absorbe los once índices de la sección 8, la RLS mínima y el trigger de auditoría; incluye como sub-entregable opcional el endurecimiento por rol. Aceptación: los once índices existen con esos nombres; sin sesión ninguna tabla del área regresa filas y con sesión `authenticated` se lee y escribe; un `UPDATE` en cualquiera de las siete tablas con esa columna cambia `actualizado_en` aunque el cliente mande otro valor (RN-A6-09). Opcional, solo si `usuarios` está poblada el miércoles 16: un usuario `CAPTURISTA` lee pero no escribe, `MARKETING` escribe campañas, costos, métricas e investigaciones, y solo `ADMINISTRADOR` borra y administra catálogos (RN-A6-05, RN-A6-06).

**7 — Presupuesto y campaña directa.** Aceptación: el caso A de la sección 10: tres costos suman 45,000 y pasan; el cuarto de 7,500 falla con `RN-A6-03: el gasto total 52500.00 excede el presupuesto asignado 50000.00`; subir el presupuesto a 52,500 y reintentar pasa; insertar un cliente objetivo en una campaña `EXTERNO` falla con mensaje `RN-A6-02`.

**8 — Campaña cerrada y activación.** Aceptación: un costo o métrica en una campaña `FINALIZADA` o `CANCELADA` falla con `RN-A6-13`; pasar a `ACTIVA` una campaña `DIRECTO` sin clientes falla con `RN-A6-15`; con un cliente pasa.

**9 — Seed.** Aceptación: corre limpio sobre una base con el seed del área 2 ya cargado; deja los seis canales en las cuatro categorías, tres proveedores de tipos distintos, dos campañas `EXTERNO` y dos `DIRECTO` con una `FINALIZADA`, clientes objetivo con los cinco estados de contacto, dos investigaciones; reproduce exactos los números de los casos A y B.

**10 — Vistas de contrato.** Aceptación contra el seed: campaña del caso A con `gasto_total` 45,000.00, `presupuesto_restante` 5,000.00, `pct_ejercido` 90.00, `roi` 1.9333; `v_costos_por_canal` ordena canales por gasto descendente y muestra ceros en los sin gasto.

**11 — Ventas atribuidas.** Cruza `campana_clientes` con `facturas` en `PAGADO` cuya fecha cae en la vigencia. Aceptación: caso B con `facturas_atribuidas` 2, `ventas_atribuidas_sin_iva` 245,431.04, `gasto_total` 11,200.00, `roi_real` 20.9135.

**12 — Vistas internas.** Absorbe `v_directo_desempeno` y la vista opcional de baja rotación. Aceptación: caso B con `total_objetivo` 5, `total_contactados` 4, `total_convertidos` 2, `tasa_conversion_pct` 40.00; la opcional lista productos de `v_rotacion` bajo el umbral con las campañas que ya los promueven, y si el tiempo no alcanza se documenta como pendiente.

**13 — Pruebas SQL.** Absorbe los tres archivos de prueba. Un archivo por caso en `supabase/tests/area6/` (`caso_a.sql`, `caso_b.sql`, `casos_limite.sql`), cada uno dice qué RN verifica y falla con `RAISE EXCEPTION` si no se cumple: caso A con resumen y cuarto costo rechazado; caso B con desempeño directo, ROI real y rechazos por RN-A6-02 y RN-A6-15; límites con campaña cerrada, `actualizado_en`, `ON DELETE RESTRICT` y `SET NULL`, `CHECK` de fechas. Aceptación: corren sin excepción inesperada; salida guardada en `evidencias/`.

**14 — Módulo en la app.** Aceptación: la entrada "Marketing" del menú abre `src/modules/area6-marketing/` y una consulta a `v_campana_resumen` regresa datos del seed.

**15 — Servicios y errores.** Absorbe la capa de servicios y el manejo de errores. Aceptación: los componentes importan funciones de `src/services/area6/`, nunca el cliente crudo; ninguna función escribe `actualizado_en`, `gasto_total` ni `roi`; `referencias.js` solo lee `clientes`, `productos`, `v_clientes_activos`, `v_rotacion` y `v_desempeno_agente_zona`; exceder el presupuesto muestra "El gasto excede el presupuesto de la campaña (restante: $n)"; agregar cliente a campaña externa muestra "Solo las campañas directas tienen clientes objetivo"; sin errores crudos de Postgres en pantalla.

**16 — Dashboard.** Seis `KpiCard` (presupuesto del periodo, gasto ejercido, % ejercido, leads, conversiones, ROI promedio), `Panel` con la gráfica de barras del repo alimentada por `v_costos_por_canal`, `Panel` con `Table` de campañas recientes con `Tag` de tipo y `StatusBadge` de estado, filtro por rango de fechas. Aceptación: todos los números vienen de las vistas; ninguno se calcula en el cliente; sin colores en hex fuera de los tokens.

**17 — Listado y alta de campañas.** Aceptación: filtros por tipo, estado, canal y fechas funcionan combinados; "+ Nueva campaña" en la topbar abre el formulario base; una campaña con `fecha_fin` anterior se rechaza antes de tocar la base.

**18 — Detalle por pestañas.** Absorbe las pestañas general, costos, métricas, clientes objetivo y productos promovidos. Aceptación: la pestaña de costos muestra total vs presupuesto en `Mono` y el alta de un costo que excede muestra el mensaje de la tarea 15 sin perder lo capturado; la pestaña de métricas lista por periodo con `fuente_dato`; la pestaña de clientes solo aparece en campañas `DIRECTO`, el selector lee `v_clientes_activos` (o `clientes` con `activo` mientras no exista la vista) y cada cliente muestra `StatusBadge` con su estado de contacto editable; el selector de productos lee `productos`.

**19 — Costos y catálogos.** Absorbe las pantallas 3 y 5. Aceptación: tabla global de costos con filtros por proveedor, canal y campaña combinados, totales por mes y montos en `Mono`; catálogos con alta, edición y "Dar de baja" (pone `activo = false`, nunca `DELETE`), un canal inactivo desaparece de los selectores pero sigue en el listado con `Tag` "inactivo", y la pantalla solo aparece para rol `ADMINISTRADOR`.

**20 — Investigación.** Aceptación: listado con `Tag` por tipo y `StatusBadge` por estado; detalle con metodología, tamaño de muestra, hallazgos y enlace a `url_reporte`; una investigación sin campaña se muestra como independiente.

**21 — Punta a punta.** Crear campaña `DIRECTO`, intentar activar sin clientes (rechazo), agregar cinco clientes, activar, registrar dos costos y los contactos del caso B, ver `v_directo_desempeno` y `v_ventas_atribuidas_campana` en pantalla. Aceptación: capturas de cada paso en `evidencias/`; sin errores no controlados en consola.

**22 — Cierre.** Absorbe evidencias, estado, contexto y reporte. Aceptación: cada issue cerrado tiene su archivo en `evidencias/` con el número de issue en el nombre; `ESTADO.md` actualizado todos los días al cierre; las ocho preguntas abiertas con respuesta o justificación; `REPORTE_FINAL.md` con la plantilla de `docs/plantillas/REPORTE_FINAL_LIDER.md` entregado antes de las 14:00 del jueves 17; ensayo de la demostración hecho.
