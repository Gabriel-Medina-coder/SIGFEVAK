# Issue #39 · Integración con las áreas 4 y 6

Fecha: 13 sep 2026, sobre la base con dos años de operación (D-12).

## Quién lee las vistas del área 1

| Vista | Consumidor | Dónde | Para qué |
| --- | --- | --- | --- |
| `v_mano_obra_produccion` | Área 4 · Nómina | `src/services/area4/nomina.js` (`obtenerManoObraProduccion`), pestaña Reportes | Mano de obra directa por orden terminada y responsable; insumo futuro de bonos de productividad, sin cambiar el cálculo actual (tarea 3 del área 4) |
| `v_ordenes_produccion` | Área 6 · Marketing | `src/services/area6/referencias.js` (`listarProduccionProyectada`), Tablero | Producción en camino (órdenes planeadas, en proceso y en calidad) |
| `v_reabastecimiento` | Área 6 · Marketing | `src/services/area6/referencias.js` (`listarBajoStockMinimo`), Tablero | Productos bajo stock mínimo: no promocionarlos todavía |

Capturas:

- [Nómina · mano de obra de producción de sep 2026](../../area4-nomina/evidencias/issue-39-mano-de-obra-produccion.png): OP-2026-0003 (19 unidades, $1,000.00) y OP-2026-0001 (48 unidades, $2,500.00), responsable Marco Delgado.
- [Marketing · producción en camino y bajo stock mínimo](../../area6-marketing/evidencias/issue-39-produccion-y-bajo-stock.png): OP-2026-0002 con 40 kits en proceso y 8 productos bajo su mínimo.

## `v_entradas_area1` contra `v_entradas_detalle`

La primera comparación encontró 15 de 25 meses con 1 centavo de diferencia: `v_entradas_area1` sumaba el capital sin redondear y `v_entradas_detalle` lo redondea por entrada, igual que `productos.capital_inversion`. La migración `20260913_0920_a3_capital_redondeado_por_entrada` corrige la vista del área 3.

| Periodo | `v_entradas_area1` | `v_entradas_detalle` | Diferencia |
| --- | --- | --- | --- |
| 2026-09 | 468,535 | 468,535 | 0.00 |
| 2026-08 | 5,914,250 | 5,914,250 | 0.00 |
| 2026-07 | 1,075,762 | 1,075,762 | 0.00 |
| Todos (25 meses) | 24,972,313.43 | 24,972,313.43 | 0 meses con diferencia |

El total también coincide con la suma de `productos.capital_inversion` (24,972,313.43). La comparación queda como prueba permanente en `supabase/tests/area1/pruebas_area1.sql`.
