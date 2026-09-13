# Issues #31 y #32 · Vistas de reporte y de contrato

Migración `20260913_0350_a1_vistas.sql` aplicada el 13 de septiembre de 2026.

```sql
SELECT * FROM v_discrepancias_recepcion;
```

| sku | proveedor | esperada | cantidad | diferencia | estado_mercancia |
| --- | --- | --- | --- | --- | --- |
| MF-CAB-HDMI2 | Electrónica del Norte SA de CV | 300 | 290 | -10 | INCOMPLETO |

```sql
SELECT sku, pais_origen, valor_mercancia_mxn, impuestos_capturados_mxn FROM v_entradas_importacion;
```

| sku | pais_origen | valor_mercancia_mxn | impuestos_capturados_mxn |
| --- | --- | --- | --- |
| EL-CAM-IP1080 | China | 37000.00 | 4625.00 |

```sql
SELECT folio, responsable, cantidad_terminada, costo_mano_obra, periodo FROM v_mano_obra_produccion;
```

| folio | responsable | cantidad_terminada | costo_mano_obra | periodo |
| --- | --- | --- | --- | --- |
| OP-2026-0001 | Marco Delgado | 48 | 2500.00 | 2026-09 |

`v_reabastecimiento` lista MF-BAS-LAP (faltante 50) y MF-KIT-SOL10 (faltante 20). `v_capital_en_proceso` da 1,700.00 para OP-2026-0002. `v_entradas_area1` del área 3 y `v_entradas_detalle` usan la misma fórmula de I-01.
