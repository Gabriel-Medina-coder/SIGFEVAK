# Issue #103 · Pruebas de punta a punta e integración probada

Fecha: 13 sep 2026, sobre la base con dos años de operación (D-12).

## ISN desde `v_retenciones_area5`

`fn_generar_obligaciones_periodo` toma la base del bimestre de `v_retenciones_area5` (Chiapas) y aplica la tasa vigente. Comparación de las obligaciones cerradas contra la vista:

| Bimestre que cierra | Monto de la obligación | Base de retenciones × 2 % |
| --- | --- | --- |
| 2026-06 | 1,652.85 | 1,652.85 |
| 2026-04 | 1,747.70 | 1,747.70 |
| 2026-02 | 1,359.31 | 1,359.31 |
| 2025-12 | 1,844.10 | 1,844.10 |

## IVA desde `v_iva_trasladado_periodo`

Al generarse, la obligación de IVA toma el IVA trasladado del mes (seed del área 5: julio a octubre 2026). En la historia del flujo, la de septiembre arrancó en 254,784, el trasladado de la vista en ese momento, y el contador registró el determinado de 44,784 antes de presentarla.

## Pedimentos ligados a `v_entradas_importacion`

24 pedimentos tienen entrada ligada y los 24 aparecen en `v_entradas_importacion`. El del ejemplo 10.2 (26 47 3891 6004520) da 395.00 por unidad en `v_impuestos_importacion_producto`.

## El área 1 lee `v_impuestos_importacion_producto`

Al capturar una entrada, Entradas muestra el último pedimento del producto y sus impuestos por unidad, y con un clic los usa en la entrada convertidos a la moneda de captura. Con la tableta del ejemplo: 395.00 MXN por unidad, en una entrada en USD a 18.25 queda 21.64 USD.

- [Captura en Entradas](../../area1-entradas/evidencias/issue-103-impuestos-del-pedimento.png)

## IVA por los 9 estados con dos usuarios

Capítulo 12 de la [historia del flujo](../../HISTORIA_FLUJO.md): el contador calcula, presenta y genera la línea; el autorizador autoriza; el contador registra el pago con comprobante; el autorizador concilia y cierra. Bitácora con una línea por paso y sin errores en consola.

- [Orden de pago dirigido](historia-27-orden-de-pago-dirigido.png) · [Pago con comprobante](historia-28-pago-con-comprobante.png) · [IVA cerrado](historia-29-iva-cerrado.png)

Las seis suites de pruebas SQL y la de seguridad pasan sobre esta base.
