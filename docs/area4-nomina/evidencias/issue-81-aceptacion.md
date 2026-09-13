# Issue #81 · Pruebas de aceptación y de punta a punta

Fecha: 13 sep 2026, sobre la base con dos años de operación (D-12).

## Ejemplo de la sección 10

Jorge Mendoza, zona general, salario $350, meta $500,000, $560,000 cobrados, 2 clientes nuevos, cartera vencida 3 % y sin retardos. Lo verifica `supabase/tests/area4/pruebas_area4.sql`:

| Concepto | Monto |
| --- | --- |
| Sueldo | 10,640.00 |
| Comisión (3 %) | 16,800.00 |
| Bono de meta | 2,500.00 |
| Clientes nuevos | 1,000.00 |
| Cobranza sana | 1,000.00 |
| Premio de puntualidad | 1,064.00 |
| **Total** | **33,004.00** |

## Paralelo en Excel

[issue-81-paralelo-nomina-sep-2026.xlsx](issue-81-paralelo-nomina-sep-2026.xlsx) recalcula con fórmulas de Excel las percepciones y la cuota obrera del IMSS de los 5 agentes del periodo de septiembre 2026 (sueldo, cumplimiento, tramo, comisión, bonos y puntualidad) y las compara con lo que guardó el sistema.

| Agente | Percepciones Excel | Sistema | Diferencia | IMSS Excel | Sistema | Diferencia |
| --- | --- | --- | --- | --- | --- | --- |
| Jorge Mendoza | 33,004.00 | 33,004.00 | 0.00 | 760.17 | 760.17 | 0.00 |
| Verónica Castillo | 12,704.00 | 12,704.00 | 0.00 | 277.03 | 277.03 | 0.00 |
| Andrés Fuentes | 15,644.00 | 15,644.00 | 0.00 | 372.33 | 372.33 | 0.00 |
| Patricia Leal | 13,924.00 | 13,924.00 | 0.00 | 306.07 | 306.07 | 0.00 |
| Miguel Torres | 16,892.70 | 16,892.70 | 0.00 | 370.15 | 370.15 | 0.00 |

## Casos límite (pruebas SQL)

| Caso | Resultado esperado | Estado |
| --- | --- | --- |
| Agente sin meta | Bloquea el cálculo (RN-A4-03) | Pasa |
| Agente sin esquema | Usa su tasa de respaldo y queda `SIN_ESQUEMA` en bitácora (RN-A4-05) | Pasa |
| Factura cobrada en un periodo autorizado que se cancela | Crea el ajuste negativo con la tasa pagada (RN-A4-08) | Pasa |
| Factura cancelada que nunca se cobró | No crea ajuste | Pasa |
| Zona ZLFN con salario menor a 440.87 | Se rechaza; con 440.87 exacto se acepta (RN-A4-01) | Pasa |
| Cumplimiento de 100 % exacto | Cae en el tramo del 3 % (RN-A4-04) | Pasa |
| Quien calcula intenta autorizar | Se rechaza (RN-A4-15) | Pasa |

La cancelación no tenía disparador en la base; se agregó con la migración `20260913_0900_a4_ajuste_por_cancelacion`.

## Flujo desde la app

- Alta de agente: la zona fronteriza con salario de 400 se rechaza con el mínimo de 440.87; en zona Centro con 350 se guarda y recibe su meta de noviembre. [Rechazo](issue-81-zlfn-bajo-minimo.png) · [Alta](issue-81-alta-de-agente.png) · [Meta](issue-81-meta-agente-nuevo.png)
- Periodo con varios usuarios: el administrador calcula, el gerente rechaza con comentario y luego revisa, quien calculó ve Autorizar deshabilitado, el autorizador autoriza, paga y cierra, y se consulta el recibo. Capítulos 9 y 10 de la [historia del flujo](../../HISTORIA_FLUJO.md) con sus [capturas](README.md). Sin errores en consola.
