# Issue #117 · Pruebas SQL

`supabase/tests/area6/pruebas_area6.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Verifica el caso A (resumen, presupuesto excedido y ampliado), el caso B (desempeño directo y ventas atribuidas reales) y los casos límite RN-A6-02, 04, 09, 10, 13, 15 y 16. Corre en una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT (SELECT count(*) FROM campanas) campanas, (SELECT count(*) FROM campanas WHERE nombre LIKE 'PRUEBA%') campanas_prueba,
       (SELECT presupuesto_asignado FROM campanas WHERE nombre = 'Lanzamiento Smartwatch Pro') presupuesto_a;
```

| campanas | campanas_prueba | presupuesto_a |
| --- | --- | --- |
| 4 | 0 | 50000.00 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area6/pruebas_area6.sql`.
