# Issue #26 · Seed del área

`supabase/seed/seed_area1.sql` aplicado el 13 de septiembre de 2026, dos veces seguidas sin duplicar.

## Ejemplo 10.1 y variante en dólares

```sql
SELECT sku, proveedor, cantidad, moneda, tipo_cambio, valor_unitario_mxn, capital_entrada_mxn, iva_estimado_mxn
FROM v_entradas_detalle WHERE numero_factura_proveedor IN ('F-4471', 'SZ-2026-0917');
```

| sku | proveedor | cantidad | moneda | tipo_cambio | valor_unitario_mxn | capital_entrada_mxn | iva_estimado_mxn |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MF-BAS-LAP | Plásticos Bajío SA de CV | 100 | MXN | 1.0000 | 220.00 | 22000.00 | 3200.00 |
| EL-CAM-IP1080 | Shenzhen Import Co. | 50 | USD | 18.5000 | 888.00 | 44400.00 | 5920.00 |

## Ejemplo 10.2

```sql
SELECT folio, estado, cantidad_planeada, cantidad_terminada, costo_materia_real, merma_total, costo_unitario_manufactura, aprobadas, rechazadas
FROM v_ordenes_produccion WHERE folio = 'OP-2026-0001';
```

| folio | estado | planeada | terminada | costo_materia_real | merma_total | costo_unitario_manufactura | aprobadas | rechazadas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OP-2026-0001 | TERMINADA | 50 | 48 | 11420.00 | 2.000 | 302.08 | 48 | 2 |

Entrada generada por `fn_cerrar_orden`: 48 unidades a 302.08, proveedor PRODUCCIÓN INTERNA, capital 14,499.84. `materias_primas.stock`: carcasa 200 - 52 - 20 = 128, módulo 150 - 50 = 100.

Ninguna sentencia del seed escribe `productos.stock` ni `materias_primas.stock`.
