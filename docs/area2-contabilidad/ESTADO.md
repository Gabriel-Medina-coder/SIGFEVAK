# Estado · Área 2 · Contabilidad y facturación

Última actualización: 2026-09-13 por Diego (coordinación) con Eduardo

## Semáforo

🟢 En tiempo

## Hecho

- [x] #41 Integración con el área 3: esquema base confirmado y cancelación sin reintegro de stock (Diego, Eduardo) · main 2026-09-13
- [x] #42 Integración I-02 con el área 4: `fecha_cobro`, `fecha_vencimiento`, `subtotal` y `v_cartera_agente` (Diego, Eduardo) · main 2026-09-13
- [x] #43 Integración I-07 con el área 5: `v_iva_trasladado_periodo` y `uuid_cfdi` (Diego, Eduardo) · main 2026-09-13
- [x] #44 Integración I-10 con el área 6: baja lógica y `v_clientes_activos` (Diego, Eduardo) · main 2026-09-13
- [x] #45 Columnas aditivas, secuencias, CHECK de RFC e índices (Diego, Eduardo) · main 2026-09-13
- [x] #46 `fn_tasa_iva()`, folios y `fn_valida_factura` (Diego, Eduardo) · main 2026-09-13
- [x] #47 `fn_recalcular_factura` (Diego, Eduardo) · main 2026-09-13
- [x] #48 `fn_estado_pago_factura` y `fn_bloquea_detalle_cerrado` (Diego, Eduardo) · main 2026-09-13
- [x] #49 Vistas del equipo (Diego, Eduardo) · main 2026-09-13
- [x] #50 Vistas de contrato con las áreas 4, 5 y 6 (Diego, Eduardo) · main 2026-09-13
- [x] #51 Seed con el ejemplo FAC-000016 y el del área 4 (Diego, Eduardo) · main 2026-09-13
- [x] #52 Pruebas SQL del área (Diego, Eduardo) · main 2026-09-13

## En progreso

- [ ] #53 a #58 Módulo, servicios, comercializadores, factura con renglones, cobros, pendientes y dashboard (Diego, Eduardo) · construidos, en prueba en navegador

## Bloqueado

- Nada

## Próximo

- #59 prueba de punta a punta con capturas, #60 cierre

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 5 migraciones (`a2_columnas_aditivas`, `a2_folios_iva_validacion`, `a2_recalculo_factura`, `a2_estado_pago`, `a2_vistas`), seed y pruebas.
- Decisión: las 15 facturas y 10 clientes del seed base reciben folio, vencimiento y fecha de cobro por un paso de relleno en el seed del área; los totales se recalculan desde los renglones y ya no coinciden con los montos ilustrativos del seed base.
- Decisión: RLS de `clientes` y `facturas` ya venía de la migración base; la migración del área no la repite.
- El seed reproduce FAC-000016 (subtotal 20,725, IVA 3,316, total 24,041) y el ejemplo del área 4 (Jorge Mendoza: 560,000 cobrados sin IVA en 2026-09, clientes nuevos Norte Digital y Distribuidora Bajío, cartera vencida 3.00 %).
- Preguntas abiertas 2, 5, 6 y 7 cerradas; la 1 (tasa de IVA) queda en 16 % fijo para esta versión.
- Módulo construido en `src/modules/area2-contabilidad/` con servicios en `src/services/area2/`: factura en dos pasos (cabecera y renglones), rechazo por stock sin perder lo capturado, cambio de estado de pago, pendientes con filtros, comercializadores con baja lógica y exportación de ventas por agente. Consultas verificadas con la cuenta del contador. Falta la prueba en navegador para cerrar los issues.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y pantalla de comercializadores

-

### Mié 16 sep · Facturación, pagos e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
