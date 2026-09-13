# Estado — Área 1 · Entradas y manufactura

Última actualización: 2026-09-13 por Diego (coordinación) con Viviana

## Semáforo

🟢 En tiempo

## Hecho

- [x] #20 Integración I-01 verificada: entrada del ejemplo 10.1 deja capital 22,000 y valor 220 (Diego, Viviana) — main 2026-09-13
- [x] #21 Integración I-04: `v_entradas_importacion` publicada; impuestos capturados a mano (Diego, Viviana) — main 2026-09-13
- [x] #22 Checklist 11.5 con supuestos y preguntas abiertas 1, 6, 7 y 8 cerradas (Diego, Viviana) — main 2026-09-13
- [x] #23 Enums y catálogos `proveedores` y `almacenes` con RLS (Diego, Viviana) — main 2026-09-13
- [x] #24 Columnas aditivas en `productos` y `entradas_producto`, CHECK de moneda, SKU único (Diego, Viviana) — main 2026-09-13
- [x] #25 Tablas de manufactura con CHECK y RLS (Diego, Viviana) — main 2026-09-13
- [x] #26 Seed con los ejemplos 10.1 y 10.2 exactos (Diego, Viviana) — main 2026-09-13
- [x] #27 Trigger `fn_valida_entrada` (Diego, Viviana) — main 2026-09-13
- [x] #28 Triggers de materias primas y de orden (Diego, Viviana) — main 2026-09-13
- [x] #29 Triggers de consumo y calidad (Diego, Viviana) — main 2026-09-13
- [x] #30 Trigger `fn_cerrar_orden` (Diego, Viviana) — main 2026-09-13
- [x] #31 Vistas de reporte (Diego, Viviana) — main 2026-09-13
- [x] #32 Vistas de contrato con las áreas 4, 5 y 6 (Diego, Viviana) — main 2026-09-13
- [x] #33 Pruebas SQL del área (Diego, Viviana) — main 2026-09-13

## En progreso

- [ ] #35 Módulo del área en la app compartida (Diego, Viviana) — espera la app base con menú

## Bloqueado

- Nada

## Próximo

- #34, #36, #37, #38, #39

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 6 migraciones (`a1_tipos_catalogos`, `a1_manufactura`, `a1_columnas_aditivas`, `a1_trigger_entradas`, `a1_triggers_manufactura`, `a1_vistas`), seed y pruebas.
- Checklist 11.5: se toman los supuestos de la tabla del contexto (dos almacenes por tipo, calidad por orden completa, trazabilidad por lote, sin migración de históricos).
- Decisión: `flete_unitario`, `impuestos_unitarios` y `tipo_cambio` ya venían en la migración del área 3; la migración aditiva del área no las repite.
- Decisión: la migración de manufactura va antes que las columnas aditivas porque `entradas_producto` referencia `lotes` y `ordenes_produccion`.
- Preguntas abiertas 1, 6, 7 y 8 cerradas en la sección 16 del contexto; 2, 3, 4 y 5 quedan como fase 2.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y captura

-

### Mié 16 sep · Flujos e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
