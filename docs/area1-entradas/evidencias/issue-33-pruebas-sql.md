# Issue #33 · Pruebas SQL

`supabase/tests/area1/pruebas_area1.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Verifica RN-A1-04 a RN-A1-18 en un escenario propio y reproduce el costo del ejemplo 10.2 al centavo. Corre dentro de una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT (SELECT count(*) FROM productos WHERE nombre LIKE 'PRUEBA%') productos,
       (SELECT count(*) FROM almacenes WHERE nombre LIKE 'PRUEBA%') almacenes,
       (SELECT count(*) FROM ordenes_produccion WHERE folio LIKE 'OP-PRUEBA%') ordenes;
```

| productos | almacenes | ordenes |
| --- | --- | --- |
| 0 | 0 | 0 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area1/pruebas_area1.sql`.
