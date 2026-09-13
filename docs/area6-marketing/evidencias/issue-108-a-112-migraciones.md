# Issues #108, #109, #110, #111 y #112 · Catálogos, tablas, RLS y triggers

Migraciones aplicadas al proyecto el 13 de septiembre de 2026:

| Migración | Issues |
| --- | --- |
| `20260913_0700_a6_tipos_catalogos.sql` | #108 |
| `20260913_0710_a6_tablas_operacion.sql` | #109 |
| `20260913_0720_a6_indices_rls.sql` | #110 |
| `20260913_0730_a6_triggers.sql` | #111, #112 |

Comprobado con `supabase/tests/area6/pruebas_area6.sql`:

| Regla | Caso | Resultado |
| --- | --- | --- |
| RN-A6-03 | Cuarto costo de 7,500 sobre un presupuesto de 50,000 con 45,000 gastados | Rechazado; el resumen sigue en 45,000. Con el presupuesto en 52,500 entra |
| RN-A6-02 | Cliente objetivo en una campaña EXTERNO | Rechazado |
| RN-A6-15 | Activar una campaña DIRECTO sin clientes | Rechazado |
| RN-A6-10 | `fecha_fin` anterior a `fecha_inicio` | Rechazado por CHECK |
| RN-A6-09 | Editar una campaña | `actualizado_en` cambia solo |
| RN-A6-13 | Costo y métrica en una campaña FINALIZADA | Rechazados |
| RN-A6-04 | Borrar una campaña con costos | Rechazado por la FK RESTRICT |
| RN-A6-16 | Borrar una campaña sin costos con investigación ligada | La investigación queda con `id_campana` nulo |

Las ocho tablas tienen RLS con la política mínima para `authenticated`; las siete con `actualizado_en` tienen su trigger.
