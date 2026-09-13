# Tareas — Área 4 · Nómina de agentes

Desglose previo a los issues, derivado de `docs/area4-nomina/CONTEXTO.md` (secciones 5, 8, 9, 10 y 12), del alcance mínimo de `docs/CRONOGRAMA.md` y de las integraciones I-02, I-03, I-05, I-06 e I-12 de `docs/MODELO_DATOS.md`. El líder lo revisa el sábado 12; después cada fila se convierte en un issue con la plantilla "Tarea" y se anota su número.

Estimación: S = menos de 2 h, M = medio día, L = un día. Roles: Líder, Analista (negocio y normativa), DBA (modelador), Dev (desarrollador), QA-Docs.

> **Antes de empezar (líder y analista, domingo 13, día 1):** cada integrante agrega su línea en `docs/EQUIPOS.md` por PR con su fork configurado; el líder llena `EVALUACION.md` sección 1 con la tarea corta de prueba (consulta que calcula el % de cumplimiento del ejemplo de la sección 10) y los roles; el analista valida con el equipo las reglas RN-A4-01 a RN-A4-18 y los ocho valores legales de la sección 2.2, y deja escrita la decisión sobre INFONAVIT (pregunta 4), tope del art. 110 (pregunta 6) y quincenas automáticas (pregunta 8). Esto no son issues de desarrollo.

Orden por día (5 días, domingo 13 a jueves 17): dom 13 arranque, acuerdos I-02, I-03 e I-12 y asignación; lun 14 catálogos, tablas, seed, funciones base y pruebas SQL; mar 15 vistas, servicios y pantallas de catálogos; mié 16 cálculo, nómina, estados, recibo, pruebas e integración (congelamiento 18:00); jue 17 correcciones, evidencias y cierre. El sábado 12 es de coordinación; el viernes 18 no forma parte del plan.

| # | Título | Tipo | Nivel | Estimación | Depende de | Persona sugerida | RN | Issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Integración con el área 2: `fecha_cobro`, `subtotal`, `fecha_vencimiento`, `v_cartera_agente` (I-02) y seed único de `agentes_ventas` (I-12) | tipo:integracion | nivel:medio | S | — | Líder + Analista | RN-A4-02, RN-A4-06, RN-A4-07 | #61 |
| 2 | Integración con el área 5: tasas de ISN por entidad en `v_tasas_isn` y confirmación de que `v_retenciones_area5` cubre lo que necesita (I-03) | tipo:integracion | nivel:inicial | S | — | Líder | RN-A4-16 | #62 |
| 3 | Integración con las áreas 6 y 1: confirmar `v_desempeno_agente_zona` con marketing (I-05) y documentar `v_mano_obra_produccion` como insumo futuro de bonos (I-06) | tipo:integracion | nivel:inicial | S | 10 | Líder | — | #63 |
| 4 | Migración a4: enums, catálogos `zonas`, `esquemas_compensacion`, `tramos_comision` y trigger de tramos sin traslapes — `buena-primera-tarea` | tipo:bd | nivel:medio | M | — | DBA | RN-A4-04 | #64 |
| 5 | Migración a4: ampliación aditiva de `agentes_ventas`, tablas de operación (`metas`, `bonos_catalogo`, `periodos_nomina`, `bonos_asignados`, `nomina_detalle`, `ajustes_comision`, `parametros_legales`, `bitacora_nomina`), índices y RLS | tipo:bd | nivel:medio | L | 4 | DBA | RN-A4-01, RN-A4-02, RN-A4-03, RN-A4-08, RN-A4-09, RN-A4-12, RN-A4-13, RN-A4-14 | #65 |
| 6 | Seed legal (SM, UMA, factor 30.4, tope art. 110, cuota IMSS, tarifa ISR en JSONB) y seed de negocio (bonos, esquema con tramos, zonas, agentes, metas, periodos) | tipo:bd | nivel:avanzado | L | 5, 1 | Analista + QA-Docs | RN-A4-02, RN-A4-03, RN-A4-14 | #66 |
| 7 | `fn_parametro(clave, entidad, fecha)` y trigger `fn_valida_salario_minimo` | tipo:backend | nivel:medio | M | 6 | DBA | RN-A4-01, RN-A4-14 | #67 |
| 8 | Estados del periodo: `fn_transicion_periodo` (orden, retroceso con comentario, separación de funciones) y `fn_bloquea_periodo_cerrado` | tipo:backend | nivel:avanzado | M | 5 | DBA | RN-A4-13, RN-A4-15, RN-A4-18 | #68 |
| 9 | Vistas sobre `facturas` del área 2: `v_ventas_cobradas_agente`, `v_clientes_nuevos_agente`, `v_cumplimiento_meta` | tipo:bd | nivel:medio | M | 1, 6 | DBA | RN-A4-06, RN-A4-07 | #69 |
| 10 | Vistas de contrato `v_retenciones_area5` (I-03) y `v_desempeno_agente_zona` (I-05), firmas en `docs/MODELO_DATOS.md` | tipo:bd | nivel:medio | S | 9 | DBA | RN-A4-16 | #70 |
| 11 | Vistas `v_recibo_nomina`, `v_nomina_totales`, `v_sbc_bimestral` | tipo:bd | nivel:medio | S | 5 | DBA | RN-A4-10, RN-A4-11 | #71 |
| 12 | Servicios `src/services/area4/` (agentes, catálogos, metas, periodos) y manejo centralizado de errores de Postgres | tipo:frontend | nivel:medio | M | app base de coordinación, 5 | Dev | — | #72 |
| 13 | Módulo del área en la app compartida: carpeta, ruta "Nómina y Personal" y 4 `KpiCard` del dashboard — `buena-primera-tarea` | tipo:frontend | nivel:inicial | S | 12 | Dev | — | #73 |
| 14 | Pantalla de agentes: listado con `Table` y `Tag` de estatus, alta y edición con zona, esquema, salario diario y entidad | tipo:frontend | nivel:medio | M | 12, 7 | Dev | RN-A4-01, RN-A4-02 | #74 |
| 15 | Pantallas de catálogos (zonas, esquemas, tramos; solo ADMINISTRADOR) y de metas por agente y periodo con cumplimiento en vivo | tipo:frontend | nivel:medio | M | 12, 9 | Dev | RN-A4-03, RN-A4-04 | #75 |
| 16 | `fn_calcular_periodo(id_periodo, usuario)`: cumplimiento, tramo, comisión, cinco bonos; y `fn_aplicar_ajustes` con tope del art. 110 | tipo:backend | nivel:avanzado | L | 7, 8, 9 | DBA | RN-A4-02, RN-A4-03, RN-A4-05, RN-A4-06, RN-A4-08, RN-A4-09, RN-A4-17 | #76 |
| 17 | `fn_calcular_nomina(id_periodo)`: percepciones, gravado y exento, ISR art. 96, IMSS obrero, ISN por entidad, INFONAVIT | tipo:backend | nivel:avanzado | L | 16, 2 | DBA + Analista | RN-A4-10, RN-A4-12, RN-A4-14, RN-A4-16 | #77 |
| 18 | Pantalla de periodo: abrir, calcular, revisar, autorizar, pagar y cerrar con botones según rol y comentario en rechazo | tipo:frontend | nivel:avanzado | M | 12, 16, 17 | Dev | RN-A4-13, RN-A4-15 | #78 |
| 19 | Recibo por agente con claves SAT, layout CSV de dispersión y reportes (nómina del periodo, comisiones por agente y zona, costo de compensación) | tipo:frontend | nivel:medio | M | 11, 10, 18 | Dev | RN-A4-12 | #79 |
| 20 | Pruebas SQL en `supabase/tests/area4/`: salario mínimo, tramos, transición de estados, separación de funciones, periodo cerrado | tipo:pruebas | nivel:medio | M | 7, 8 | QA-Docs | RN-A4-01, RN-A4-04, RN-A4-13, RN-A4-15, RN-A4-18 | #80 |
| 21 | Pruebas de aceptación y de punta a punta: ejemplo de la sección 10 exacto, paralelo contra Excel con casos límite, y flujo completo desde la app con dos usuarios | tipo:pruebas | nivel:avanzado | L | 6, 16, 17, 18, 19 | Analista + QA-Docs | RN-A4-03, RN-A4-05, RN-A4-06, RN-A4-08, RN-A4-09, RN-A4-10, RN-A4-15 | #81 |
| 22 | Cierre: contexto actualizado con los acuerdos, evidencias por issue, `ESTADO.md` diario, reasignaciones en `EVALUACION.md`, reporte final y evaluación final | tipo:docs | nivel:inicial | M | todo | Líder + QA-Docs | — | #82 |

## Integraciones que este equipo necesita de otras áreas

| Qué | De quién | Para cuándo | Issue |
| --- | --- | --- | --- |
| `facturas` con `fecha_cobro`, `subtotal` sin IVA, `fecha_vencimiento` e `id_agente` obligatorio; vista `v_cartera_agente` para el bono de cobranza sana (I-02) | Área 2 | Lun 14 sep | # |
| Tasas de ISN por entidad en `v_tasas_isn` (I-03) | Área 5 | Mar 15 sep | # |
| Seed único de `agentes_ventas` (I-12) | Área 2 | Lun 14 sep | # |
| `v_mano_obra_produccion` para bonos de productividad, solo lectura (I-06) | Área 1 | Mar 15 sep | # |
| Tabla `usuarios` con `rol` para separación de funciones; login y sesión | Coordinación | Sáb 12 sep (coordinación) | # |
| `agentes_ventas` base creada en la migración base con las 4 columnas del modelo aprobado | Área 3 / Coordinación | Sáb 12 sep (coordinación) | # |

## Integraciones que este equipo entrega a otras áreas

| Qué | Para quién | Vía (vista) | Issue |
| --- | --- | --- | --- |
| ISR retenido, IMSS obrero y base de ISN por entidad y periodo (I-03) | Área 5 | `v_retenciones_area5` | # |
| Cumplimiento y ventas cobradas por agente y zona (I-05) | Área 6 | `v_desempeno_agente_zona` | # |
| Nómina total del periodo, agentes activos, bono promedio, próximo pago | Coordinación (resumen general) | `v_nomina_totales`, `v_cumplimiento_meta` | # |

## Detalle de cada tarea

**1 — Integración con el área 2 (I-02, I-12).** Absorbe: acuerdo de columnas y vista de cartera; acuerdo de seed único de agentes. Aceptación: issue `tipo:integracion` con ambos líderes marcando su casilla; `fecha_cobro`, `subtotal`, `fecha_vencimiento` y `v_cartera_agente` confirmados como suficientes para RN-A4-06, RN-A4-07 y el bono de cobranza sana; un solo archivo de seed de `agentes_ventas` acordado; todo registrado en `docs/MODELO_DATOS.md`.

**2 — Integración con el área 5 (I-03).** Absorbe: carga de tasas de ISN y confirmación de `v_retenciones_area5`. Aceptación: `v_tasas_isn` publicada por el área 5 con la tasa por entidad; Ivan confirma en el issue que `v_retenciones_area5` (ISR e IMSS obrero por entidad de periodos AUTORIZADO, PAGADO o CERRADO) es lo que necesita para crear la obligación bimestral.

**3 — Integración con las áreas 6 y 1 (I-05, I-06).** Aceptación: César confirma en el issue que `v_desempeno_agente_zona` (zona, región, agente, periodo, cumplimiento, ventas cobradas) cubre lo que marketing necesita; consulta de prueba a `v_mano_obra_produccion` del área 1 documentada en el contexto como insumo futuro sin cambiar el cálculo actual.

**4 — Migración de enums, catálogos y trigger de tramos.** Absorbe: tipos `zona_salarial`, `estatus_agente`, `periodicidad`, `tipo_periodo`, `estatus_periodo`, `tipo_concepto`; tablas `zonas`, `esquemas_compensacion`, `tramos_comision` con CHECK de rango y tasa; trigger que impide tramos traslapados o con huecos. Archivos `AAAAMMDD_HHMM_a4_*.sql` con encabezado de área, issue y RN. Aceptación: aplica sin error; los CHECK rechazan `pct_max <= pct_min` y `tasa >= 1`; insertar un tramo 60–80 en un esquema que ya tiene 70–99.99 falla; el esquema del seed cubre de 0 en adelante sin huecos.

**5 — Migración de ampliación, tablas de operación, índices y RLS.** Absorbe: columnas aditivas de `agentes_ventas` (rfc, curp, nss, fecha_ingreso, id_zona, id_esquema, salario_diario, entidad_federativa, clabe, estatus); `metas`, `bonos_catalogo`, `periodos_nomina`, `bonos_asignados`, `nomina_detalle`, `ajustes_comision`, `parametros_legales`, `bitacora_nomina`; índices; RLS en las once tablas. Aceptación: `supabase db reset` aplica todo sin error sobre la base del área 3; las columnas nuevas de `agentes_ventas` son opcionales o con default y un INSERT con solo `nombre` sigue funcionando; los CHECK rechazan `monto_meta <= 0`, un bono manual sin `autorizado_por`, y `gravado + exento <> monto` en una percepción; sin sesión ninguna tabla del área regresa filas y con sesión `authenticated` se lee y escribe.

**6 — Seed legal y de negocio.** Absorbe: parámetros legales y datos de prueba del negocio. Aceptación: `fn_parametro('SM_GENERAL', NULL, '2026-09-18')` devuelve 315.04; `SM_ZLFN` 440.87; `UMA_DIARIA` 117.31; `UMA_MENSUAL` 3566.22; `FACTOR_DIAS_MES` 30.4; `TARIFA_ISR_MENSUAL` devuelve la tabla completa del art. 96 en JSONB con límite inferior, superior, cuota fija y porcentaje por renglón; cada valor con `vigencia_inicio` y fuente en comentario; 5 bonos con las claves `META`, `CLIENTE_NUEVO`, `COBRANZA_SANA`, `PUNTUALIDAD`, `TRIMESTRAL`; 1 esquema con tramos 0–69.99 / 70–99.99 / 100–119.99 / 120+; 3 zonas de las cuales una es ZLFN; 5 agentes con RFC, zona, esquema y salario ≥ mínimo; metas del mes; facturas coordinadas con el seed del área 2 para que el agente del ejemplo tenga $560,000 cobrados sin IVA, 2 clientes nuevos y cartera vencida del 3 %.

**7 — `fn_parametro` y salario mínimo.** Absorbe: función de parámetro vigente y trigger de validación. Aceptación: `fn_parametro` devuelve el parámetro vigente en la fecha pedida, prefiere el de la entidad cuando existe y el federal cuando no, y con dos vigencias devuelve la más reciente que no exceda la fecha; un agente en zona GENERAL con `salario_diario = 300` es rechazado con mensaje `RN-A4-01` y con 350 pasa; en ZLFN con 400 es rechazado y con 440.87 pasa.

**8 — Estados del periodo.** Absorbe: `fn_transicion_periodo` y `fn_bloquea_periodo_cerrado`. Aceptación: ABIERTO → CALCULADO → REVISADO → AUTORIZADO → PAGADO → CERRADO en orden; saltar un estado falla; regresar a ABIERTO exige `comentario`; `autorizado_por` igual a `calculado_por` falla con mensaje `RN-A4-15`; cualquier INSERT, UPDATE o DELETE en `nomina_detalle` o `bonos_asignados` de un periodo PAGADO o CERRADO falla con mensaje `RN-A4-18`.

**9 — Vistas sobre facturas.** Aceptación: `v_ventas_cobradas_agente` solo incluye `estado_pago = 'PAGADO'` y agrupa por mes de `fecha_cobro`; `v_clientes_nuevos_agente` devuelve el primer periodo pagado por cliente; `v_cumplimiento_meta` da 112.00 para el agente del ejemplo.

**10 — Vistas de contrato.** Aceptación: `v_retenciones_area5` suma ISR e IMSS obrero por entidad solo de periodos AUTORIZADO, PAGADO o CERRADO; `v_desempeno_agente_zona` devuelve zona, región, agente, periodo, cumplimiento y ventas cobradas; ambas registradas en `docs/MODELO_DATOS.md` con su firma y no cambian después.

**11 — Vistas de recibo, totales y SBC.** Aceptación: `v_nomina_totales` da percepciones, deducciones y neto por agente y periodo; `v_sbc_bimestral` divide el variable entre 60.8; `v_recibo_nomina` trae concepto, clave SAT, monto, gravado y exento por renglón.

**12 — Servicios y errores.** Absorbe: `agentes.js`, `catalogos.js`, `metas.js`, `periodos.js` y traducción de errores. Aceptación: todas las llamadas a `supabase-js` del área viven en `src/services/area4/`; ningún servicio escribe `fecha_cobro`, `stock` ni estados de periodo saltándose las funciones; los componentes importan funciones, no el cliente; los mensajes `RN-A4-xx` que lanza la base se muestran como texto legible en un `Tag` rojo o alerta del panel, sin el error crudo de Postgres.

**13 — Módulo y dashboard.** Aceptación: la ruta "Nómina y Personal" abre el módulo; 4 `KpiCard` (nómina total del periodo, agentes activos, bono promedio, próximo pago) con datos de `v_nomina_totales` y `periodos_nomina`, con el estilo de `docs/GUIA_ESTILO.md`.

**14 — Agentes.** Aceptación: listado con `Table`, `Tag` de estatus (ACTIVO verde, SUSPENDIDO ámbar, BAJA rojo), alta y edición; un salario debajo del mínimo muestra el mensaje del trigger sin perder el formulario.

**15 — Catálogos y metas.** Absorbe: pantalla de zonas, esquemas y tramos; pantalla de metas. Aceptación: solo el rol ADMINISTRADOR ve el botón de alta en catálogos; un tramo traslapado muestra el mensaje `RN-A4-04`; captura de meta por agente y periodo `AAAA-MM`; la columna de cumplimiento se lee de `v_cumplimiento_meta` y no se calcula en el frontend; una meta duplicada muestra mensaje claro.

**16 — `fn_calcular_periodo` y `fn_aplicar_ajustes`.** Absorbe: cálculo de comisiones y bonos; ajustes por cancelación. Aceptación: solo corre en periodos MENSUAL y ABIERTO; falla con `RN-A4-03` si falta la meta y con `RN-A4-02` si el agente no tiene zona o esquema; sin esquema usa `agentes_ventas.comision` y anota la excepción en `bitacora_nomina`; aplica la tasa del tramo a toda la base cobrada; genera los bonos META, CLIENTE_NUEVO, COBRANZA_SANA, PUNTUALIDAD (con bandera manual) y TRIMESTRAL cuando aplica; deja el periodo en CALCULADO con `calculado_por`; una factura comisionada que pasa a CANCELADO genera `ajustes_comision` negativo, y al calcular el siguiente periodo se descuenta hasta el tope del art. 110 dejando el excedente con `id_periodo_aplicado` NULL para el siguiente.

**17 — `fn_calcular_nomina`.** Aceptación: para el ejemplo de la sección 10 las percepciones suman $33,004.00 con las claves SAT 001, 028, 038 y 010; comisiones y bonos 100 % gravados; premio de puntualidad exento hasta el tope de UMA y no integra SBC hasta el 10 %; ISR calculado con la tarifa del art. 96 leída de `parametros_legales`; IMSS obrero según `CUOTA_IMSS_OBRERO`; ISN con la tasa de la entidad del agente vía `v_tasas_isn`; INFONAVIT según lo decidido antes de empezar.

**18 — Pantalla de periodo.** Aceptación: los botones "Calcular", "Revisar", "Autorizar", "Pagar", "Cerrar" aparecen según el rol (CONTADOR o ADMINISTRADOR calcula, GERENTE_VENTAS revisa, AUTORIZADOR autoriza); el usuario que calculó ve deshabilitado "Autorizar"; rechazar exige comentario y regresa a ABIERTO; el estado se muestra con `Tag`.

**19 — Recibo, dispersión y reportes.** Absorbe: recibo por agente, CSV de dispersión y los tres reportes. Aceptación: recibo con sueldo, comisión, bonos, premio, ISR, IMSS, INFONAVIT y neto, cada renglón con clave SAT, gravado y exento; botón "Exportar" genera CSV con nombre, CLABE y neto de un periodo AUTORIZADO o PAGADO; tres `Panel` con `Table`: nómina del periodo, comisiones por agente y zona, y costo de compensación como porcentaje de ventas cobradas; todas las cifras vienen de vistas.

**20 — Pruebas SQL.** Un archivo por regla en `supabase/tests/area4/`, cada uno con `RAISE EXCEPTION` si la regla no se cumple. Aceptación: los cinco archivos corren limpios contra el seed.

**21 — Pruebas de aceptación y de punta a punta.** Absorbe: reproducción del ejemplo, paralelo contra Excel con casos límite, flujo completo desde la app. Aceptación: con el seed, el agente de zona general con salario $350, meta $500,000, $560,000 cobrados, 2 clientes nuevos, cartera vencida 3 % y sin retardos obtiene sueldo $10,640.00, comisión $16,800.00, bono de meta $2,500.00, clientes nuevos $1,000.00, cobranza sana $1,000.00, puntualidad $1,064.00, total $33,004.00; hoja de Excel con los 5 agentes y diferencia $0.00 en cada uno; el agente sin meta bloquea el cálculo; el agente sin esquema usa la tasa de respaldo y queda en bitácora; una cancelación genera ajuste; el agente en ZLFN no puede tener salario debajo de $440.87; el flujo alta de agente → meta → factura cobrada (área 2) → periodo calculado → autorizado por otro usuario → recibo corre con dos usuarios distintos sin errores no controlados en consola; bitácora de pruebas y capturas de cada paso en `evidencias/`.

**22 — Cierre.** Absorbe: contexto actualizado, evidencias y bitácora, reasignaciones, reporte final. Aceptación: `ESTADO.md` con entrada diaria; cada issue cerrado con evidencia enlazada; preguntas abiertas cerradas o justificadas; I-02, I-03, I-05, I-06 e I-12 como cerradas; reasignaciones en `EVALUACION.md` con motivo e impacto; `REPORTE_FINAL.md` entregado antes de las 10:00 del viernes 18 con la matriz final de evaluación.
