# Issues #91, #94, #96 · Funciones diarias, importaciones, licencias y seed

`supabase/seed/seed_area5.sql` aplicado el 13 de septiembre de 2026, dos veces sin duplicar. Genera las obligaciones de julio a octubre con `fn_generar_obligaciones_periodo`, corre `fn_marcar_vencidas`, `fn_generar_alertas` y `fn_actualizar_estado_licencias`.

## Ejemplo 10.1 · IVA de julio de principio a fin

```sql
SELECT t.clave, o.periodo, o.monto_estimado, o.monto_final, o.estado, o.fecha_cierre
FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion) WHERE t.clave = 'IVA_MENSUAL' AND o.periodo = '2026-07';
```

| clave | periodo | monto_estimado | monto_final | estado | fecha_cierre |
| --- | --- | --- | --- | --- | --- |
| IVA_MENSUAL | 2026-07 | 110000.00 | 110000.00 | CERRADO | 2026-08-17 |

Pasó por CALCULADO, PRESENTADO (declaración y acuse), LINEA_GENERADA, AUTORIZADO (autorizador distinto del contador), PAGADO (SPEI con comprobante), CONCILIADO y CERRADO. La bitácora registra AUTORIZAR, PAGADO, CONCILIADO y CERRAR.

## Ejemplo 10.2 · Pedimento de 200 tabletas

```sql
SELECT numero_pedimento, valor_aduanero, igi, dta, iva_importacion, total_contribuciones FROM importaciones WHERE numero_pedimento = '26 47 3891 6004520';
```

| numero_pedimento | valor_aduanero | igi | dta | iva_importacion | total_contribuciones |
| --- | --- | --- | --- | --- | --- |
| 26 47 3891 6004520 | 500000.00 | 75000.00 | 4000.00 | 92640.00 | 171640.00 |

`v_impuestos_importacion_producto` da 395.00 por unidad sin IVA para el área 1. La obligación del pedimento quedó con `monto_estimado` 171,640 y cerrada con su pago.

## Estados del seed

| clave | periodo | estado |
| --- | --- | --- |
| IVA_MENSUAL | 2026-07 | CERRADO |
| ISR_PROV | 2026-07 | VENCIDO (marcada por `fn_marcar_vencidas`, con alerta VENCIDA) |
| IVA_MENSUAL | 2026-08 | LINEA_GENERADA |
| ISR_PROV | 2026-08 | CALCULADO (sugerencia con coeficiente de utilidad) |
| ISN_CHIAPAS | 2026-10 | PENDIENTE, 871.60 = base 43,580 del área 4 × 2 % |
| PEDIMENTO 6004520 | | CERRADO |
| PEDIMENTO 6004521 | | PAGADO, ligado a la entrada SZ-2026-0917 del área 1 |

Licencias: Protección Civil VENCIDA, uso de suelo POR_VENCER (17 días), funcionamiento y SIEM VIGENTE. Alertas: 15, 7, 3, 1 y 0 días por obligación abierta y VENCIDA por la incumplida; una segunda corrida no duplica (RN-A5-21).
