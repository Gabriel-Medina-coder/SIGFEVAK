# Issues #23, #24 y #25 · Tipos, catálogos, columnas aditivas y manufactura

Migraciones aplicadas al proyecto el 13 de septiembre de 2026, en este orden:

| Migración | Issue |
| --- | --- |
| `20260913_0300_a1_tipos_catalogos.sql` | #23 |
| `20260913_0310_a1_manufactura.sql` | #25 |
| `20260913_0320_a1_columnas_aditivas.sql` | #24 |

Conteo después del seed:

```sql
SELECT (SELECT count(*) FROM almacenes) almacenes, (SELECT count(*) FROM proveedores) proveedores,
       (SELECT count(*) FROM productos WHERE sku IS NOT NULL) productos_sku, (SELECT count(*) FROM materias_primas) materias,
       (SELECT count(*) FROM bom) bom, (SELECT count(*) FROM ordenes_produccion) ordenes;
```

| almacenes | proveedores | productos_sku | materias | bom | ordenes |
| --- | --- | --- | --- | --- | --- |
| 2 | 4 | 6 | 3 | 2 | 2 |

Las nueve tablas nuevas tienen RLS con política para `authenticated`. Los `INSERT` del área 3 con solo `tipo` y `nombre` y con solo `id_producto`, `cantidad` y `costo_unitario` siguen funcionando: el seed del área 3 corrió antes y después sin cambios. `moneda = 'USD'` con `tipo_cambio = 1` falla por `ck_tipo_cambio_moneda` (ver pruebas).
