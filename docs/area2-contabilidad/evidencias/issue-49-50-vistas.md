# Issues #49 y #50 · Vistas del equipo y de contrato

Migración `20260913_0440_a2_vistas.sql` aplicada el 13 de septiembre de 2026.

## `v_cartera_agente` (contrato con el área 4, I-02)

```sql
SELECT * FROM v_cartera_agente ORDER BY id_agente;
```

| id_agente | cartera_total | cartera_vencida | pct_vencida |
| --- | --- | --- | --- |
| 1 | 394400.00 | 11832.00 | 3.00 |
| 2 | 90944.00 | 0 | 0.00 |
| 3 | 165648.00 | 21576.00 | 13.03 |
| 4 | 215760.00 | 0 | 0.00 |
| 5 | 120640.00 | 0 | 0.00 |

## `v_iva_trasladado_periodo` (contrato con el área 5, I-07)

| periodo | numero_facturas | facturas_con_cfdi | subtotal | iva_trasladado | total |
| --- | --- | --- | --- | --- | --- |
| 2026-07 | 1 | 0 | 18600.00 | 2976.00 | 21576.00 |
| 2026-08 | 8 | 0 | 897400.00 | 143584.00 | 1040984.00 |
| 2026-09 | 11 | 0 | 1592400.00 | 254784.00 | 1847184.00 |

La factura cancelada (FAC-000006) no cuenta.

## `v_clientes_activos` (contrato con el área 6, I-10)

10 clientes; el inactivo `Comercial Antigua del Centro` no aparece.

## `v_facturas_pendientes`

| folio | cliente | agente | fecha_vencimiento | dias_vencidos | valor_total |
| --- | --- | --- | --- | --- | --- |
| FAC-000021 | Ramírez & Hijos Comercial S.A. | Andrés Fuentes | 2026-08-19 | 25 | 21576.00 |
| FAC-000019 | COPPEL Distribución S.A. de C.V. | Jorge Mendoza | 2026-08-31 | 13 | 11832.00 |

`v_clientes_resumen` y `v_ventas_agente` regresan datos del seed. `v_salidas_area2` del área 3 conserva su firma; solo cambió por los renglones nuevos del seed.
