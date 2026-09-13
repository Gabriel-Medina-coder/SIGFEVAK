# Issues #113, #114, #115 y #116 · Seed y vistas

`supabase/seed/seed_area6.sql` aplicado el 13 de septiembre de 2026, dos veces sin duplicar: 7 canales, 3 proveedores, 4 campañas, 2 investigaciones y clientes objetivo en los cinco estados de contacto. Migración `20260913_0740_a6_vistas.sql`.

## Caso A · `v_campana_resumen`

```sql
SELECT nombre, presupuesto_asignado, gasto_total, presupuesto_restante, pct_ejercido, leads_generados, conversiones, ingreso_atribuido, roi
FROM v_campana_resumen WHERE nombre = 'Lanzamiento Smartwatch Pro';
```

| nombre | presupuesto | gasto_total | restante | pct_ejercido | leads | conversiones | ingreso_atribuido | roi |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Lanzamiento Smartwatch Pro | 50000.00 | 45000.00 | 5000.00 | 90.00 | 310 | 48 | 132000.00 | 1.9333 |

## Caso B · `v_directo_desempeno` y `v_ventas_atribuidas_campana`

| nombre | total_objetivo | total_contactados | total_convertidos | tasa_conversion_pct |
| --- | --- | --- | --- | --- |
| Promo revendedores agosto | 5 | 4 | 2 | 40.00 |

| nombre | facturas_atribuidas | ventas_atribuidas_sin_iva | gasto_total | roi_real |
| --- | --- | --- | --- | --- |
| Promo revendedores agosto | 5 | 771200.00 | 11200.00 | 67.8571 |

Las cinco facturas son las pagadas en agosto de los cinco clientes objetivo (Elektra 147,200; TechMex 429,000; Norte Digital 72,000; Distribuidora Bajío 65,000; RadioShack 58,000), como define RN-A6-14. Los montos del ejemplo original del contexto venían de los totales provisionales del seed base; la sección 10 quedó actualizada con estos.

## `v_costos_por_canal`

| canal | categoria | campanas_relacionadas | gasto_total |
| --- | --- | --- | --- |
| Redes sociales | DIGITAL | 1 | 37000.00 |
| Evento | EVENTOS | 1 | 24900.00 |
| WhatsApp | DIRECTO | 1 | 8200.00 |
| Radio | TRADICIONAL | 1 | 8000.00 |
| Llamada | DIRECTO | 1 | 3000.00 |

`v_productos_baja_rotacion_campana` lee `v_rotacion` del área 3 y lista los productos con rotación menor a 30 % sin campaña vigente.
