# Estado · Área 4 · Nómina de agentes

Última actualización: 2026-09-13 por Diego (coordinación) con Fernando

## Semáforo

🟢 En tiempo

## Hecho

- [x] #62 Integración I-03 con el área 5: `v_tasas_isn` y `v_retenciones_area5` (Diego, Fernando) · main 2026-09-13
- [x] #61 Integración I-02 e I-12 con el área 2: `fecha_cobro`, `subtotal`, `fecha_vencimiento`, `v_cartera_agente` y seed único de agentes (Diego, Fernando) · main 2026-09-13
- [x] #63 Integración I-05 con el área 6 e I-06 con el área 1 (Diego, Fernando) · main 2026-09-13
- [x] #64 Enums, catálogos `zonas`, `esquemas_compensacion`, `tramos_comision` y trigger de tramos (Diego, Fernando) · main 2026-09-13
- [x] #65 Ampliación de `agentes_ventas` y tablas de operación con RLS (Diego, Fernando) · main 2026-09-13
- [x] #66 Seed legal y de negocio (Diego, Fernando) · main 2026-09-13
- [x] #67 `fn_parametro` y trigger de salario mínimo (Diego, Fernando) · main 2026-09-13
- [x] #68 `fn_transicion_periodo` y `fn_bloquea_periodo_cerrado` (Diego, Fernando) · main 2026-09-13
- [x] #69 Vistas sobre `facturas` del área 2 (Diego, Fernando) · main 2026-09-13
- [x] #70 Vistas de contrato `v_retenciones_area5` y `v_desempeno_agente_zona` (Diego, Fernando) · main 2026-09-13
- [x] #71 Vistas `v_recibo_nomina`, `v_nomina_totales`, `v_sbc_bimestral` (Diego, Fernando) · main 2026-09-13
- [x] #76 `fn_calcular_periodo` y `fn_aplicar_ajustes` (Diego, Fernando) · main 2026-09-13
- [x] #77 `fn_calcular_nomina` (Diego, Fernando) · main 2026-09-13
- [x] #80 Pruebas SQL del área (Diego, Fernando) · main 2026-09-13
- [x] #72 a #75, #78 y #79 Servicios, módulo, agentes, catálogos y metas, periodo por rol, recibos, dispersión y reportes (Diego, Fernando) · main 2026-09-13
- [x] #81 Aceptación: ejemplo de la sección 10 exacto, paralelo en Excel de los 5 agentes con diferencia $0.00, casos límite en pruebas SQL, ajuste automático por cancelación, alta de agente y flujo por varios usuarios (Diego, Fernando) · main 2026-09-13

## En progreso

- Nada

## Bloqueado

- Nada

## Próximo

- #82 cierre del área: reporte final y evaluación del equipo (líder)

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 5 migraciones (`a4_tipos_catalogos`, `a4_tablas_operacion`, `a4_parametros_y_estados`, `a4_vistas`, `a4_calculo`), seed y pruebas.
- El ejemplo de la sección 10 se reproduce exacto con el periodo mensual 2026-09 del seed: Jorge Mendoza cobra 560,000 sin IVA (112 %), comisión 16,800 al 3 %, bonos de meta 2,500, clientes nuevos 1,000, cobranza sana 1,000, premio de puntualidad 1,064, total 33,004. Deducciones con los parámetros cargados: ISR 5,169.58 e IMSS obrero 760.17.
- Decisión: solo se calculan periodos `MENSUAL` en esta versión; el sueldo del mes entra al periodo mensual. Quincenas en fase 2 (pregunta abierta 8).
- Decisión: `metas.sin_retardos` es la bandera manual del premio de puntualidad; `parametros_legales.fuente` guarda el origen de cada valor; `v_retenciones_area5` agrega `isn_estimado`.
- Decisión: INFONAVIT fuera del alcance (pregunta abierta 4). Nuevas preguntas 9 (tope exento de puntualidad) y 10 (ramo excedente IMSS) para el analista.
- Preguntas abiertas 1 a 8 cerradas en la sección 16 del contexto.
- Módulo construido en `src/modules/area4-nomina/` con servicios en `src/services/area4/`: calcula CONTADOR o ADMINISTRADOR, revisa GERENTE_VENTAS, autoriza AUTORIZADOR y quien calculó no ve habilitado autorizar. Recibo con claves SAT, CSV de dispersión y reportes. Consultas verificadas con la cuenta del gerente. Falta la prueba en navegador para cerrar los issues.
- Integración I-03 cerrada (#62): el Área 5 publica `v_tasas_isn`.
- RN-A4-08 no tenía disparador: se agrega `fn_ajuste_por_cancelacion` (migración `20260913_0900_a4_ajuste_por_cancelacion`), que al cancelar una factura cobrada en un periodo ya autorizado crea el ajuste negativo con la tasa pagada. Pruebas nuevas: salario exacto del mínimo ZLFN, tramo al 100 % exacto, agente sin esquema con tasa de respaldo y bitácora, cancelación con y sin comisión pagada. Reportes muestra la mano de obra de producción del periodo (insumo futuro de bonos, sin cambiar el cálculo). Evidencias en `evidencias/issue-81-aceptacion.md`.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y pantallas

-

### Mié 16 sep · Cálculo, flujo de estados e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
