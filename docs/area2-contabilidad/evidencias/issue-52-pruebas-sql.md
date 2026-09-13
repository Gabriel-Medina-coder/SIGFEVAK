# Issue #52 · Pruebas SQL

`supabase/tests/area2/pruebas_area2.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Cubre el recálculo (insertar, editar, borrar y borrar el último renglón), estado de pago y fecha de cobro, folios, vencimiento, baja lógica, factura cerrada, RFC y el rechazo por stock del área 3, en una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT (SELECT count(*) FROM clientes WHERE nombre_empresa LIKE 'PRUEBA%') clientes_prueba,
       (SELECT count(*) FROM facturas) facturas;
```

| clientes_prueba | facturas |
| --- | --- |
| 0 | 21 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area2/pruebas_area2.sql`.
