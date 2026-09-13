# Issues #69, #70 y #71 · Vistas

Migración `20260913_0530_a4_vistas.sql` aplicada el 13 de septiembre de 2026.

```sql
SELECT zona, nombre, periodo, monto_meta, pct_cumplimiento, ventas_cobradas FROM v_desempeno_agente_zona ORDER BY id_agente;
```

| zona | nombre | periodo | monto_meta | pct_cumplimiento | ventas_cobradas |
| --- | --- | --- | --- | --- | --- |
| Sureste | Jorge Mendoza | 2026-09 | 500000.00 | 112.00 | 560000.00 |
| Sureste | Verónica Castillo | 2026-09 | 200000.00 | 0.00 | 0 |
| Centro | Andrés Fuentes | 2026-09 | 250000.00 | 84.00 | 210000.00 |
| Centro | Patricia Leal | 2026-09 | 300000.00 | 24.00 | 72000.00 |
| Frontera Norte | Miguel Torres | 2026-09 | 150000.00 | 43.33 | 65000.00 |

```sql
SELECT nombre, percepciones, deducciones, neto FROM v_nomina_totales ORDER BY id_agente;
```

| nombre | percepciones | deducciones | neto |
| --- | --- | --- | --- |
| Jorge Mendoza | 33004.00 | 5929.75 | 27074.25 |
| Verónica Castillo | 12704.00 | 1252.58 | 11451.42 |
| Andrés Fuentes | 15644.00 | 2045.89 | 13598.11 |
| Patricia Leal | 13924.00 | 1476.82 | 12447.18 |
| Miguel Torres | 16892.70 | 2024.16 | 14868.54 |

`v_ventas_cobradas_agente`, `v_clientes_nuevos_agente`, `v_cumplimiento_meta`, `v_recibo_nomina`, `v_sbc_bimestral` y `v_retenciones_area5` regresan datos del seed (ver `issue-66-seed-ejemplo-10.md`).
