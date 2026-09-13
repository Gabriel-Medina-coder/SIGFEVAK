# Issues #87, #88, #89 y #90 · Catálogos, tablas de operación, máquina de estados y auditoría

Migraciones aplicadas al proyecto el 13 de septiembre de 2026:

| Migración | Issues |
| --- | --- |
| `20260913_0600_a5_tipos_catalogos.sql` | #87 |
| `20260913_0610_a5_tablas_operacion.sql` | #88 |
| `20260913_0620_a5_triggers.sql` | #89, #90 |

Comprobado con `supabase/tests/area5/pruebas_area5.sql`:

| Regla | Caso | Resultado |
| --- | --- | --- |
| RN-A5-19 | Salto PENDIENTE a PRESENTADO; CALCULADO sin monto; rechazo sin comentario; VENCIDO a otro estado que no sea PAGADO | Rechazados |
| RN-A5-18 | El responsable se autoriza a sí mismo | Rechazado |
| RN-A5-06 | Un GERENTE_VENTAS autoriza una obligación crítica | Rechazado |
| RN-A5-23 | Cambiar `monto_final` después de AUTORIZADO | Rechazado |
| RN-A5-04 | PAGADO sin pago registrado | Rechazado |
| RN-A5-05 | CONCILIADO con pagos que no suman el monto final | Rechazado |
| RN-A5-07 | CONCILIADO sin comprobante bancario | Rechazado |
| RN-A5-24 | Cambio en obligación CERRADO y pago sobre ella | Rechazados |
| RN-A5-22 | DELETE de una obligación | Convertido en baja lógica con bitácora |
| RN-A5-17 | Baja, autorización, cierre | Filas en `bitacora_fiscal` (acciones BAJA, AUTORIZAR, CERRAR) |

RLS: 12 tablas con política para `authenticated`; `obligaciones`, `pagos_obligacion` y `documentos_fiscales` sin política de DELETE.
