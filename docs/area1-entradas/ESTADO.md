# Estado · Área 1 · Entradas y manufactura

Última actualización: 2026-09-13 por Diego (coordinación) con Viviana

## Semáforo

🟢 En tiempo

## Hecho

- [x] #20 Integración I-01 verificada: entrada del ejemplo 10.1 deja capital 22,000 y valor 220 (Diego, Viviana) · main 2026-09-13
- [x] #21 Integración I-04: `v_entradas_importacion` publicada; impuestos capturados a mano (Diego, Viviana) · main 2026-09-13
- [x] #22 Checklist 11.5 con supuestos y preguntas abiertas 1, 6, 7 y 8 cerradas (Diego, Viviana) · main 2026-09-13
- [x] #23 Enums y catálogos `proveedores` y `almacenes` con RLS (Diego, Viviana) · main 2026-09-13
- [x] #24 Columnas aditivas en `productos` y `entradas_producto`, CHECK de moneda, SKU único (Diego, Viviana) · main 2026-09-13
- [x] #25 Tablas de manufactura con CHECK y RLS (Diego, Viviana) · main 2026-09-13
- [x] #26 Seed con los ejemplos 10.1 y 10.2 exactos (Diego, Viviana) · main 2026-09-13
- [x] #27 Trigger `fn_valida_entrada` (Diego, Viviana) · main 2026-09-13
- [x] #28 Triggers de materias primas y de orden (Diego, Viviana) · main 2026-09-13
- [x] #29 Triggers de consumo y calidad (Diego, Viviana) · main 2026-09-13
- [x] #30 Trigger `fn_cerrar_orden` (Diego, Viviana) · main 2026-09-13
- [x] #31 Vistas de reporte (Diego, Viviana) · main 2026-09-13
- [x] #32 Vistas de contrato con las áreas 4, 5 y 6 (Diego, Viviana) · main 2026-09-13
- [x] #33 Pruebas SQL del área (Diego, Viviana) · main 2026-09-13
- [x] #34 a #38 Servicios, módulo, catálogos, entradas con capital en vivo, órdenes de producción y prueba de punta a punta con capturas en la historia del flujo (Diego, Viviana) · main 2026-09-13
- [x] #39 Integración con las áreas 4 y 6: Nómina lee `v_mano_obra_produccion`, Marketing lee `v_ordenes_produccion` y `v_reabastecimiento`; `v_entradas_area1` cuadra al centavo con `v_entradas_detalle` en los 25 meses (Diego, Viviana) · main 2026-09-13

## En progreso

- Nada

## Bloqueado

- Nada

## Próximo

- #40 cierre del área: reporte final y evaluación del equipo (líder)

## Bitácora

### Dom 13 sep · Arranque

- Base de datos completa del área aplicada al proyecto de Supabase: 6 migraciones (`a1_tipos_catalogos`, `a1_manufactura`, `a1_columnas_aditivas`, `a1_trigger_entradas`, `a1_triggers_manufactura`, `a1_vistas`), seed y pruebas.
- Checklist 11.5: se toman los supuestos de la tabla del contexto (dos almacenes por tipo, calidad por orden completa, trazabilidad por lote, sin migración de históricos).
- Decisión: `flete_unitario`, `impuestos_unitarios` y `tipo_cambio` ya venían en la migración del área 3; la migración aditiva del área no las repite.
- Decisión: la migración de manufactura va antes que las columnas aditivas porque `entradas_producto` referencia `lotes` y `ordenes_produccion`.
- Preguntas abiertas 1, 6, 7 y 8 cerradas en la sección 16 del contexto; 2, 3, 4 y 5 quedan como fase 2.
- Módulo construido en `src/modules/area1-entradas/` con servicios en `src/services/area1/`: entradas con capital estimado en vivo, órdenes de producción con consumo, calidad y cierre, materias primas, proveedores, almacenes y discrepancias. Consultas verificadas con la cuenta de almacén. Falta la prueba en navegador para cerrar los issues.
- Entradas lee de Regulación los impuestos por unidad del último pedimento del producto (`v_impuestos_importacion_producto`) y los usa en la entrada con un clic, convertidos a la moneda de la entrada (#103). La vista `v_entradas_area1` redondea el capital por entrada y ya no difiere un centavo (#39). Evidencias en `evidencias/issue-39-integracion.md` e `issue-103-impuestos-del-pedimento.png`.

### Lun 14 sep · Base de datos

-

### Mar 15 sep · Vistas, servicios y captura

-

### Mié 16 sep · Flujos e integración (congelamiento 18:00)

-

### Jue 17 sep · Cierre y entrega

-
