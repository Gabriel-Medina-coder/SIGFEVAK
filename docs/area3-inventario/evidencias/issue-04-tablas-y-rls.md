# Issue #4 · Tablas del área y RLS

Migración `supabase/migrations/20260913_0200_a3_tablas_inventario.sql` aplicada al proyecto el 13 de septiembre de 2026 (versión `20260913064316`).

```sql
SELECT table_name, row_security FROM information_schema.tables t
JOIN pg_tables p ON p.tablename = t.table_name
WHERE table_schema = 'public' AND table_name IN ('productos','entradas_producto','detalle_factura','ajustes_inventario');
```

| tabla | RLS |
| --- | --- |
| productos | activado |
| entradas_producto | activado |
| detalle_factura | activado |
| ajustes_inventario | activado |

Restricciones verificadas por las pruebas de `supabase/tests/area3/pruebas_area3.sql`: `ck_stock_no_negativo`, `uq_producto`, `ck_entrada_cantidad`, `ck_detalle_cantidad`, columna generada `diferencia`.
Cierra también #2 (I-09): la base no crea `marketing` ni `clientes_marketing`; `productos.activo` existe con default `TRUE`.
