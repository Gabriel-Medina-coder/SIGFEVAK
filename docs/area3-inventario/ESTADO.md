# Estado — Área 3 · Inventario

Última actualización: 2026-09-13 por Diego (coordinación) con Davor

## Semáforo

🟢 En tiempo

## Hecho

- [x] #1 Integración I-01: fórmula de capital con flete, impuestos y tipo de cambio (Diego, Davor) — main 2026-09-13
- [x] #2 Integración I-09: la base no crea `marketing` ni `clientes_marketing`; `productos.activo` (Diego, Davor) — main 2026-09-13
- [x] #3 Integración I-11: cancelar no reintegra stock; devolución = ajuste con motivo `DEVOLUCION` (Diego, Davor) — main 2026-09-13
- [x] #4 Tablas `productos`, `entradas_producto`, `detalle_factura`, `ajustes_inventario` y RLS (Diego, Davor) — main 2026-09-13
- [x] #5 Triggers de entrada, salida y ajuste (Diego, Davor) — main 2026-09-13
- [x] #6 Vistas `v_inventario_actual`, `v_kardex`, `v_rotacion`, `v_discrepancias` (Diego, Davor) — main 2026-09-13
- [x] #7 Vista de contrato `v_entradas_area1` (Diego, Davor) — main 2026-09-13
- [x] #8 Vista de contrato `v_salidas_area2` (Diego, Davor) — main 2026-09-13
- [x] #9 Seed de 20 productos, 12 entradas, 10 salidas y 1 ajuste (Diego, Davor) — main 2026-09-13
- [x] #10 Pruebas SQL de RN-A3-01, 04, 05, 07 y 08 (Diego, Davor) — main 2026-09-13

## En progreso

- [ ] #11 Módulo del área en la app compartida (Diego, Davor) — espera la app base con menú

## Bloqueado

- Nada

## Próximo

- #12, #13, #14, #15, #16, #17

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 3 migraciones (`a3_tablas_inventario`, `a3_triggers`, `a3_vistas`), seed y pruebas.
- Integraciones I-01, I-09 e I-11 cerradas y anotadas en `docs/MODELO_DATOS.md` y en la sección 13 del contexto.
- Decisión: `detalle_factura` se crea en la migración del área 3 (referencia a `productos`), no en la base.
- Decisión: `entradas_producto` nace con las columnas de D-03 (`flete_unitario`, `impuestos_unitarios`, `tipo_cambio`) con defaults neutros, así el área 1 no toca el trigger.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y captura

-

### Mié 16 sep · Flujos e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
