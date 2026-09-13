# Tareas — Área 2 · Contabilidad y facturación

Desglose previo a los issues, a partir de los 25 issues que definió el equipo (identificador original `AREA2-XX` entre paréntesis) más las tareas que salen de las integraciones con las áreas 4, 5 y 6. El líder lo revisa el domingo 13 (día 1); después cada fila se convierte en un issue con la plantilla "Tarea" y se anota su número.

> **Antes de empezar (líder):** cada integrante agrega su nombre y usuario a `docs/EQUIPOS.md` en su primer PR desde su fork; el líder llena la sección 1 de `EVALUACION.md` con la matriz de habilidades, una tarea corta y los roles, y lo anota en la bitácora de `ESTADO.md` del domingo 13. Ninguna de las dos cosas es un issue de desarrollo. Calendario: dom 13 arranque y acuerdos; lun 14 base de datos; mar 15 vistas, servicios y pantalla de comercializadores; mié 16 facturación, pagos e integración con congelamiento a las 18:00; jue 17 cierre y entrega.

Estimación: S = menos de 2 h, M = medio día, L = un día. Roles: Líder, Modelador, FE-Clientes, FE-Facturación, Docs.

> **Adaptado:** el equipo usaba etiquetas propias (`schema`, `trigger`, `rls`, `frontend`, `reporte`, `auth`, `qa`, `docs`). Se mapean a las etiquetas globales del repo: `tipo:bd`, `tipo:frontend`, `tipo:pruebas`, `tipo:docs`, `tipo:integracion`. Los issues de autenticación (AREA2-08, AREA2-09) los hace la coordinación: Supabase Auth y la tabla global `usuarios` son compartidos por las seis áreas; el área 2 solo verifica que sin sesión no lee ni escribe.

Las tareas marcadas con ★ son `buena-primera-tarea`: se resuelven siguiendo el contexto paso a paso y sirven como primer PR.

| # | Título | Tipo | Nivel | Estimación | Depende de | Persona sugerida | RN | Issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Integración con el área 3: confirmar el esquema base compartido (AREA2-01) y definir si cancelar una factura reintegra stock (pregunta abierta 2) | tipo:integracion | nivel:inicial | S | — | Líder | RN-A2-01 | #41 |
| 2 | Integración con el área 4: acordar `fecha_cobro`, `fecha_vencimiento`, `v_cartera_agente` (I-02) y el seed único de agentes; confirmar al final que las vistas cubren lo que necesita (AREA2-25) | tipo:integracion | nivel:medio | S | 1 | Líder | RN-A2-08, RN-A2-09 | #42 |
| 3 | Integración con el área 5: acordar `v_iva_trasladado_periodo` y `uuid_cfdi` (I-07) y confirmar al final (AREA2-25) | tipo:integracion | nivel:inicial | S | 1 | Líder | — | #43 |
| 4 | Integración con el área 6: acordar baja lógica y `v_clientes_activos` (I-10) y confirmar al final (AREA2-25) | tipo:integracion | nivel:inicial | S | 1 | Líder | RN-A2-10 | #44 |
| 5 | Migración aditiva: columnas nuevas en `clientes` y `facturas`, secuencias, índices, `CHECK` de RFC y RLS en ambas tablas (AREA2-03) ★ | tipo:bd | nivel:medio | M | 1 | Modelador | RN-A2-05, RN-A2-09, RN-A2-10, RN-A2-11 | #45 |
| 6 | Función `fn_tasa_iva()`, triggers de folios (`fn_folio_cliente`, `fn_folio_factura`) y `fn_valida_factura` (cliente activo y vencimiento por días de crédito) | tipo:bd | nivel:medio | M | 5 | Modelador | RN-A2-03, RN-A2-09, RN-A2-10, RN-A2-11 | #46 |
| 7 | Trigger `fn_recalcular_factura` sobre `detalle_factura` (AREA2-02) | tipo:bd | nivel:avanzado | M | 5 | Modelador | RN-A2-02, RN-A2-03 | #47 |
| 8 | Triggers de estado: `fn_estado_pago_factura` (`fecha_cobro` automática, bloqueo de `PAGADO` con total 0) y `fn_bloquea_detalle_cerrado` (renglones inmutables en `PAGADO`/`CANCELADO`) | tipo:bd | nivel:medio | M | 5 | Modelador | RN-A2-04, RN-A2-08, RN-A2-12 | #48 |
| 9 | Vistas del equipo: `v_clientes_resumen`, `v_facturas_pendientes`, `v_ventas_agente` (AREA2-04) | tipo:bd | nivel:medio | M | 7, 8 | Modelador | — | #49 |
| 10 | Vistas de contrato: `v_cartera_agente` (área 4), `v_iva_trasladado_periodo` (área 5), `v_clientes_activos` (área 6); verificar que `v_salidas_area2` no cambia | tipo:bd | nivel:medio | M | 9 | Modelador | RN-A2-09, RN-A2-10 | #50 |
| 11 | Seed `seed_area2.sql`: 10 clientes, 4 agentes coordinados con el área 4, 15 facturas, caso de stock insuficiente (AREA2-21) | tipo:pruebas | nivel:medio | M | 5, 7 | Docs | — | #51 |
| 12 | Pruebas SQL del área en `supabase/tests/area2/`: recálculo (AREA2-22), estado de pago, folios, vencimiento, baja lógica, factura cerrada, RFC | tipo:pruebas | nivel:medio | M | 7, 8, 11 | Modelador | RN-A2-02 a RN-A2-12 | #52 |
| 13 | Módulo del área en la app compartida (`src/modules/area2-contabilidad/`, ruta en el menú) y servicios `src/services/area2/clientes.js` y `facturas.js` con manejo centralizado de errores de Postgres (AREA2-05, AREA2-06, AREA2-07) ★ | tipo:frontend | nivel:medio | M | app base de coordinación | FE-Facturación | RN-A2-06 | #53 |
| 14 | Pantalla de comercializadores: listado con buscador desde `v_clientes_resumen`, alta y edición con validación de RFC y días de crédito, baja lógica, `KpiCard` de número de comercializadores (AREA2-10, AREA2-11, AREA2-12) | tipo:frontend | nivel:medio | L | 9, 13 | FE-Clientes | RN-A2-05, RN-A2-10 | #54 |
| 15 | Formulario de nueva factura: cabecera con cliente activo y agente obligatorios, selector de productos con stock y renglones con subtotal en vivo, guardado con manejo del rechazo por stock sin perder lo capturado (AREA2-13, AREA2-14, AREA2-15) | tipo:frontend | nivel:avanzado | L | 13 | FE-Facturación | RN-A2-01, RN-A2-06, RN-A2-10 | #55 |
| 16 | Detalle de factura y cambio de estado de pago: cabecera, renglones, subtotal, IVA, total, fechas y estado; acción entre estados con RN-A2-04 validada en frontend y `fecha_cobro` puesta por el trigger (AREA2-16, AREA2-18) | tipo:frontend | nivel:medio | M | 15 | FE-Facturación | RN-A2-02, RN-A2-04, RN-A2-08 | #56 |
| 17 | Listado de facturas pendientes con filtros y días vencidos desde `v_facturas_pendientes` (AREA2-17) | tipo:frontend | nivel:inicial | M | 9, 13 | FE-Facturación | RN-A2-09 | #57 |
| 18 | Dashboard del área: 4 `KpiCard` (comercializadores, facturado del mes, pendiente, vencido), top 5 comercializadores y exportación de `v_ventas_agente` a CSV (AREA2-19, AREA2-20) | tipo:frontend | nivel:medio | M | 9, 14 | FE-Clientes | — | #58 |
| 19 | Pruebas de punta a punta: login → cliente → factura → rechazo por stock → pagada; capturas en `evidencias/` (AREA2-23) | tipo:pruebas | nivel:medio | M | 15, 16 | Docs | — | #59 |
| 20 | Cierre del área: evidencias por issue, `ESTADO.md` diario, `CONTEXTO.md` actualizado con los acuerdos reales y preguntas abiertas cerradas (AREA2-24), reporte final y evaluación final del equipo | tipo:docs | nivel:inicial | M | todo | Líder, Docs | — | #60 |

## Integraciones que este equipo necesita de otras áreas

| Qué | De quién | Para cuándo | Issue |
| --- | --- | --- | --- |
| Tablas base `clientes`, `facturas`, `detalle_factura` creadas en la migración base con las columnas del modelo aprobado | Área 3 / Coordinación | Sáb 12 sep (coordinación) | # |
| Trigger `fn_salida_producto` (valida y descuenta stock) aplicado antes que el recálculo del área 2 | Área 3 | Lun 14 sep | # |
| Catálogo `agentes_ventas` con seed único (no duplicar agentes entre áreas 2 y 4) | Área 4 | Lun 14 sep | # |
| Definición de devolución para reintegrar stock al cancelar (pregunta abierta 2) | Área 3 | Dom 13 sep (decisión) | # |
| `productos.precio_venta_sugerido` para precargar el precio unitario (pregunta abierta 7) | Área 1 | Mar 15 sep | # |
| Login, sesión y tabla `usuarios` | Coordinación | Sáb 12 sep (coordinación) | # |

## Integraciones que este equipo entrega a otras áreas

| Qué | Para quién | Vía (vista) | Issue |
| --- | --- | --- | --- |
| Facturas pagadas con `fecha_cobro`, `subtotal` sin IVA e `id_agente` (I-02) | Área 4 | Columnas de `facturas`; el área 4 las lee con `v_ventas_cobradas_agente` | # |
| Cartera vencida por agente para el bono de cobranza sana (I-02) | Área 4 | `v_cartera_agente` | # |
| IVA trasladado y facturas con CFDI por mes (I-07) | Área 5 | `v_iva_trasladado_periodo` | # |
| Clientes activos y garantía de baja lógica (I-10) | Área 6 | `v_clientes_activos`, `clientes` solo lectura | # |
| Unidades y monto facturado por cliente | Áreas 3, 4 | `v_salidas_area2` (definida por el área 3, mantenida por el área 2) | # |
| Número de comercializadores, facturado del mes, pendiente | Coordinación (resumen general) | `v_clientes_resumen`, `v_facturas_pendientes` | # |

## Detalle de cada tarea (criterios de aceptación del equipo)

Los criterios son los que escribió el equipo; se conservan con su identificador original.

**1 — Integración con el área 3.** Absorbe: confirmar y aplicar el esquema base compartido (AREA2-01) y la decisión sobre devoluciones. Aceptación: `clientes`, `facturas`, `agentes_ventas`, `productos` y `detalle_factura` existen en el proyecto Supabase tal como en `docs/area3-inventario/CONTEXTO.md` sección 10, con los `CHECK` y `UNIQUE` del modelo aprobado activos; issue de integración con ambos líderes marcando su casilla y la respuesta a la pregunta abierta 2 registrada en `CONTEXTO.md`.

**2, 3, 4 — Integraciones con las áreas 4, 5 y 6 (I-02, I-07, I-10; AREA2-25).** Absorben: apertura del acuerdo y confirmación final de cada contraparte. Aceptación: issue `tipo:integracion` por área con ambos líderes marcando su casilla; columnas y vistas registradas en `docs/MODELO_DATOS.md`; comentario del líder contraparte confirmando que la vista cubre lo que necesita; en la tarea 2, además, el seed de `agentes_ventas` acordado con el área 4.

**5 — Migración aditiva y RLS.** Absorbe: columnas, secuencias, índices, `CHECK` de RFC y RLS (AREA2-03). Aceptación: la migración `AAAAMMDD_HHMM_a2_columnas_aditivas.sql` aplica sobre la base del área 3 sin error; un usuario no autenticado no puede leer ni escribir `clientes` ni `facturas`; uno autenticado sí.

**6 — Tasa de IVA, folios y validación de factura.** Absorbe: `fn_tasa_iva()`, `fn_folio_cliente`, `fn_folio_factura`, `fn_valida_factura`. Aceptación: un insert en `clientes` recibe `COM-000001`; un insert en `facturas` recibe `FAC-000001` y, sin `fecha_vencimiento`, la recibe como `fecha + dias_credito`; un cliente con `activo = false` no puede recibir facturas; `fn_tasa_iva()` es el único lugar donde vive el 0.16.

**7 — Trigger de recálculo de `subtotal`, `iva` y `valor_total` (AREA2-02).** Crear `fn_recalcular_factura()` y `tg_recalcular_factura` sobre `detalle_factura` (AFTER INSERT/UPDATE/DELETE). Aceptación: insertar, editar o borrar un renglón actualiza los tres campos de la factura sin intervención del frontend.

**8 — Triggers de estado.** Absorbe: `fn_estado_pago_factura` y `fn_bloquea_detalle_cerrado`. Aceptación: marcar `PAGADO` llena `fecha_cobro` con la fecha del día; regresar a `PENDIENTE` la limpia; marcar `PAGADO` una factura con `valor_total = 0` falla con mensaje `RN-A2-04`; cualquier insert, update o delete en `detalle_factura` de una factura `PAGADO` o `CANCELADO` falla con mensaje `RN-A2-12`.

**9 — Vistas del equipo (AREA2-04).** Crear `v_clientes_resumen`, `v_facturas_pendientes` y `v_ventas_agente`. Aceptación: las tres regresan datos correctos contra el seed (mínimo 10 clientes, 15 facturas).

**10 — Vistas de contrato.** Aceptación: `v_cartera_agente` da el porcentaje vencido del ejemplo de la sección 10; `v_iva_trasladado_periodo` suma el IVA del mes excluyendo canceladas; `v_clientes_activos` excluye al cliente inactivo del seed; `v_salidas_area2` sigue devolviendo lo mismo que antes de la migración.

**11 — Seed (AREA2-21).** Al menos 10 clientes, 4 agentes de referencia y 15 facturas con renglones variados, incluyendo casos de stock insuficiente. Aceptación: corre limpio contra una base vacía y deja el escenario listo para QA; reproduce el ejemplo de la sección 10 y el de `docs/area4-nomina/CONTEXTO.md` sección 10.

**12 — Pruebas SQL del área.** Absorbe: pruebas del recálculo (AREA2-22: insertar un renglón, editar su cantidad, borrar un renglón, borrar la última línea dejando `valor_total = 0`) y las pruebas restantes de la tabla 8.10 del contexto (estado de pago, folios, vencimiento, baja lógica, factura cerrada, RFC), un archivo por regla. Aceptación: los cuatro casos de recálculo dejan `subtotal`, `iva`, `valor_total` correctos verificado en Supabase; los demás archivos corren sin `RAISE EXCEPTION` inesperado.

**13 — Módulo, servicios y errores.** Absorbe: módulo del área en la app compartida (AREA2-05 adaptado), capa de servicios (AREA2-06) y manejo centralizado de errores (AREA2-07). Aceptación: la ruta "Registro Contable" del menú abre `src/modules/area2-contabilidad/` y una consulta a `v_clientes_resumen` regresa datos; todas las llamadas a `supabase-js` viven en `src/services/area2/clientes.js` y `facturas.js`, los componentes importan funciones de `services/` y nunca el cliente crudo, y ningún servicio manda `subtotal`, `iva`, `valor_total`, `fecha_cobro` ni folios; facturar más unidades de las que hay muestra "Stock insuficiente para <producto> (disponible: n)" en vez de un error crudo y un RFC duplicado muestra "Ya existe un comercializador con ese RFC".

**14 — Pantalla de comercializadores.** Absorbe: listado (AREA2-10), alta y edición (AREA2-11), baja lógica y KPI (AREA2-12). Aceptación: tabla con folio, nombre, RFC, estado, facturado y pendiente desde `v_clientes_resumen`, buscador por nombre y `Tag` activo/inactivo, que refleja el seed y se actualiza tras un alta; formulario con validación de RFC (regex 12 o 13 caracteres, RN-A2-05) y días de crédito que rechaza un RFC mal formado o duplicado en el frontend antes de tocar la BD; "Dar de baja" pone `activo = false`, el cliente desaparece de selectores y de `v_clientes_activos` pero sigue en el listado con `Tag` "inactivo" y conserva sus facturas; `KpiCard` con el conteo de clientes activos que coincide con `COUNT(*) FROM clientes WHERE activo`.

**15 — Formulario de nueva factura.** Absorbe: cabecera (AREA2-13), renglones (AREA2-14), guardado y rechazo por stock (AREA2-15). Aceptación: selector de cliente (solo activos) y de agente, sin poder continuar a renglones sin ambos (RN-A2-01), y al guardar la cabecera se muestran el folio y la fecha de vencimiento que asignó el sistema; buscador de producto mostrando `stock`, cantidad, precio unitario e importe en vivo, con subtotal, IVA y total marcados como "estimado" hasta guardar; un intento fallido por stock no borra el formulario, el usuario corrige y reintenta, y los totales mostrados después de guardar vienen de `facturas`, no del cálculo local.

**16 — Detalle de factura y estado de pago.** Absorbe: vista de detalle (AREA2-16) y cambio de estado (AREA2-18). Aceptación: pantalla de solo lectura con folio, cliente, agente, fecha, vencimiento, cobro, renglones, subtotal, IVA, total y estado con `Tag`, con montos que vienen de `facturas`/`detalle_factura` y nunca se recalculan en el frontend; acción entre `PENDIENTE`, `PARCIAL`, `PAGADO`, `CANCELADO` con RN-A2-04 validada en el frontend antes del update y por el trigger después; al pasar a `PAGADO` el detalle muestra la `fecha_cobro` que puso el trigger.

**17 — Facturas pendientes (AREA2-17).** Tabla desde `v_facturas_pendientes` con filtro por cliente y rango de fechas; `dias_vencidos` en rojo si es mayor a 0. Aceptación: una factura marcada `PAGADO` desaparece del listado sin recargar manualmente.

**18 — Dashboard y exportación.** Absorbe: dashboard (AREA2-19) y CSV (AREA2-20). Aceptación: `KpiCard` de comercializadores, facturado del mes, pendiente de cobro y cartera vencida, más `Panel` con top 5 comercializadores por monto, todos con números que provienen de `v_clientes_resumen` y `v_facturas_pendientes` y ninguno calculado en el cliente; botón que exporta `v_ventas_agente` a CSV y el archivo coincide con la vista en Supabase.

**19 — Pruebas de punta a punta (AREA2-23).** Desde login hasta factura pagada, incluyendo rechazo por stock. Aceptación: el flujo completo corre sin errores no controlados en consola; capturas en `evidencias/issue-19-*.png`.

**20 — Cierre del área.** Absorbe: evidencias y bitácora, contexto actualizado (AREA2-24), reporte final. Aceptación: cada issue cerrado tiene su archivo en `evidencias/` con el número de issue y `ESTADO.md` se actualiza cada día al cierre con semáforo; ninguna pregunta abierta queda sin respuesta o sin justificación de por qué se pospuso; `REPORTE_FINAL.md` con la plantilla de `docs/plantillas/REPORTE_FINAL_LIDER.md`, matriz final y registro de cambios de asignación, entregado antes de las 10:00 del viernes 18.
