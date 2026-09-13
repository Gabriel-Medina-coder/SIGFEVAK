# Issue #97 · Pruebas SQL

`supabase/tests/area5/pruebas_area5.sql` corrió el 13 de septiembre de 2026 contra el proyecto sin lanzar excepción. Verifica los ejemplos 10.1 y 10.2 sobre el seed, la máquina de estados completa con una obligación propia, separación de funciones, rol del autorizador, monto congelado, pagos y conciliación, cerradas inmutables, baja lógica con bitácora, vencidas automáticas, alertas sin duplicar, fracción sin tasa, pedimento sin fracción, recálculo al fijar la fracción, importación sobre una obligación que no es pedimento y licencia sin municipio. Corre en una transacción que se revierte.

Confirmación de que no dejó datos:

```sql
SELECT (SELECT count(*) FROM obligaciones) obligaciones,
       (SELECT count(*) FROM importaciones WHERE numero_pedimento LIKE 'PRUEBA%') imp_prueba,
       (SELECT count(*) FROM obligaciones WHERE periodo LIKE '2030%' OR periodo LIKE '2020%') obl_prueba;
```

| obligaciones | imp_prueba | obl_prueba |
| --- | --- | --- |
| 12 | 0 | 0 |

Para volver a correrla sin CLI: `node supabase/sql.mjs file supabase/tests/area5/pruebas_area5.sql`.
