# Issue #51 · Seed del área

`supabase/seed/seed_area2.sql` aplicado el 13 de septiembre de 2026, dos veces seguidas sin duplicar. Resultado: 11 clientes (1 inactivo, 1 con 15 días de crédito), 5 agentes del seed base, 21 facturas (pagadas con `fecha_cobro`, pendientes, 1 parcial, 1 cancelada, 2 vencidas).

## Ejemplo de la sección 10 · FAC-000016

```sql
SELECT folio, nombre_empresa, fecha, fecha_vencimiento, fecha_cobro, subtotal, iva, valor_total, estado_pago
FROM facturas JOIN clientes USING (id_cliente) WHERE folio = 'FAC-000016';
```

| folio | cliente | fecha | fecha_vencimiento | fecha_cobro | subtotal | iva | valor_total | estado_pago |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FAC-000016 | Distribuidora Bajío S.A. de C.V. | 2026-09-14 | 2026-10-14 | 2026-09-20 | 20725.00 | 3316.00 | 24041.00 | PAGADO |

El seed nunca mandó `subtotal`, `iva`, `valor_total`, `folio` ni `fecha_cobro`: los pusieron los triggers. Los stocks del ejemplo (310 a 300 en tabletas, 88 auriculares) son ilustrativos; el rechazo por stock se prueba en `pruebas_area2.sql` con 500 cámaras sobre 50 en existencia.

## Ejemplo del área 4 · Jorge Mendoza, 2026-09

```sql
SELECT TO_CHAR(fecha_cobro, 'YYYY-MM') periodo, SUM(subtotal) cobrado_sin_iva, COUNT(*) facturas
FROM facturas WHERE estado_pago = 'PAGADO' AND id_agente = 1 GROUP BY 1 ORDER BY 1;
```

| periodo | cobrado_sin_iva | facturas |
| --- | --- | --- |
| 2026-08 | 576200.00 | 2 |
| 2026-09 | 560000.00 | 3 |

Clientes nuevos de Jorge en 2026-09 (primera factura pagada en ese periodo): Norte Digital y Distribuidora Bajío, es decir 2. Cartera vencida de Jorge: 3.00 % (`v_cartera_agente`).
