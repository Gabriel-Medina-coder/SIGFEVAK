# Issues #45, #46, #47 y #48 · Columnas aditivas, folios, recálculo y estado de pago

Migraciones aplicadas al proyecto el 13 de septiembre de 2026:

| Migración | Issue |
| --- | --- |
| `20260913_0400_a2_columnas_aditivas.sql` | #45 |
| `20260913_0410_a2_folios_iva_validacion.sql` | #46 |
| `20260913_0420_a2_recalculo_factura.sql` | #47 |
| `20260913_0430_a2_estado_pago.sql` | #48 |

Consistencia de todas las facturas después del seed:

```sql
SELECT (SELECT count(*) FROM facturas) facturas,
       (SELECT count(*) FROM facturas WHERE folio IS NULL OR fecha_vencimiento IS NULL) sin_folio_o_vencimiento,
       (SELECT count(*) FROM facturas f WHERE valor_total <> subtotal + iva
           OR subtotal <> (SELECT COALESCE(sum(importe),0) FROM detalle_factura d WHERE d.id_factura = f.id_factura)) inconsistentes,
       (SELECT count(*) FROM facturas WHERE estado_pago = 'PAGADO' AND fecha_cobro IS NULL) pagadas_sin_cobro;
```

| facturas | sin_folio_o_vencimiento | inconsistentes | pagadas_sin_cobro |
| --- | --- | --- | --- |
| 21 | 0 | 0 | 0 |

Las reglas se comprueban en `supabase/tests/area2/pruebas_area2.sql`: RFC inválido y duplicado rechazados (RN-A2-05), folios `COM-` y `FAC-` generados (RN-A2-11), vencimiento a 20 días del cliente de prueba (RN-A2-09), `PAGADO` con total 0 rechazado (RN-A2-04), `fecha_cobro` puesta y limpiada por el trigger (RN-A2-08), renglón de factura pagada rechazado (RN-A2-12), cliente inactivo sin facturas nuevas (RN-A2-10).
