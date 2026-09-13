# Cronograma

Del domingo 13 al jueves 17 de septiembre de 2026: **5 días de trabajo** para los equipos. El sábado 12 la coordinación deja listo el repo. El viernes 18 no forma parte del plan.

| Día | Fecha | Fase | Qué hace cada equipo | Hito al cierre del día |
| --- | --- | --- | --- | --- |
| 0 | Sáb 12 sep | Preparación (coordinación) | Nada todavía. Los líderes reciben el enlace al repo y a `docs/EMPIEZA_AQUI.md` | Repo publicado con contextos, tareas, guías e issues |
| 1 | Dom 13 sep | Arranque | Líder lee el `CONTEXTO.md` con su equipo y aplica la evaluación de habilidades. Integrantes hacen fork y su PR de bienvenida. Líderes cierran los acuerdos de integración con sus áreas contraparte y asignan los issues del lunes | Seis equipos con roles, forks hechos, integraciones acordadas |
| 2 | Lun 14 sep | Base de datos | Migraciones del área, seed, triggers, RLS y pruebas SQL | La base levanta limpia con los datos de las seis áreas |
| 3 | Mar 15 sep | Vistas, servicios y captura | Vistas de contrato publicadas, `src/services/areaN/`, pantallas de alta y listado conectadas | Cada área captura y lista sus datos desde la app; las otras áreas ya pueden leer sus vistas |
| 4 | Mié 16 sep | Flujos e integración | Pantallas de flujo con estados, reportes, pruebas de punta a punta con las áreas contraparte. **18:00 congelamiento de alcance**; después solo correcciones | El flujo de 14 pasos de `docs/FLUJO_APP.md` corre de punta a punta |
| 5 | Jue 17 sep | Cierre y entrega | Corrección de bugs en la mañana, evidencias, contexto actualizado, `REPORTE_FINAL.md` del líder antes de las 14:00 | **Entrega** |

## Reglas

- Los PRs se revisan el mismo día; uno que espera más de 6 horas bloquea a alguien. Si el líder no alcanza, aprueba la coordinación.
- Cada líder actualiza `ESTADO.md` de su área todos los días al cierre y llena la evaluación del día.
- Nada nuevo entra después del miércoles 16 a las 18:00.
- Todo se documenta: cada issue cierra con evidencia, cada acuerdo entre áreas queda en su issue de integración, cada decisión en `DECISIONES.md`, cada día en la bitácora de `ESTADO.md`.

## Alcance mínimo por área para el jueves 17

Con cinco días, esto es lo que debe existir. Lo que sobre es extra y se decide el miércoles antes del congelamiento.

| Área | Mínimo entregable |
| --- | --- |
| 1 | Catálogo de proveedores y almacenes. Pantalla de registro de entrada con SKU, lote, flete e impuestos. Una orden de producción con lista de materiales y su entrada a inventario. Vista de entradas con detalle |
| 2 | Catálogo de clientes con número de comercializador. Alta de factura con renglones validados contra stock y totales por trigger. Cambio de estado de pago con fecha de cobro automática. Reporte de facturado por cliente con IVA desglosado |
| 3 | Migraciones, tres triggers, RLS, seis vistas, seed con 20 productos y 10 movimientos. Conciliación con ajuste |
| 4 | Catálogo de agentes con zona y esquema. Cálculo de comisiones y bonos del periodo. Nómina con ISR, IMSS e ISN. Recibo por agente. Separación de funciones en el flujo de estados |
| 5 | Catálogo de instituciones y obligaciones con parámetros fiscales. Alta de obligación con vencimiento y estados. Alertas por anticipación. Registro de pago con comprobante. Cálculo de ISN e IVA de importación |
| 6 | Catálogo de canales y campañas con costo, presupuesto y tipo. Relación campaña-cliente con estado de contacto. Reporte de costo y ROI por campaña |

## Qué hace la coordinación cada día

| Día | Coordinación |
| --- | --- |
| Sáb 12 | Sube issues, avisa a líderes, deja `EMPIEZA_AQUI.md` |
| Dom 13 | Migración base y seed compartido; app base con menú y módulos vacíos; destraba integraciones |
| Lun 14 | Revisa PRs de migraciones, resuelve choques entre áreas |
| Mar 15 | Revisa vistas de contrato y estilo de pantallas; resumen general con datos del seed |
| Mié 16 | Prueba el flujo de 14 pasos; a las 18:00 cierra el alcance |
| Jue 17 | Consolida los seis reportes, verifica el historial, entrega |
