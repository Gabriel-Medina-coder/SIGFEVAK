# Glosario

Términos de negocio usados en el proyecto. Cada área mantiene su propio glosario en su `CONTEXTO.md`; aquí van los que cruzan áreas.

| Término | Significado en este proyecto | Área |
| --- | --- | --- |
| Comercializadora | La empresa: compra productos electrónicos y de manufactura nacional y los vende a clientes empresa en todo México | Todas |
| Comercializador / cliente | Empresa que compra a la comercializadora para revender | 2 |
| Agente de ventas | Trabajador que vende a clientes en una zona; cobra sueldo base más comisiones y bonos | 4 |
| Producto | Artículo del catálogo, electrónico o de manufactura nacional | 3 |
| Entrada | Ingreso de mercancía al inventario por compra, importación o producción interna | 1, 3 |
| Salida | Egreso por venta, registrado como renglón de factura | 2, 3 |
| Stock | Existencia disponible ahora mismo. Nunca negativo | 3 |
| Volumen | Acumulado histórico de unidades ingresadas; nunca decrece. No es el stock | 1, 3 |
| Capital de inversión | Dinero acumulado invertido en un producto: (costo + flete + impuestos) × cantidad, sumado por todas sus entradas | 1, 3 |
| Valor de entrada | Costo unitario de la última entrada | 3 |
| Kardex | Historial cronológico de movimientos de un producto | 3 |
| Conciliación | Comparación entre el stock del sistema y el conteo físico | 3 |
| Ajuste de inventario | Corrección del stock derivada de una conciliación, con evidencia | 3 |
| Rotación | Proporción de lo ingresado que ya se vendió | 3, 4, 6 |
| SKU | Código interno único de producto | 1 |
| Lote | Grupo de unidades de una misma producción o importación | 1 |
| BOM | Lista de materiales: qué materias primas y en qué cantidad lleva un producto terminado | 1 |
| Orden de producción | Folio que autoriza fabricar N unidades de un producto con un BOM | 1 |
| Factura | Documento de venta a un cliente, con renglones de detalle, IVA y estado de pago | 2 |
| CFDI | Comprobante Fiscal Digital por Internet; factura electrónica con UUID | 2, 5 |
| Venta cobrada | Factura con estado de pago PAGADO; única base para comisiones | 2, 4 |
| Meta | Monto de ventas sin IVA que un agente debe cobrar en el mes | 4 |
| Comisión | Porcentaje sobre ventas cobradas según el tramo de cumplimiento de meta | 4 |
| Bono | Pago adicional por una condición (meta, cliente nuevo, cobranza, puntualidad, trimestral) | 4 |
| SBC | Salario Base de Cotización ante el IMSS | 4 |
| UMA | Unidad de Medida y Actualización; base para topes fiscales | 4, 5 |
| ISR | Impuesto Sobre la Renta | 4, 5 |
| IVA | Impuesto al Valor Agregado, 16% general | 2, 5 |
| ISN | Impuesto Sobre Nómina, estatal; la tasa depende de la entidad | 4, 5 |
| Obligación | Deber fiscal, aduanal o administrativo con fecha de vencimiento (ISR, IVA, ISN, pedimento, licencia) | 5 |
| Línea de captura | Referencia bancaria que emite la autoridad para pagar una obligación | 5 |
| Pedimento | Documento aduanal de una importación | 5 |
| Fracción arancelaria / NICO | Clasificación de una mercancía importada; determina el IGI | 5 |
| IGI | Impuesto General de Importación | 5 |
| DTA | Derecho de Trámite Aduanero, 8 al millar general | 5 |
| Campaña | Acción de marketing externo o directo, con costo y clientes alcanzados | 6 |
| ROI | Retorno de la inversión de una campaña | 6 |
| RN | Regla de negocio numerada por área: `RN-A3-06` | Todas |
| Vista de contrato | Vista `v_*` que un área publica para que otras la consuman sin tocar sus tablas | Todas |
| RLS | Row Level Security de PostgreSQL; sin políticas, Supabase regresa vacío | Todas |
