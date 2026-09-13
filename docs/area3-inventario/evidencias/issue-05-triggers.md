# Issue #5 · Triggers de entrada, salida y ajuste

Migración `supabase/migrations/20260913_0210_a3_triggers.sql` aplicada el 13 de septiembre de 2026 (versión `20260913064317`).

Comprobación con el seed: una entrada de 100 unidades a costo 200 con flete 20 dejó `valor_entrada = 220` y sumó 22,000 al capital (fórmula de I-01, cierra #1).

```sql
SELECT nombre, stock, volumen, valor_entrada, capital_inversion
FROM v_inventario_actual WHERE nombre = 'Tableta Android 10" OEM';
```

| nombre | stock | volumen | valor_entrada | capital_inversion |
| --- | --- | --- | --- | --- |
| Tableta Android 10" OEM | 410 | 500 | 220.00 | 852000.00 |

Capital = 400 × (1850 + 40 + 185) + 100 × (200 + 20) = 830,000 + 22,000 = 852,000. Stock = 500 − 90 vendidas.

Salida excedida rechazada por `fn_salida_producto` con mensaje `RN-A3-01: stock insuficiente para "..." (disponible: 100, solicitado: 101)`; ver `pruebas_area3.sql`.
