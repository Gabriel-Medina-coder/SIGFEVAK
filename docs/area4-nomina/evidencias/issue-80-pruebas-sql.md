# Issue #80 · Pruebas SQL

`supabase/tests/area4/pruebas_area4.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Cubre salario mínimo, tramos, bono manual, el ejemplo de la sección 10 exacto (conceptos, total 33,004, ISR, IMSS e ISN), meta obligatoria, transición de estados, rechazo con comentario, ajuste con tope del art. 110, separación de funciones y periodo pagado o cerrado. Corre en una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT (SELECT count(*) FROM periodos_nomina) periodos, (SELECT count(*) FROM agentes_ventas WHERE nombre LIKE 'PRUEBA%') agentes_prueba,
       (SELECT count(*) FROM metas WHERE periodo = '2026-10') metas_oct, (SELECT count(*) FROM ajustes_comision) ajustes;
```

| periodos | agentes_prueba | metas_oct | ajustes |
| --- | --- | --- | --- |
| 1 | 0 | 0 | 0 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area4/pruebas_area4.sql`.
