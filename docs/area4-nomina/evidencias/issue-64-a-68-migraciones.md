# Issues #64, #65, #67 y #68 · Catálogos, tablas de operación, parámetros y estados

Migraciones aplicadas al proyecto el 13 de septiembre de 2026:

| Migración | Issues |
| --- | --- |
| `20260913_0500_a4_tipos_catalogos.sql` | #64 |
| `20260913_0510_a4_tablas_operacion.sql` | #65 |
| `20260913_0520_a4_parametros_y_estados.sql` | #67, #68 |

Comprobado con `supabase/tests/area4/pruebas_area4.sql`:

| Regla | Caso | Resultado |
| --- | --- | --- |
| RN-A4-01 | Salario 300 en zona general (mínimo 315.04); salario 350 en ZLFN (mínimo 440.87) | Rechazados |
| RN-A4-04 | Tramo 90 a 110 sobre un esquema con tramos 70 a 100 y 100 a 120 | Rechazado |
| RN-A4-09 | Bono manual sin `autorizado_por` | Rechazado por CHECK |
| RN-A4-13 | Salto ABIERTO a REVISADO; regreso a ABIERTO sin comentario | Rechazados |
| RN-A4-13 | Regreso CALCULADO a ABIERTO con comentario | Aceptado y en bitácora |
| RN-A4-15 | Autoriza quien calculó | Rechazado |
| RN-A4-18 | Movimiento en `nomina_detalle` y cambio de estado de un periodo PAGADO | Rechazados |

Las 11 tablas nuevas tienen RLS con política para `authenticated`. `parametros_legales` tiene 10 valores vigentes con su fuente.
