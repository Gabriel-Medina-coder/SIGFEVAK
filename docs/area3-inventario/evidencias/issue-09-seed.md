# Issue #9 · Seed del área

`supabase/seed/seed_area3.sql` aplicado el 13 de septiembre de 2026 sobre el seed base. Corrió dos veces sin duplicar.

```sql
SELECT (SELECT count(*) FROM productos) productos, (SELECT count(*) FROM entradas_producto) entradas,
       (SELECT count(*) FROM detalle_factura) salidas, (SELECT count(*) FROM ajustes_inventario) ajustes,
       (SELECT sum(stock) FROM productos) stock_total, (SELECT sum(volumen) FROM productos) volumen_total;
```

| productos | entradas | salidas | ajustes | stock_total | volumen_total |
| --- | --- | --- | --- | --- | --- |
| 20 | 12 | 10 | 1 | 8293 | 11400 |

Ninguna sentencia del seed escribe `productos.stock`; el stock lo movieron los triggers (RN-A3-06). Hay 9 productos con stock 0 (sin entradas) y `Monitor LED 24" FHD` queda con 180 unidades para probar las etiquetas del catálogo.
