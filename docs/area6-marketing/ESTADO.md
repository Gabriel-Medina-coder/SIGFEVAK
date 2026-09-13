# Estado · Área 6 · Marketing

Última actualización: 2026-09-13 por Diego (coordinación) con César

## Semáforo

🟢 En tiempo

## Hecho

- [x] #105 Integración I-09 con el área 3: la base no crea `marketing` ni `clientes_marketing`; `productos.activo`; lectura de `v_rotacion` (Diego, César) · main 2026-09-13
- [x] #106 Integración I-10 con el área 2: `clientes.activo`, `v_clientes_activos` y ventas atribuidas sobre `facturas` pagadas (Diego, César) · main 2026-09-13
- [x] #107 Integración I-05 con el área 4 y la coordinación: `v_desempeno_agente_zona`, roles y vistas del resumen general (Diego, César) · main 2026-09-13
- [x] #108 Enums y catálogos `canales_marketing` y `proveedores_marketing` (Diego, César) · main 2026-09-13
- [x] #109 Tablas de operación y uniones con las áreas 2 y 3 (Diego, César) · main 2026-09-13
- [x] #110 Índices, RLS mínima y `actualizado_en` por trigger (Diego, César) · main 2026-09-13
- [x] #111 Triggers de presupuesto y campaña directa (Diego, César) · main 2026-09-13
- [x] #112 Triggers de campaña cerrada y de activación (Diego, César) · main 2026-09-13
- [x] #113 Seed con los casos A y B (Diego, César) · main 2026-09-13
- [x] #114 Vistas de contrato `v_campana_resumen` y `v_costos_por_canal` (Diego, César) · main 2026-09-13
- [x] #115 `v_ventas_atribuidas_campana` sobre facturas pagadas (Diego, César) · main 2026-09-13
- [x] #116 `v_directo_desempeno` y `v_productos_baja_rotacion_campana` (Diego, César) · main 2026-09-13
- [x] #117 Pruebas SQL del área (Diego, César) · main 2026-09-13

## En progreso

- [ ] #118 a #124 Módulo, servicios, tablero, campañas con detalle por pestañas, costos, catálogos e investigación (Diego, César) · construidos, en prueba en navegador

## Bloqueado

- Nada

## Próximo

- #125 punta a punta con capturas, #126 cierre

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 5 migraciones (`a6_tipos_catalogos`, `a6_tablas_operacion`, `a6_indices_rls`, `a6_triggers`, `a6_vistas`), seed y pruebas.
- Caso A reproducido exacto: gasto 45,000 de 50,000 (90 %), ROI 1.9333, y el cuarto costo de 7,500 rechazado por RN-A6-03.
- Caso B: 5 clientes objetivo, 4 contactados, 2 convertidos, 40 %. Las ventas atribuidas se recalcularon con las facturas reales del seed del área 2 (5 facturas pagadas en agosto de los cinco clientes objetivo, 771,200 sin IVA, ROI real 67.8571); la sección 10 del contexto quedó actualizada.
- Decisión: la campaña del caso B se llama "Promo revendedores agosto" y su vigencia es agosto, que es cuando el seed del área 2 tiene facturas pagadas de esos clientes. Se agregó el canal "Llamada" (7 canales).
- Decisión: RLS mínima; `fn_a6_usuario_tiene_rol` queda lista para el endurecimiento por rol si se decide (pregunta abierta 8).
- Preguntas abiertas 1 a 8 cerradas en la sección 16 del contexto.
- Módulo construido en `src/modules/area6-marketing/` con servicios en `src/services/area6/`: tablero con gasto por canal, campañas con pestañas de costos, métricas, clientes objetivo y productos, costos globales con totales por mes, investigación y catálogos solo para ADMINISTRADOR. Consultas verificadas con sesión real. Falta la prueba en navegador para cerrar los issues.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y pantallas

-

### Mié 16 sep · Flujos e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
