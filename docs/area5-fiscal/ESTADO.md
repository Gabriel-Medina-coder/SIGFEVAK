# Estado · Área 5 · Fiscal y permisos

Última actualización: 2026-09-13 por Diego (coordinación) con Ivan

## Semáforo

🟢 En tiempo

## Hecho

- [x] #83 Integración I-03 con el área 4: `v_tasas_isn` publicada y `v_retenciones_area5` consumida (Diego, Ivan) · main 2026-09-13
- [x] #84 Integración I-04 con el área 1: `v_impuestos_importacion_producto` publicada; IVA acreditable a mano (Diego, Ivan) · main 2026-09-13
- [x] #85 Integración I-07 con el área 2: `v_iva_trasladado_periodo` consumida al generar la obligación de IVA (Diego, Ivan) · main 2026-09-13
- [x] #86 Integración I-08: `usuarios` con rol, cuentas por rol, funciones diarias por botón (Diego, Ivan) · main 2026-09-13
- [x] #87 Enums, catálogos, `parametros_fiscales`, `fn_parametro_fiscal` e `impuestos_licencias` (Diego, Ivan) · main 2026-09-13
- [x] #88 Tablas de operación con CHECK, índices y RLS sin DELETE (Diego, Ivan) · main 2026-09-13
- [x] #89 Máquina de estados y separación de funciones (Diego, Ivan) · main 2026-09-13
- [x] #90 Bitácora, baja lógica e inmutabilidad de cerradas (Diego, Ivan) · main 2026-09-13
- [x] #91 Funciones diarias (Diego, Ivan) · main 2026-09-13
- [x] #92 Vistas de reporte (Diego, Ivan) · main 2026-09-13
- [x] #93 Vistas de contrato `v_tasas_isn` y `v_resumen_fiscal` (Diego, Ivan) · main 2026-09-13
- [x] #94 Importaciones y licencias con sus triggers (Diego, Ivan) · main 2026-09-13
- [x] #95 Vista de contrato `v_impuestos_importacion_producto` (Diego, Ivan) · main 2026-09-13
- [x] #96 Seed completo (Diego, Ivan) · main 2026-09-13
- [x] #97 Pruebas SQL del área (Diego, Ivan) · main 2026-09-13

## En progreso

- [ ] #98 a #102 Módulo, servicios, obligaciones con calendario y alertas, flujo completo por rol, importaciones y licencias (Diego, Ivan) · construidos, en prueba en navegador

## Bloqueado

- Nada

## Próximo

- #103 punta a punta con capturas (IVA por los nueve estados con dos usuarios), #104 cierre

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 6 migraciones (`a5_tipos_catalogos`, `a5_tablas_operacion`, `a5_triggers`, `a5_importaciones_licencias`, `a5_funciones_diarias`, `a5_vistas`), seed y pruebas.
- El ejemplo 10.1 se reproduce con la obligación de IVA de julio: 110,000 recorridos por los nueve estados hasta CERRADO. El ejemplo 10.2 se reproduce con el pedimento 26 47 3891 6004520: IGI 75,000, DTA 4,000, IVA 92,640, total 171,640, 395 por unidad para el área 1.
- Decisión: la tabla `impuestos_licencias` del modelo base la crea la primera migración del área (no existía en la base).
- Decisión: municipio sede Tuxtla Gutiérrez; `pg_cron` no se usa; las tasas de IGI del seed quedan en 0.15 hasta confirmarlas en la TIGIE (pregunta abierta 9).
- Preguntas abiertas 1 a 8 cerradas en la sección 16 del contexto.
- Módulo construido en `src/modules/area5-fiscal/` con servicios en `src/services/area5/`: cada estado tiene su formulario (cálculo, declaración, línea de captura, autorización, pago con comprobante, conciliación, cierre); quien registró no ve autorizar; botón de administración que corre las funciones diarias y genera obligaciones del mes. Consultas verificadas con la cuenta del autorizador. Falta la prueba en navegador para cerrar los issues.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y pantallas

-

### Mié 16 sep · Flujo de pagos, importaciones e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
