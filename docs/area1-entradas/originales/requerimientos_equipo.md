# Requerimientos del Sistema

**Módulo:** Registro de Entradas de Productos Electrónicos y Manufactura para Producción Nacional


---

## Parte I — Requerimientos Base del Módulo

### 1. Contexto y alcance

Este módulo cubre dos procesos que están directamente conectados dentro del sistema general:

1. **Entrada de productos electrónicos** que llegan a la comercializadora (compra a proveedores, importación, etc.)
2. **Manufactura para producción nacional**: transformación de materias primas/insumos en un producto terminado dentro del país.

Ambos procesos alimentan la misma base de datos de inventario, por lo que se diseñan de forma que un producto pueda entrar al sistema por dos vías distintas:

- **Vía A – Compra directa:** el producto entra ya terminado (ej. se importa o se compra a un tercero).
- **Vía B – Manufactura nacional:** el producto se arma/fabrica internamente a partir de materias primas registradas.

Se incluyen también los atributos de valor de capital de inversión y volumen de comercialización, que el equipo pidió explícitamente rastrear, ya que son datos que alimentan el módulo contable/financiero (necesidad general 1) y el de marketing/ventas (necesidad general 5).

### 2. Actividad 1 — Campos del "Registro de Entrada de Productos Electrónicos"

#### 2.1 Identificación del producto

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| SKU | Texto/código alfanumérico | Sí | Identificador único interno |
| Código de barras / EAN / UPC | Texto numérico | Sí (si aplica) | Para lectura con escáner |
| Número de serie | Texto alfanumérico | Sí (electrónicos) | Único por unidad física |
| Número de lote | Texto/código | Sí | Agrupa unidades de una misma producción/importación |
| Nombre del producto | Texto | Sí | |
| Categoría / subcategoría | Texto (lista controlada) | Sí | Ej: Audio > Bocinas |
| Marca | Texto | Sí | |
| Modelo | Texto | Sí | |
| Descripción técnica | Texto largo | No | Especificaciones relevantes |
| Unidad de medida | Lista (pieza, caja, kit) | Sí | |

#### 2.2 Datos de origen y proveedor

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| Proveedor (ID y nombre) | Relación con tabla Proveedores | Sí | |
| País de origen | Texto | Sí | Relevante para aduanas |
| Número de orden de compra | Texto/código | Sí | Vincula con contabilidad |
| Número de factura del proveedor | Texto/código | Sí | Vincula con necesidad contable general |
| Fecha de emisión de factura | Fecha | Sí | |
| Documento de importación (si aplica) | Referencia/archivo | No | Pedimento, guía, etc. |

#### 2.3 Datos de recepción (entrada física)

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| Fecha de entrada | Fecha/hora | Sí | |
| Responsable de recepción | Usuario del sistema | Sí | Trazabilidad |
| Almacén / bodega destino | Relación con tabla Almacenes | Sí | |
| Ubicación física (rack/anaquel) | Texto/código | No | |
| Cantidad recibida | Número entero | Sí | |
| Cantidad esperada (según orden) | Número entero | Sí | Para detectar faltantes/sobrantes |
| Estado de la mercancía | Lista (buen estado, dañado, incompleto) | Sí | |
| Evidencia fotográfica | Archivo/imagen | No | Para reclamaciones |
| Observaciones de recepción | Texto | No | |

#### 2.4 Datos financieros y de valor

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| Costo unitario de compra | Moneda | Sí | Sin impuestos |
| Impuestos/aranceles aplicados | Moneda | Sí | Conecta con módulo de impuestos aduanales |
| Costo total del lote | Moneda (calculado) | Sí | Cantidad × costo unitario + impuestos |
| Moneda de la transacción | Lista (MXN, USD, etc.) | Sí | |
| Tipo de cambio aplicado | Número decimal | Condicional | Si la moneda no es local |
| Valor de capital de inversión | Moneda (calculado) | Sí | Suma del capital inmovilizado en ese lote/entrada |
| Precio de venta sugerido | Moneda | No | Referencia para ventas |

#### 2.5 Garantía y ciclo de vida

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| Fecha de fabricación | Fecha | Sí (si el proveedor la reporta) | |
| Fecha de vencimiento de garantía | Fecha | Sí | |
| Condiciones de garantía | Texto | No | |
| Vida útil estimada | Número (meses/años) | No | |

#### 2.6 Estado y trazabilidad en sistema

| Campo | Tipo de dato | Obligatorio | Notas |
|---|---|---|---|
| Estatus del inventario | Lista (disponible, reservado, en tránsito, dado de baja) | Sí | |
| Historial de movimientos | Log automático | Sí | Cada entrada/salida se registra con timestamp y usuario |
| Vinculación con salida (si ya se vendió) | Relación con módulo de ventas | No | |

### 3. Actividad 2 — Flujo de "Manufactura para Producción Nacional"

Este flujo aplica cuando el producto no llega terminado, sino que se arma o fabrica internamente.

#### 3.1 Etapas del flujo y datos requeridos en cada una

**Etapa 1 — Registro de materias primas / insumos**
- SKU de materia prima
- Proveedor de la materia prima
- Cantidad recibida y unidad de medida
- Costo unitario de materia prima
- Lote de materia prima
- Almacén de insumos (separado del almacén de producto terminado)

**Etapa 2 — Orden de producción (planeación)**
- Número de orden de producción (folio único)
- Producto terminado a fabricar (SKU destino)
- Fecha programada de inicio y fin
- Cantidad planeada a producir
- Lista de materiales / BOM (Bill of Materials): qué materias primas y en qué cantidad se necesitan por unidad de producto terminado
- Responsable de la orden de producción

**Etapa 3 — Consumo de materia prima (ejecución)**
- Cantidad real de materia prima consumida por orden
- Mermas o desperdicio (cantidad y motivo)
- Fecha de consumo
- Turno/línea de producción (si aplica)

**Etapa 4 — Proceso de transformación**
- Etapas internas del proceso (ej: ensamblaje, soldadura, calibración, control de calidad)
- Tiempo estándar vs. tiempo real por etapa
- Responsable/operador por etapa
- Máquina o estación de trabajo utilizada (si aplica)

**Etapa 5 — Control de calidad**
- Resultado de inspección (aprobado/rechazado)
- Motivo de rechazo (si aplica)
- Responsable de control de calidad
- Número de unidades aprobadas vs. rechazadas

**Etapa 6 — Registro de producto terminado**
- Nuevo SKU / número de serie del producto terminado
- Lote de producción
- Fecha de terminación
- Costo de producción total (materia prima + mano de obra + costos indirectos)
- Costo unitario de manufactura (calculado)
- Cantidad final ingresada a almacén de producto terminado

**Etapa 7 — Entrada a inventario de producto terminado**
- Se conecta directamente con los campos de la sección 2 (Registro de Entrada), usando como "proveedor" la propia planta de producción interna.

#### 3.2 Datos de capital de inversión y volumen (transversales al flujo)

| Campo | Dónde se calcula | Notas |
|---|---|---|
| Capital invertido en materia prima | Etapa 1 | Suma de costos de insumos comprados |
| Capital invertido en producción en proceso | Etapa 3-4 | Materia prima consumida + mano de obra directa |
| Capital invertido en producto terminado | Etapa 6 | Costo total de manufactura |
| Volumen de comercialización proyectado | Planeación (Etapa 2) | Cantidad planeada a producir en periodo X |
| Volumen de comercialización real | Post-producción | Cantidad realmente disponible para venta |
| Rotación de inventario | Calculado con módulo de ventas | Producto terminado vendido / producto terminado disponible |

#### 3.3 Diagrama de flujo (descripción textual)

```
Materia Prima (compra)
        ↓
Registro en Almacén de Insumos
        ↓
Orden de Producción (BOM definido)
        ↓
Consumo de Materia Prima
        ↓
Transformación (etapas internas + control de calidad)
        ↓
Producto Terminado (nuevo SKU/lote)
        ↓
Entrada a Inventario de Producto Terminado
        ↓
Disponible para Venta / Comercialización
```

### 4. Actividad 3 — Validación con Almacén/Operaciones

Checklist de preguntas para validar el flujo con el área operativa:

- ¿El almacén de materias primas y el de producto terminado deben estar físicamente separados en el sistema (dos ubicaciones distintas)?
- ¿Quién captura los datos en cada etapa? (¿el mismo operador o distintos roles?)
- ¿Existen mermas conocidas por tipo de producto que debamos parametrizar?
- ¿El control de calidad es por lote completo o por unidad individual?
- ¿Cómo se registra hoy en día (papel, Excel, otro sistema)? Para migrar datos históricos.
- ¿Cuál es el tiempo real entre recepción de materia prima y disponibilidad de producto terminado? (para validar los campos de fecha)
- ¿Se requiere trazabilidad por número de serie individual o basta con lote?
- ¿Qué pasa con producto rechazado en control de calidad? ¿Se reprocesa, se desecha, se devuelve al proveedor?
- ¿Existen normativas o certificaciones (ej. NOM, RoHS) que deban registrarse como campo obligatorio?

### 5. Estructura de Base de Datos necesaria (soporte del punto 3 general)

Entidades (tablas) mínimas que este módulo requiere:

1. Productos (catálogo maestro: SKU, categoría, marca, modelo)
2. Proveedores
3. Materias Primas / Insumos
4. Órdenes de Compra
5. Entradas de Inventario (vía A: compra directa)
6. Órdenes de Producción
7. BOM (Lista de Materiales) — relación producto terminado ↔ materias primas y cantidades
8. Consumo de Producción (movimientos de materia prima hacia producción)
9. Control de Calidad
10. Inventario de Producto Terminado
11. Almacenes / Ubicaciones
12. Movimientos de Inventario (log histórico de entradas/salidas/transferencias)
13. Usuarios / Responsables (para trazabilidad de quién capturó qué)

**Relaciones clave**

- Un Producto Terminado puede originarse de una Entrada directa o de una Orden de Producción.
- Una Orden de Producción consume múltiples Materias Primas según el BOM.
- Cada Movimiento de Inventario debe quedar ligado a un usuario, fecha y documento origen (factura, orden de producción, etc.) para conectar con el módulo contable general.

### 6. Notas de integración con las otras necesidades generales del sistema

- **Contabilidad (necesidad 1):** los campos de factura, costo y capital de inversión de este módulo deben poder consultarse desde el módulo contable sin duplicar captura.
- **Salarios/bonificaciones (necesidad 3):** la mano de obra directa registrada en la Etapa 3-4 de manufactura puede alimentar el cálculo de bonos por productividad.
- **Impuestos/aduanas (necesidad 4):** los campos de país de origen, documento de importación e impuestos aplicados en la sección 2.4 son el punto de conexión.
- **Marketing (necesidad 5):** el volumen de comercialización disponible (sección 3.2) es un dato que marketing necesita para planear campañas y evitar promocionar producto sin stock.

*Documento preparado para uso interno del equipo — pendiente de validación con Almacén/Operaciones (Actividad 3).*

---

## Parte II — Complemento: Cálculo de Valor de Capital y Métricas de Volumen

Como complemento a los requerimientos base del módulo, se detallan a continuación los criterios de cálculo de valor de capital y las métricas de volumen definidas para el sistema, así como la validación correspondiente con el área de Finanzas.

### 1. Cálculo de Valor y Capital

Se establece que el sistema no registrará únicamente el precio de compra, sino el **valor real** de cada entrada de inventario, considerando todos los costos asociados a la operación.

**Fórmula definida:**

> Capital por entrada = (Costo del producto + Flete + Impuesto) × Cantidad

**Ejemplo ilustrativo:**

Para una entrada de 100 unidades de manufactura nacional, con un costo de $200 por unidad y un costo de traslado de $20 por unidad, el valor real por unidad asciende a $220. Esto resulta en una inversión total de $22,000 para el lote.

### 2. Métricas de Volumen

Se proponen las siguientes métricas de volumen para apoyar la toma de decisiones logísticas y financieras del equipo:

- **Unidades por región:** permite determinar hacia qué región debe dirigirse el inventario disponible.
- **Rotación (días en venderse el lote):** indica el tiempo que tarda un lote en venderse por completo.

Estas métricas en conjunto permiten identificar si el capital invertido permanece inmovilizado en bodega o si está circulando de manera eficiente.

### 3. Validación con Finanzas

Se realizó la validación correspondiente de las fórmulas de cálculo con el área de Finanzas, con el fin de asegurar que la información generada por el sistema sea de utilidad directa para dicha área. Como parte de esta validación, se confirmó el requerimiento de que el reporte incluya el IVA desglosado y la referencia de factura correspondiente, criterio que ha sido incorporado al cálculo definido en la sección anterior.
