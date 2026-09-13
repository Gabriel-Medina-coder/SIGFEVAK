# Issue #10 · Pruebas SQL

`supabase/tests/area3/pruebas_area3.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Verifica RN-A3-01, RN-A3-04, RN-A3-05, RN-A3-07 y RN-A3-08 en un solo bloque dentro de una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT count(*) AS temporales FROM productos WHERE nombre LIKE 'PRUEBA%';
```

| temporales |
| --- |
| 0 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area3/pruebas_area3.sql`.
