# Issues #27, #28, #29 y #30 · Triggers del área

Migraciones `20260913_0330_a1_trigger_entradas.sql` (#27) y `20260913_0340_a1_triggers_manufactura.sql` (#28, #29, #30) aplicadas el 13 de septiembre de 2026.

Comprobado con las pruebas de `supabase/tests/area1/pruebas_area1.sql`:

| Regla | Caso | Resultado |
| --- | --- | --- |
| RN-A1-06 | Entrada a almacén `INSUMOS` | Rechazada |
| RN-A1-05 | Lote de otro producto | Rechazada |
| RN-A1-18 | Entrada con almacén sin documento | Rechazada |
| RN-A1-04 | Entrada con `id_proveedor` | `proveedor` copia el nombre |
| RN-A1-06 | Materia prima en almacén `PRODUCTO_TERMINADO` | Rechazada |
| RN-A1-10 | Orden sin BOM | Rechazada |
| RN-A1-11 | Salto y retroceso de estado; cambio tras `TERMINADA` | Rechazados |
| RN-A1-13 | Consumo en orden `PLANEADA` | Rechazado |
| RN-A1-14 | Materia fuera del BOM | Rechazada |
| RN-A1-09 | Consumo mayor al stock | Rechazado con mensaje RN-A1-09 |
| RN-A1-12 | Terminar sin calidad | Rechazado |
| RN-A1-15 | Totales mayores a lo planeado; rechazadas sin motivo | Rechazados |
| RN-A1-16 | Inspector igual al responsable | Rechazado |
| RN-A1-17 | Cierre del ejemplo 10.2 | Entrada de 48 a 302.08; stock del producto 148 |
