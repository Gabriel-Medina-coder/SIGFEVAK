# Plan de proyecto: Módulo 4, Asignación de salarios, sueldos y bonificaciones a agentes de ventas

> Documento original entregado por el líder del Área 4 el 11 de septiembre de 2026, transcrito sin cambios de contenido.

## 1. Objetivo y alcance

Objetivo: diseñar e implementar un módulo que calcule, controle y pague de forma correcta y trazable el sueldo base, las comisiones y los bonos de los agentes de ventas de la comercializadora a nivel nacional, cumpliendo con la LFT, la Ley del Seguro Social y la LISR.

Dentro del alcance: catálogo de agentes y zonas, esquemas de compensación, metas de venta, cálculo de comisiones sobre ventas cobradas, bonos, nómina del periodo, autorizaciones, recibos CFDI de nómina y reportes.

Fuera del alcance: la facturación a clientes (módulo 2), el inventario (módulo 3) y el pago de impuestos (módulo 5). Este módulo solo consume datos de esos módulos y les envía información.

El plan sirve igual si lo construyen en Excel o como sistema con base de datos. En Excel cada tabla del diseño se vuelve una hoja, y en un sistema se vuelve una tabla de la BD.

## 2. Equipo, roles y evaluación del líder

### Roles propuestos (5 integrantes)

| Rol | Responsabilidades principales |
| --- | --- |
| Líder de proyecto | Planeación, cronograma, evaluación del equipo, control de cambios, reporte final |
| Analista de negocio y normativa | Reglas de comisiones y bonos, investigación legal (LFT, LSS, LISR), validación de cálculos |
| Diseñador de base de datos | Modelo de datos, diccionario de datos, relaciones con módulos 2, 3 y 5 |
| Desarrollador | Lógica de cálculo, pantallas o formularios de captura, automatización |
| QA y documentación | Casos de prueba, pruebas con datos reales, manual de usuario, formato de reportes |

### Cómo evalúa el líder

Diagnóstico inicial (semana 1). Cada integrante hace una autoevaluación de habilidades (Excel/BD, programación, redacción, normativa, diseño) y resuelve una tarea corta de prueba. Con eso el líder confirma o ajusta la asignación de roles antes de arrancar.

Evaluación continua. El líder evalúa a cada integrante al cierre de cada fase con esta matriz, en escala de 1 a 5:

| Criterio | Peso | Qué observa el líder |
| --- | --- | --- |
| Cumplimiento de entregas | 30% | Entrega a tiempo y completa |
| Calidad técnica | 25% | Errores encontrados en revisión o pruebas |
| Comunicación y colaboración | 20% | Avisa bloqueos, apoya a otros, asiste a reuniones |
| Solución de problemas e iniciativa | 15% | Propone mejoras, resuelve sin esperar instrucciones |
| Aprendizaje y adaptación | 10% | Aplica la retroalimentación recibida |

Reglas para modificar tareas. Si un integrante saca menos de 3 en una tarea crítica, o esa tarea lleva más de 20% de retraso, el líder la reasigna o pone a otro integrante a trabajar en pareja con él. Si alguien saca 4.5 o más de forma sostenida, puede recibir tareas de mayor complejidad o liderar una subparte.

Cada cambio se anota en un Registro de control de cambios, con estas columnas: fecha, tarea, responsable anterior, nuevo responsable, motivo, impacto en el cronograma y visto bueno del líder. Ese registro es la evidencia que después va en el reporte final.

## 3. Fases y cronograma (8 semanas)

| Semana | Fase | Actividades | Entregable |
| --- | --- | --- | --- |
| 1 | Inicio | Acta constitutiva, alcance, roles, diagnóstico de habilidades | Project Charter, matriz de roles |
| 2 | Análisis | Entrevistas con Ventas, RH y Finanzas; definición de reglas de negocio e investigación legal | Documento de requerimientos y reglas de negocio |
| 3 | Diseño | Modelo de datos, flujo del proceso, prototipo de pantallas y reportes | Diagrama E-R, diccionario de datos, diagrama de flujo |
| 4 y 5 | Construcción | Catálogos, cálculo de comisiones y bonos, cálculo de nómina, reportes | Módulo funcional |
| 6 | Pruebas | Casos de prueba, cálculo en paralelo contra nómina manual, corrección de errores | Bitácora de pruebas firmada |
| 7 | Implementación | Carga de datos reales, capacitación, primer periodo piloto | Manual de usuario, acta de capacitación |
| 8 | Cierre | Evaluación final del equipo, lecciones aprendidas | Reporte final del líder, acta de cierre |

## 4. Reglas de negocio: esquema de compensación

### Marco legal que debe respetar

Los agentes de comercio que trabajan de forma permanente para la empresa son trabajadores, no comisionistas independientes (arts. 285 a 291 LFT). Además, el art. 84 LFT establece que las comisiones forman parte del salario. Esto trae tres consecuencias para el diseño.

La primera es que el sueldo base nunca puede quedar debajo del mínimo, aunque el agente no venda nada. Para este año, el salario mínimo tuvo un aumento del 13% y quedó en 315.04 pesos diarios, y en 440.87 pesos diarios en la Zona Libre de la Frontera Norte. Como la empresa es nacional, el sistema debe saber en qué zona salarial trabaja cada agente.

La segunda es que las comisiones y los bonos integran el Salario Base de Cotización del IMSS. La parte variable se promedia por bimestre (art. 30 LSS). Solo los premios de puntualidad y asistencia quedan excluidos, cada uno hasta el 10% del SBC (art. 27 LSS).

La tercera es que todas las comisiones y bonos pagan ISR (retención con la tarifa del art. 96 LISR). Algunos topes de exención se calculan con la UMA: en 2026 la UMA diaria es de $117.31 y el valor mensual es de $3,566.22, vigentes desde el 1 de febrero de 2026.

### Esquema propuesto

Sueldo base: $350 diarios en zona general, un poco arriba del mínimo para dar margen. En la zona frontera se ajusta al mínimo de esa zona.

Comisión escalonada. Se calcula sobre ventas cobradas sin IVA y ya descontadas las devoluciones. La tasa depende del porcentaje de cumplimiento de la meta mensual:

| Cumplimiento de meta | Tasa de comisión |
| --- | --- |
| 0% a 69% | 1.0% |
| 70% a 99% | 2.0% |
| 100% a 119% | 3.0% |
| 120% o más | 3.5% |

Se paga sobre ventas cobradas y no solo facturadas, para no pagar comisión por facturas que el cliente nunca liquida. Lo facturado y pendiente de cobro pasa al periodo en que efectivamente se cobre.

Bonos:

| Bono | Condición | Monto | ¿Integra SBC? |
| --- | --- | --- | --- |
| Cumplimiento de meta | Llegar al 100% o más | $2,500 | Sí |
| Cliente nuevo | Cada cliente nuevo con su primera compra pagada | $500 por cliente | Sí |
| Cobranza sana | Cartera vencida del agente menor al 5% | $1,000 | Sí |
| Premio de puntualidad | Cero retardos en el periodo | 10% del sueldo | No (hasta 10% del SBC) |
| Bono trimestral | Promedio del trimestre de 110% o más | $6,000 | Sí |

Regla de ajuste por cancelación. Si una factura ya comisionada se cancela o se devuelve la mercancía, la comisión se descuenta en el siguiente periodo. Ese descuento debe respetar los límites del art. 110 LFT y quedar registrado.

Periodicidad: el sueldo base se paga por quincena, y las comisiones y bonos se pagan una vez al mes, después del corte de cobranza.

## 5. Diseño de datos

| Tabla | Propósito | Campos clave |
| --- | --- | --- |
| AGENTE | Datos laborales del agente | id_agente, RFC, CURP, NSS, nombre, fecha_ingreso, id_zona, id_esquema, salario_diario, entidad_federativa, CLABE, estatus |
| ZONA | Regiones de venta | id_zona, nombre, región, zona_salarial (general o ZLFN), entidad |
| ESQUEMA_COMPENSACION | Plan de pago vigente | id_esquema, nombre, periodicidad, vigencia_inicio, vigencia_fin |
| TRAMO_COMISION | Tabla escalonada | id_tramo, id_esquema, pct_min, pct_max, tasa |
| META | Meta mensual por agente | id_meta, id_agente, periodo, monto_meta |
| VENTA_AGENTE | Ventas que vienen del módulo 2 | id_venta, id_agente, folio_factura, UUID, id_cliente, subtotal, fecha_factura, fecha_cobro, estatus |
| BONO_CATALOGO | Tipos de bono | id_bono, nombre, condición, monto_o_porcentaje, integra_sbc, gravado_isr |
| BONO_ASIGNADO | Bonos ganados | id, id_agente, id_bono, periodo, monto, autorizado_por, fecha |
| PERIODO_NOMINA | Control de periodos | id_periodo, tipo, fecha_inicio, fecha_fin, estatus (abierto, calculado, autorizado, pagado, cerrado) |
| NOMINA_DETALLE | Cada concepto pagado o descontado | id, id_periodo, id_agente, concepto, tipo, clave_SAT, monto, gravado, exento |
| PARAMETRO_LEGAL | Valores que cambian cada año | clave (SM, UMA, tarifa ISR, cuotas IMSS, ISN por estado), valor, vigencia |
| BITACORA | Auditoría | usuario, tabla, acción, valor_anterior, valor_nuevo, fecha |

La tabla PARAMETRO_LEGAL es la más importante para que el sistema dure. Cuando cambie el salario mínimo o la UMA el próximo año, solo se actualiza un registro y no hay que tocar fórmulas ni código.

## 6. Flujo del proceso mensual

| Paso | Acción | Responsable | Control |
| --- | --- | --- | --- |
| 1 | Corte de ventas y cobranza del mes | Sistema | Fecha de corte fija (último día hábil) |
| 2 | Importar las facturas cobradas del módulo 2 y ligarlas a su agente | Sistema | Solo facturas con estatus "pagada" |
| 3 | Calcular el % de cumplimiento contra la meta | Sistema | Meta cargada antes del inicio del mes |
| 4 | Aplicar el tramo y calcular la comisión | Sistema | Tabla de tramos vigente |
| 5 | Calcular los bonos | Sistema | Condiciones del catálogo |
| 6 | Revisión y visto bueno | Gerente de ventas | No puede modificar montos, solo aprobar o rechazar con comentario |
| 7 | Calcular la nómina: percepciones menos ISR, IMSS obrero, INFONAVIT y descuentos | Sistema | Parámetros legales vigentes |
| 8 | Autorización final | Finanzas | Separación de funciones: quien captura no autoriza |
| 9 | Timbrado del CFDI de nómina (complemento Nómina 1.2) con el PAC | Sistema | Claves SAT: 001 sueldos, 028 comisiones, 010 puntualidad, 038 otros ingresos por salarios |
| 10 | Dispersión bancaria por SPEI | Finanzas | Layout del banco y conciliación |
| 11 | Envío del recibo al agente | Sistema | Correo con PDF y XML |
| 12 | Póliza contable y envío de retenciones al módulo 5 | Sistema | ISR retenido, cuotas IMSS e Impuesto Sobre Nómina por estado |

Hay un detalle nacional importante: el Impuesto Sobre Nómina es estatal y cambia de tasa según la entidad. Por eso se calcula según el estado donde trabaja cada agente, no donde está la matriz.

## 7. Ejemplo de cálculo (un agente, un mes)

Datos del agente: zona general, salario diario $350, meta mensual de $500,000 y ventas cobradas sin IVA de $560,000. Consiguió 2 clientes nuevos y no tuvo retardos.

| Concepto | Cálculo | Monto |
| --- | --- | --- |
| Sueldo base | $350 × 30.4 días | $10,640 |
| Cumplimiento | 560,000 / 500,000 = 112%, cae en el tramo del 3% | |
| Comisión | $560,000 × 3% | $16,800 |
| Bono de cumplimiento | Superó el 100% | $2,500 |
| Bono de clientes nuevos | 2 × $500 | $1,000 |
| Premio de puntualidad | 10% del sueldo | $1,064 |
| Total de percepciones | | $32,004 |

A ese total se le aplican la tarifa mensual del art. 96 LISR, la cuota obrera del IMSS y, si el agente tiene crédito, el descuento INFONAVIT. El resultado es el neto a pagar. Para el caso contrario, si un agente vende muy poco, cobra de todas formas los $10,640 del sueldo base más la comisión del tramo bajo, y nunca menos del mínimo legal.

## 8. Integración con los otros módulos

El módulo 2 (facturas y clientes) entrega las facturas cobradas por agente y los clientes nuevos. El módulo 3 (entradas y salidas) sirve para validar las devoluciones que cancelan comisiones. El módulo 5 (impuestos) recibe el ISR retenido, las cuotas IMSS y el ISN para programar los pagos. El módulo 6 (marketing) puede usar el desempeño por agente y zona para dirigir campañas.

## 9. Riesgos

| Riesgo | Probabilidad | Impacto | Respuesta |
| --- | --- | --- | --- |
| Error en el cálculo de ISR o IMSS | Media | Alto | Cálculo en paralelo contra la nómina actual durante la semana 6 |
| Datos de ventas incompletos o sin agente asignado | Alta | Alto | Validación obligatoria de agente en cada factura del módulo 2 |
| Cambio de parámetros legales a mitad del proyecto | Media | Medio | Tabla PARAMETRO_LEGAL con vigencias |
| Conflicto con agentes por comisiones mal pagadas | Media | Alto | Recibo detallado por factura y proceso de aclaración |
| Integrante clave se retrasa | Media | Medio | Regla de reasignación del líder y trabajo en parejas |

## 10. Indicadores para medir el éxito

El módulo se evalúa con cinco indicadores. El costo de compensación de ventas como porcentaje de las ventas debe mantenerse en el rango que defina Finanzas. Los errores de nómina por periodo deben ser cero después del piloto. El tiempo de cálculo mensual debe bajar de días a horas. Se mide también el porcentaje de agentes que cumplen su meta y el número de aclaraciones presentadas por agentes.

## 11. Reporte final del líder

| Sección | Contenido |
| --- | --- |
| Resumen ejecutivo | Qué se construyó, si se cumplió el alcance y la fecha |
| Resultados del módulo | Pruebas, periodo piloto e indicadores logrados |
| Evaluación del equipo | Matriz final por integrante con el promedio de las fases y las habilidades reconocidas |
| Cambios de asignación | Resumen del registro de control de cambios: qué se movió, por qué y el efecto |
| Reconocimientos | Aportaciones destacadas de cada integrante, con evidencia concreta |
| Desviaciones | Retrasos, riesgos que ocurrieron y cómo se resolvieron |
| Lecciones aprendidas | Qué repetir y qué evitar en los siguientes módulos |
| Anexos | Charter, diagramas, casos de prueba, actas y manual |
