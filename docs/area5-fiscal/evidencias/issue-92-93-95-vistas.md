# Issues #92, #93 y #95 · Vistas de reporte y de contrato

Migración `20260913_0650_a5_vistas.sql` aplicada el 13 de septiembre de 2026.

```sql
SELECT * FROM v_resumen_fiscal;
```

| monto_pendiente | obligaciones_pendientes | proximo_vencimiento | vencidas | pagado_en_el_anio | alertas_activas |
| --- | --- | --- | --- | --- | --- |
| 369848.20 | 10 | 2026-09-17 | 2 | 327364.90 | 12 |

```sql
SELECT * FROM v_tasas_isn;
```

| entidad | tasa_isn | vigencia_inicio | vigencia_fin |
| --- | --- | --- | --- |
| Chiapas | 0.020000 | 2026-01-01 | |

```sql
SELECT clave, periodo, fecha_vencimiento, dias_restantes, estado FROM v_calendario_fiscal;
```

| clave | periodo | fecha_vencimiento | dias_restantes | estado |
| --- | --- | --- | --- | --- |
| ISN_CHIAPAS | 2026-08 | 2026-09-17 | 4 | PENDIENTE |
| IVA_MENSUAL | 2026-08 | 2026-09-17 | 4 | LINEA_GENERADA |
| ISR_PROV | 2026-08 | 2026-09-17 | 4 | CALCULADO |

`v_impuestos_importacion_producto` (contrato con el área 1) por producto del segundo pedimento:

| nombre | cantidad | igi_producto | dta_producto | iva_importacion_producto | impuestos_por_unidad_sin_iva |
| --- | --- | --- | --- | --- | --- |
| Cámara IP WiFi 1080p | 50 | 5550.00 | 296.00 | 6855.36 | 116.92 |
| Smartwatch Fitness Pro | 30 | 9990.00 | 532.80 | 12339.65 | 350.76 |
| Auriculares BT TW-55 | 100 | 4440.00 | 236.80 | 5484.29 | 46.77 |

`v_obligaciones_pendientes`, `v_obligaciones_vencidas`, `v_pagos_por_institucion`, `v_alertas_activas` y `v_licencias_por_vencer` regresan datos del seed.
