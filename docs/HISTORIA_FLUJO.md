# Historia del flujo · una semana en SIGFEVAK

Recorrido de punta a punta por las seis áreas, contado como lo vive la empresa. Cada capítulo lo hace el rol que corresponde, en la app real, con la base reconstruida desde el repositorio: migraciones, seeds de área y dos años de operación simulada (`seed_historico.sql`, D-12). Por eso las pantallas ya traen historia: facturas desde sep 2024, nóminas cerradas, obligaciones pagadas y campañas anteriores. Las cifras salen de la base después de cada paso, no de la pantalla.

- Fecha de grabación: 13 sep 2026, Chrome a 1440 px contra `pnpm dev`.
- Resultado: 15 capítulos, 26 de 26 comprobaciones, sin errores en la consola del navegador.
- Las capturas viven en la carpeta de evidencias de cada área; las generales en `docs/evidencias/`.
- El flujo de negocio y los roles por pantalla están en [FLUJO_APP.md](FLUJO_APP.md).

| Cap. | Quién | Qué pasa | Área |
| --- | --- | --- | --- |
| 1 | Sin sesión | La app no muestra nada sin entrar | Coordinación |
| 2 | Almacén | Recibe 100 bases para laptop | 1 |
| 3 | Almacén | Produce 20 kits de bocina | 1 |
| 4 | Almacén | Revisa catálogo y kardex | 3 |
| 5 | Contador | Da de alta un cliente y le factura | 2 |
| 6 | Contador | Intenta vender más de lo que hay | 2 |
| 7 | Contador | Cobra la factura | 2 |
| 8 | Almacén | Concilia el conteo físico | 3 |
| 9 | Admin y gerente | Calcula, rechaza y revisa la nómina de octubre | 4 |
| 10 | Autorizador | Autoriza, paga y cierra la nómina | 4 |
| 11 | Admin | Genera obligaciones y alertas | 5 |
| 12 | Contador y autorizador | Lleva el IVA de septiembre de pendiente a cerrado | 5 |
| 13 | Admin | Registra un pedimento de importación | 5 |
| 14 | Marketing | Lanza una campaña directa y mide su ROI | 6 |
| 15 | Admin | Ve el resumen general | Coordinación |

---

## 1. Sin sesión no se ve nada

Alguien abre la página de inicio y trata de entrar directo a `/app/nomina`. La app lo manda al login. Además, en la base ninguna tabla ni vista se puede leer sin sesión (D-11, prueba `supabase/tests/coord/seguridad.sql`).

![Inicio](evidencias/historia-01-inicio.png)
![Login](evidencias/historia-02-login.png)

## 2. Almacén recibe mercancía

Llega un pedido de Plásticos Bajío: 100 bases para laptop de aluminio a 200 pesos más 20 de flete.

1. Primero se intenta registrar sin factura ni orden de compra. La base lo rechaza (RN-A1-18).
2. Con la factura PB-8812 capturada, la pantalla calcula en vivo el capital estimado: 100 × (200 + 20) = **22,000**.
3. Al guardar, el trigger del Área 3 mueve el producto; nadie escribe `stock` a mano (RN-A3-06).

| Base para laptop aluminio | Antes | Después |
| --- | --- | --- |
| Stock | 100 | 200 |
| Volumen histórico | 2,064 | 2,164 |
| Capital de inversión acumulado | 461,645.32 | 483,645.32 (+22,000) |
| Valor de entrada por unidad | 220.00 | 220.00 |

![Entrada sin documento](area1-entradas/evidencias/historia-03-entrada-sin-documento.png)
![Capital en vivo](area1-entradas/evidencias/historia-04-entrada-capital-en-vivo.png)
![Entradas registradas](area1-entradas/evidencias/historia-05-entradas-registradas.png)

## 3. Producción interna

Se abre la orden OP-2026-0003 para 20 kits de bocina portátil BT 20W, con su lista de materiales.

1. Se inicia y se capturan consumos: 21 carcasas (1 de merma, rayada) y 20 módulos.
2. Pasa a calidad con 1,000 de mano de obra y 240 de indirectos.
3. Marco Delgado, responsable de la orden, intenta inspeccionarla. La base lo impide: quien produce no inspecciona (separación de funciones).
4. Sofía Campos inspecciona: 19 aprobadas, 1 rechazada (no enciende).
5. Al cerrar, la orden genera una entrada interna de 19 kits a costo real: (21 × 85 + 20 × 140 + 1,000 + 240) / 19 = **306.58** por unidad, proveedor PRODUCCIÓN INTERNA.

| Existencias | Antes | Después |
| --- | --- | --- |
| Carcasas de bocina (MP-CARCASA-BOC) | 128 | 107 |
| Módulos de bocina (MP-MODULO-BOC) | 100 | 80 |
| Kit bocina portátil BT 20W | 48 | 67 |

![Orden con BOM](area1-entradas/evidencias/historia-06-orden-con-bom.png)
![Separación de funciones en calidad](area1-entradas/evidencias/historia-07-calidad-separacion-funciones.png)
![Orden terminada](area1-entradas/evidencias/historia-08-orden-terminada.png)

## 4. Inventario

El catálogo ya refleja la entrada y la producción. El kardex de la base para laptop muestra cada movimiento con su origen.

![Catálogo](area3-inventario/evidencias/historia-09-catalogo.png)
![Kardex](area3-inventario/evidencias/historia-10-kardex.png)

## 5. Cliente nuevo y factura

Tecnología del Golfo quiere comprar y no está registrada. El contador la da de alta desde la misma nueva factura.

1. Captura el RFC incompleto (`TGO150820KJ`): la pantalla lo rechaza (RN-A2-05).
2. Con el RFC correcto se guarda como **COM-000029** y queda seleccionada en la factura (RN-A2-11).
3. Agente Patricia Leal; renglón de 30 bases a 450.
4. El trigger recalcula la factura **FAC-000984**: subtotal 13,500, IVA 2,160, total **15,660**, vence el 13 oct 2026. El stock baja de 200 a 170.

![RFC inválido](area2-contabilidad/evidencias/historia-11-alta-cliente-rfc-invalido.png)
![Cabecera con cliente nuevo](area2-contabilidad/evidencias/historia-12-cabecera-con-cliente-nuevo.png)
![Factura con renglón](area2-contabilidad/evidencias/historia-13-factura-con-renglon.png)

## 6. Venta sin stock

En la misma factura se intenta agregar 500 bases. La base responde en español: *Stock insuficiente para "Base para laptop aluminio" (disponible: 170, solicitado: 500)*. Lo capturado se conserva para corregir.

![Rechazo por stock](area2-contabilidad/evidencias/historia-14-rechazo-por-stock.png)

## 7. Cobro

El cliente paga. La factura pasa a **PAGADO** y la base pone la fecha de cobro (13 sep 2026), que es la que usa la nómina para comisiones.

![Factura pagada](area2-contabilidad/evidencias/historia-15-factura-pagada.png)
![Registro de facturas](area2-contabilidad/evidencias/historia-16-registro-de-facturas.png)

## 8. Conciliación

En el conteo semanal hay 168 bases y el sistema dice 170. El almacén registra la diferencia con su motivo (dos piezas golpeadas); el ajuste deja el stock en 168 y la discrepancia queda visible.

![Conciliación](area3-inventario/evidencias/historia-17-conciliacion-diferencia.png)
![Discrepancias](area3-inventario/evidencias/historia-18-discrepancias.png)

## 9. Nómina de octubre

1. Admin captura las metas de octubre de los cinco agentes y abre el periodo.
2. Calcula: el periodo queda **CALCULADO**.
3. El gerente de ventas lo rechaza con motivo: la meta de Miguel Torres cambia a 180,000. Regresa a **ABIERTO** (RN-A4-13, un retroceso sin comentario no pasa).
4. Admin corrige la meta y recalcula; el gerente revisa y aprueba: **REVISADO**.

![Metas de octubre](area4-nomina/evidencias/historia-19-metas-octubre.png)
![Periodo calculado](area4-nomina/evidencias/historia-20-periodo-calculado.png)
![Rechazo con comentario](area4-nomina/evidencias/historia-21-rechazo-con-comentario.png)

## 10. Quien calcula no autoriza

Admin calculó, así que ve el botón Autorizar deshabilitado (RN-A4-15). Entra el autorizador, autoriza, registra el pago y cierra. El periodo termina **CERRADO** con cuatro firmas distintas.

| Agente | Percepciones | Deducciones | Neto |
| --- | --- | --- | --- |
| Miguel Torres | 15,742.70 | 1,788.48 | 13,954.22 |
| Jorge Mendoza | 12,704.00 | 1,252.58 | 11,451.42 |
| Verónica Castillo | 12,704.00 | 1,252.58 | 11,451.42 |
| Patricia Leal | 12,704.00 | 1,252.58 | 11,451.42 |
| Andrés Fuentes | 12,038.40 | 1,134.08 | 10,904.32 |

![Quien calcula no autoriza](area4-nomina/evidencias/historia-22-quien-calcula-no-autoriza.png)
![Periodo cerrado](area4-nomina/evidencias/historia-23-periodo-cerrado.png)
![Recibo](area4-nomina/evidencias/historia-24-recibo.png)

## 11. Obligaciones del mes

Admin marca vencidas, genera alertas y crea las obligaciones de noviembre 2026 (2 nuevas). Correrlo dos veces no duplica (RN-A5-21).

![Administración fiscal](area5-fiscal/evidencias/historia-25-administracion-fiscal.png)
![Obligaciones](area5-fiscal/evidencias/historia-26-obligaciones.png)

## 12. IVA de septiembre, de pendiente a cerrado

La obligación arranca **PENDIENTE** con un estimado de 254,784 tomado del IVA trasladado del mes.

1. Contador: registra el monto determinado de **44,784**, presenta la declaración (acuse ACUSE-2609-IVA) y genera la línea de captura. Queda en **LINEA_GENERADA** y el contador no ve Autorizar: es una obligación crítica.
2. Autorizador: autoriza y el monto queda congelado.
3. Contador: registra el pago por BBVA con su comprobante.
4. Autorizador: concilia y cierra. Queda inmutable (RN-A5-24).

La bitácora fiscal guarda una línea por cada paso: alta, calculado, presentado, línea generada, autorizado, pagado, conciliado y cerrado.

![Orden de pago dirigido](area5-fiscal/evidencias/historia-27-orden-de-pago-dirigido.png)
![Pago con comprobante](area5-fiscal/evidencias/historia-28-pago-con-comprobante.png)
![IVA cerrado](area5-fiscal/evidencias/historia-29-iva-cerrado.png)

## 13. Importación

Pedimento 26 47 3891 6004588 por Manzanillo: 400 auriculares BT desde China, valor aduanero 120,000. La base calcula las contribuciones:

| Concepto | Cálculo | Monto |
| --- | --- | --- |
| IGI | 120,000 × 15 % | 18,000.00 |
| DTA | 120,000 × 0.8 % | 960.00 |
| IVA de importación | (120,000 + 18,000 + 960) × 16 % | 22,233.60 |
| Total | | 41,193.60 |

![Captura del pedimento](area5-fiscal/evidencias/historia-30-pedimento-captura.png)
![Pedimentos](area5-fiscal/evidencias/historia-31-pedimentos.png)

## 14. Marketing

Marketing crea la campaña directa "Reactivación Golfo septiembre" con 5,000 de presupuesto.

1. Intenta activarla sin clientes objetivo: no se puede.
2. Agrega a Tecnología del Golfo (convertido) y Distribuidora Bajío (contactado) por WhatsApp. Activa.
3. Registra un costo de 6,000: se rechaza y muestra el restante de 5,000. Lo corrige a 1,800.
4. La campaña atribuye las facturas pagadas de sus clientes.

| Campaña | Valor |
| --- | --- |
| Estatus | ACTIVA |
| Gasto | 1,800 de 5,000 |
| Conversión | 1 de 2 (50 %) |
| Ventas atribuidas sin IVA | 34,225 en 2 facturas |
| ROI real | (34,225 − 1,800) / 1,800 = 18.01 |

![Tablero](area6-marketing/evidencias/historia-32-tablero.png)
![Activar sin clientes](area6-marketing/evidencias/historia-33-activar-sin-clientes.png)
![Clientes objetivo](area6-marketing/evidencias/historia-34-clientes-objetivo.png)
![Costo excede presupuesto](area6-marketing/evidencias/historia-35-costo-excede-presupuesto.png)
![ROI real](area6-marketing/evidencias/historia-36-roi-real.png)

## 15. Resumen general

Al final de la semana, la coordinación ve todo en una pantalla: capital de inversión acumulado (24.97 millones en dos años), volumen comercializado (128,819 unidades), 24 clientes activos y 987,392 por cobrar, obligaciones pendientes, nómina del último periodo autorizado, inversión en marketing y cartera vencida.

![Resumen general](evidencias/historia-37-resumen-general.png)
