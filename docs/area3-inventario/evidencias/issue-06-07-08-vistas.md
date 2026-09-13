# Issues #6, #7 y #8 · Vistas del área y de contrato

Migración `supabase/migrations/20260913_0220_a3_vistas.sql` aplicada el 13 de septiembre de 2026 (versión `20260913064318`).

## `v_entradas_area1` (#7, contrato con el área 1)

```sql
SELECT * FROM v_entradas_area1;
```

| periodo | tipo | volumen_comercializacion | capital_inversion | valor_promedio_entrada |
| --- | --- | --- | --- | --- |
| 2026-08 | ELECTRONICO | 3400 | 4675750.00 | 1633.00 |
| 2026-08 | MANUFACTURA | 7100 | 1238500.00 | 218.50 |
| 2026-09 | ELECTRONICO | 900 | 334000.00 | 305.00 |

## `v_discrepancias` (#6)

```sql
SELECT nombre, stock_sistema, conteo_fisico, diferencia, motivo FROM v_discrepancias;
```

| nombre | stock_sistema | conteo_fisico | diferencia | motivo |
| --- | --- | --- | --- | --- |
| Auriculares BT TW-55 | 900 | 898 | -2 | Merma detectada en conteo físico |

`v_inventario_actual`, `v_kardex`, `v_rotacion` y `v_salidas_area2` (#8) regresan datos del seed; firmas publicadas en `docs/MODELO_DATOS.md`.
