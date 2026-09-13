# Issues #66, #76 y #77 · Seed y ejemplo de la sección 10

`supabase/seed/seed_area4.sql` aplicado el 13 de septiembre de 2026, dos veces sin duplicar. Deja el periodo mensual 2026-09 calculado por `admin@sigfevak.mx`, revisado por `gerente@sigfevak.mx` y autorizado por `autorizador@sigfevak.mx` (RN-A4-15).

## Recibo de Jorge Mendoza, periodo 2026-09

```sql
SELECT concepto, clave_sat, monto, gravado, exento, integra_sbc FROM v_recibo_nomina WHERE nombre = 'Jorge Mendoza' AND id_periodo = 1;
```

| concepto | clave_sat | monto | gravado | exento | integra_sbc |
| --- | --- | --- | --- | --- | --- |
| SUELDO | 001 | 10640.00 | 10640.00 | 0.00 | sí |
| COMISION | 028 | 16800.00 | 16800.00 | 0.00 | sí |
| BONO_META | 038 | 2500.00 | 2500.00 | 0.00 | sí |
| BONO_CLIENTE_NUEVO | 038 | 1000.00 | 1000.00 | 0.00 | sí |
| BONO_COBRANZA | 038 | 1000.00 | 1000.00 | 0.00 | sí |
| PREMIO_PUNTUALIDAD | 010 | 1064.00 | 0.00 | 1064.00 | no |
| ISR | 002 | 5169.58 | | | |
| IMSS_OBRERO | 001 | 760.17 | | | |

Total de percepciones 33,004.00, igual al ejemplo. Cumplimiento 560,000 / 500,000 = 112 % (tramo 100 a 119.99 %, 3 %). Clientes nuevos: Norte Digital y Distribuidora Bajío. Cartera vencida 3.00 % (`v_cartera_agente`).

ISR con la tarifa cargada: gravado 31,940 cae en el rango de 31,236.50 a 49,233.00: 5,004.12 + (31,940 − 31,236.50) × 23.52 % = 5,169.58. IMSS obrero: 31,940 × 2.38 % = 760.17. Neto 27,074.25.

## Contrato con el área 5

```sql
SELECT entidad_federativa, isr_retenido, imss_obrero, base_isn, isn_estimado FROM v_retenciones_area5;
```

| entidad | isr_retenido | imss_obrero | base_isn | isn_estimado |
| --- | --- | --- | --- | --- |
| Ciudad de México | 2844.31 | 678.40 | 28504.00 | 0.00 |
| Baja California | 1654.01 | 370.15 | 15552.45 | 0.00 |
| Chiapas | 6145.13 | 1037.20 | 43580.00 | 871.60 |

Solo Chiapas tiene tasa de ISN cargada (2 %, valor del contexto del Área 5); las demás entidades quedan en 0 hasta que el Área 5 publique `v_tasas_isn` (I-03).
