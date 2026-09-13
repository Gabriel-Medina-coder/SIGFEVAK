# Proyecto: Sistema de Control Fiscal, Aduanal y de Permisos

## 1. Nombre del proyecto

**Sistema de Control de Obligaciones, Pagos y Permisos para una Comercializadora de Productos Electrónicos en Chiapas, México**

---

## 2. Descripción general

El proyecto consiste en el diseño de un sistema administrativo capaz de controlar las principales obligaciones fiscales, aduanales, estatales y municipales de una empresa comercializadora de productos electrónicos ubicada en el estado de Chiapas, México.

El sistema permitirá registrar obligaciones, generar alertas de vencimiento, almacenar folios, controlar pagos, conservar documentos oficiales y mantener un historial de cumplimiento ante distintas instituciones gubernamentales.

Las principales instituciones contempladas son:

- Servicio de Administración Tributaria (SAT).
- Agencia Nacional de Aduanas de México (ANAM).
- Ventanilla Única de Comercio Exterior Mexicana (VUCEM).
- Secretaría de Hacienda del Estado de Chiapas.
- Protección Civil del Estado de Chiapas.
- Ayuntamiento correspondiente.
- Secretaría de Economía.
- Sistema de Información Empresarial Mexicano (SIEM).

---

## 3. Objetivo general

Diseñar un sistema que permita administrar y supervisar de manera centralizada las obligaciones fiscales, aduanales y administrativas de una comercializadora de productos electrónicos, reduciendo el riesgo de incumplimiento, retrasos, pérdida de documentos o pagos fuera de tiempo.

---

## 4. Objetivos específicos

- Registrar las obligaciones fiscales de la empresa.
- Controlar fechas límite de pago y presentación.
- Generar alertas automáticas antes de los vencimientos.
- Registrar declaraciones, folios y líneas de captura.
- Registrar pagos realizados a instituciones gubernamentales.
- Mantener evidencia documental de cada trámite o pago.
- Controlar pedimentos e información relacionada con importaciones.
- Registrar fracciones arancelarias y NICO de productos importados.
- Controlar el Impuesto Sobre Nóminas del Estado de Chiapas.
- Registrar licencias y permisos municipales o estatales.
- Mantener un historial de auditoría de las operaciones realizadas.
- Permitir identificar qué usuario realizó, autorizó o modificó una operación.

---

## 5. Alcance del sistema

El sistema contempla cuatro áreas principales:

### 5.1 Licencias y permisos

Permitirá registrar y controlar:

- Uso de suelo.
- Licencia de funcionamiento.
- Programa Interno de Protección Civil.
- Registro SIEM.
- Permisos sanitarios cuando sean aplicables.
- Autorizaciones administrativas relacionadas con la operación de la empresa.

Los costos de uso de suelo y licencia de funcionamiento dependerán del municipio de Chiapas donde se establezca físicamente la empresa.

---

### 5.2 Comercio exterior y aduanas

El sistema permitirá registrar:

- Padrón de Importadores.
- Encargos conferidos.
- Pedimentos.
- Aduana de entrada.
- Agente o agencia aduanal.
- País de origen.
- País de procedencia.
- Valor aduanero.
- Fracción arancelaria.
- NICO.
- Impuesto General de Importación (IGI).
- Derecho de Trámite Aduanero (DTA).
- IVA de importación.
- Manifestación de Valor E2.
- Documentación de VUCEM.

---

### 5.3 Obligaciones fiscales

El sistema permitirá controlar obligaciones como:

- ISR.
- IVA.
- Declaraciones mensuales.
- Declaración anual.
- CFDI.
- Impuesto Sobre Nóminas de Chiapas.
- Pagos provisionales.
- Líneas de captura.
- Acuses de presentación.
- Comprobantes bancarios.

---

### 5.4 Sistema automático de pagos y alertas

El sistema permitirá:

- Registrar fechas de vencimiento.
- Crear alertas preventivas.
- Registrar líneas de captura.
- Autorizar pagos.
- Registrar pagos realizados.
- Conciliar pagos.
- Guardar comprobantes.
- Marcar obligaciones como cerradas.
- Identificar obligaciones vencidas.

---

## 6. Usuarios del sistema

El sistema contempla diferentes tipos de usuario.

### Administrador

Puede:

- Registrar usuarios.
- Consultar todas las obligaciones.
- Configurar instituciones.
- Configurar tipos de obligación.
- Consultar auditorías.
- Modificar parámetros generales.

### Contador

Puede:

- Registrar declaraciones.
- Consultar obligaciones fiscales.
- Registrar montos.
- Registrar líneas de captura.
- Adjuntar acuses.
- Registrar información de ISR, IVA e ISN.

### Responsable de comercio exterior

Puede:

- Registrar importaciones.
- Registrar pedimentos.
- Registrar productos importados.
- Capturar fracciones arancelarias.
- Capturar NICO.
- Registrar IGI, DTA e IVA de importación.
- Adjuntar documentos relacionados con VUCEM y ANAM.

### Autorizador financiero

Puede:

- Revisar obligaciones.
- Autorizar pagos.
- Registrar confirmaciones.
- Validar montos.
- Conciliar pagos.

---

## 7. Flujo general del sistema

```text
CATÁLOGO DE OBLIGACIONES
          |
          v
GENERACIÓN DE VENCIMIENTO
          |
          v
ALERTAS AUTOMÁTICAS
          |
          v
PREPARACIÓN DE DECLARACIÓN O TRÁMITE
          |
          v
GENERACIÓN DE FOLIO / LÍNEA DE CAPTURA
          |
          v
REVISIÓN Y AUTORIZACIÓN
          |
          v
REALIZACIÓN DEL PAGO
          |
          v
REGISTRO DEL COMPROBANTE
          |
          v
CONCILIACIÓN
          |
          v
CIERRE DE LA OBLIGACIÓN
```

---

## 8. Estados de una obligación

Cada obligación podrá tener alguno de los siguientes estados:

- `PENDIENTE`
- `CALCULADO`
- `PRESENTADO`
- `LINEA_GENERADA`
- `AUTORIZADO`
- `PAGADO`
- `CONCILIADO`
- `CERRADO`
- `VENCIDO`

Ejemplo:

```text
PENDIENTE
   ↓
CALCULADO
   ↓
PRESENTADO
   ↓
LINEA_GENERADA
   ↓
AUTORIZADO
   ↓
PAGADO
   ↓
CONCILIADO
   ↓
CERRADO
```

---

## 9. Sistema de alertas

Las alertas pueden configurarse de la siguiente manera:

| Anticipación | Nivel | Acción |
|---|---|---|
| 15 días | Preventiva | Aviso inicial |
| 7 días | Preventiva | Solicitar documentación |
| 3 días | Alta | Priorizar trámite |
| 1 día | Crítica | Vencimiento próximo |
| Día del vencimiento | Crítica | Aviso inmediato |
| Después del vencimiento | Vencida | Marcar incumplimiento |

---

## 10. Modelo de base de datos

La base de datos está compuesta por las siguientes tablas principales:

### usuario

Almacena los usuarios del sistema.

Campos principales:

- id_usuario
- nombre
- apellidos
- correo
- contrasena
- rol
- activo
- fecha_registro

---

### institucion

Almacena las instituciones gubernamentales relacionadas con cada obligación.

Ejemplos:

- SAT.
- ANAM.
- Hacienda Chiapas.
- Protección Civil Chiapas.
- Ayuntamiento.
- Secretaría de Economía.

---

### tipo_obligacion

Define los diferentes tipos de obligaciones.

Ejemplos:

- ISR.
- IVA.
- ISN.
- Uso de suelo.
- Licencia de funcionamiento.
- Pedimento.
- SIEM.

---

### obligacion

Es la tabla central del sistema.

Contiene:

- Tipo de obligación.
- Periodo.
- Fecha de vencimiento.
- Monto estimado.
- Monto final.
- Estado.
- Responsable.

---

### declaracion

Registra información de las declaraciones presentadas.

Contiene:

- Tipo de declaración.
- Número de operación.
- Folio.
- Línea de captura.
- Fecha de presentación.
- Importe declarado.
- Fecha límite de pago.

---

### pago

Registra los pagos realizados.

Contiene:

- Fecha de pago.
- Monto.
- Banco.
- Referencia.
- Línea de captura.
- Método de pago.
- Estado.
- Usuario autorizador.

---

### documento

Permite almacenar referencias de documentos relacionados con una obligación o pago.

Ejemplos:

- Acuse SAT.
- Comprobante bancario.
- CFDI.
- Pedimento.
- Manifestación E2.
- Licencia de funcionamiento.
- Uso de suelo.
- Documento de Protección Civil.

---

### alerta

Controla las notificaciones generadas por el sistema.

Contiene:

- Obligación.
- Usuario.
- Fecha de alerta.
- Días de anticipación.
- Nivel.
- Mensaje.
- Estado de envío.

---

### importacion

Registra las operaciones de importación.

Contiene:

- Número de pedimento.
- Aduana.
- Agente aduanal.
- País de origen.
- País de procedencia.
- Fecha de importación.
- Valor aduanero.
- IGI.
- DTA.
- IVA de importación.
- Total de contribuciones.
- Número E2.

---

### producto_importado

Registra cada producto asociado con una importación.

Contiene:

- Nombre del producto.
- Marca.
- Modelo.
- Cantidad.
- Valor unitario.
- Valor total.
- Fracción arancelaria.
- NICO.
- Tasa IGI.
- NOM aplicable.

---

### impuesto_nomina

Registra el Impuesto Sobre Nóminas del Estado de Chiapas.

Contiene:

- Año.
- Bimestre.
- Nómina gravada.
- Tasa.
- Impuesto calculado.
- Fecha de presentación.
- Folio.

La tasa considerada para el sistema es del **2%**, conforme a la legislación estatal aplicable.

---

### licencia_permiso

Registra permisos y licencias.

Contiene:

- Tipo de licencia.
- Autoridad emisora.
- Municipio.
- Número de licencia.
- Fecha de emisión.
- Fecha de vencimiento.
- Costo.
- Estado.

---

### cfdi

Registra información básica de comprobantes fiscales.

Contiene:

- UUID.
- Tipo de CFDI.
- RFC emisor.
- RFC receptor.
- Fecha.
- Subtotal.
- IVA.
- Total.
- Estado.

---

### auditoria

Mantiene una bitácora de acciones realizadas por los usuarios.

Registra:

- Usuario.
- Tabla afectada.
- Registro afectado.
- Acción.
- Descripción.
- Fecha.
- Dirección IP.

---

## 11. Relaciones principales

```text
INSTITUCION
     |
     v
TIPO_OBLIGACION
     |
     v
OBLIGACION
     |
     +------ DECLARACION
     |
     +------ PAGO
     |
     +------ DOCUMENTO
     |
     +------ ALERTA
     |
     +------ IMPORTACION
     |           |
     |           v
     |     PRODUCTO_IMPORTADO
     |
     +------ IMPUESTO_NOMINA
     |
     +------ LICENCIA_PERMISO
```

Además:

```text
USUARIO
   |
   +------ OBLIGACION
   |
   +------ PAGO
   |
   +------ ALERTA
   |
   +------ AUDITORIA
```

---

## 12. Reglas de negocio

1. Una obligación debe pertenecer a un tipo de obligación.

2. Cada tipo de obligación debe estar relacionado con una institución.

3. Una obligación debe tener una fecha de vencimiento.

4. Una obligación no puede marcarse como `PAGADO` si no existe un pago registrado.

5. Una obligación no puede marcarse como `CONCILIADO` si el monto pagado no coincide con el monto validado.

6. Los pagos de obligaciones críticas deben ser autorizados por un usuario con permisos de autorización.

7. Cada pago debe conservar una referencia bancaria o comprobante.

8. Cada importación debe estar asociada con una obligación.

9. Cada producto importado debe pertenecer a una importación.

10. Los productos importados deben registrar su fracción arancelaria cuando ésta haya sido determinada.

11. El NICO debe registrarse cuando corresponda.

12. El sistema no debe asumir una tasa IGI general para todos los productos electrónicos.

13. El sistema debe permitir registrar una tasa IGI diferente por producto.

14. El ISN de Chiapas debe calcularse sobre la base gravable registrada.

15. Las licencias municipales deben permitir registrar el municipio, ya que los costos pueden variar.

16. Las obligaciones vencidas sin pago deberán cambiar automáticamente a estado `VENCIDO`.

17. Toda modificación importante debe registrarse en la tabla de auditoría.

---

## 13. Cálculos principales

### ISR

Para personas morales del Régimen General:

```text
ISR anual = Resultado fiscal × 30%
```

No debe calcularse directamente sobre las ventas totales.

---

### IVA

Tasa general:

```text
IVA = Base gravable × 16%
```

De forma simplificada:

```text
IVA a pagar = IVA trasladado - IVA acreditable
```

---

### Impuesto Sobre Nóminas de Chiapas

```text
ISN = Nómina gravada × 2%
```

Ejemplo:

```text
Nómina gravada = $200,000
ISN = $200,000 × 0.02
ISN = $4,000
```

---

### IGI

```text
IGI = Valor en aduana × Tasa arancelaria
```

La tasa depende de:

- Fracción arancelaria.
- NICO.
- País de origen.
- Tratados comerciales aplicables.
- Tipo de mercancía.

---

### DTA

En los casos donde aplique la regla general:

```text
DTA = Valor correspondiente × 0.008
```

La tasa general equivale a 8 al millar, aunque pueden existir supuestos especiales.

---

### IVA de importación

De forma simplificada:

```text
Base IVA importación =
Valor en aduana
+ IGI
+ contribuciones aplicables

IVA importación =
Base IVA importación × 16%
```

---

## 14. Calendario general de obligaciones

| Obligación | Frecuencia |
|---|---|
| ISR provisional | Mensual |
| IVA | Mensual |
| ISN Chiapas | Bimestral |
| Declaración anual ISR | Anual |
| SIEM | Anual |
| CFDI | Según operación |
| Pedimento | Por importación |
| E2 | Por operación cuando aplique |
| Uso de suelo | Según municipio |
| Licencia de funcionamiento | Según municipio |
| Protección Civil | Según vigencia aplicable |

---

## 15. Requerimientos funcionales

### RF-01

El sistema debe permitir registrar usuarios.

### RF-02

El sistema debe permitir registrar instituciones.

### RF-03

El sistema debe permitir registrar tipos de obligaciones.

### RF-04

El sistema debe generar obligaciones con fecha de vencimiento.

### RF-05

El sistema debe generar alertas de vencimiento.

### RF-06

El sistema debe permitir registrar declaraciones.

### RF-07

El sistema debe permitir registrar líneas de captura.

### RF-08

El sistema debe permitir registrar pagos.

### RF-09

El sistema debe permitir autorizar pagos.

### RF-10

El sistema debe permitir adjuntar o registrar documentos.

### RF-11

El sistema debe permitir registrar importaciones.

### RF-12

El sistema debe permitir registrar productos de cada importación.

### RF-13

El sistema debe permitir registrar fracciones arancelarias y NICO.

### RF-14

El sistema debe permitir calcular y registrar ISN.

### RF-15

El sistema debe permitir registrar licencias y permisos.

### RF-16

El sistema debe permitir consultar obligaciones vencidas.

### RF-17

El sistema debe permitir consultar historial de pagos.

### RF-18

El sistema debe registrar acciones en una bitácora de auditoría.

---

## 16. Requerimientos no funcionales

### Seguridad

- Las contraseñas deben almacenarse cifradas mediante hash seguro.
- El acceso debe controlarse mediante roles.
- Los usuarios sólo deben acceder a funciones autorizadas.
- Los cambios críticos deben quedar registrados.

### Disponibilidad

El sistema debe estar disponible durante los horarios administrativos de la empresa.

### Integridad

No se deben eliminar físicamente registros fiscales importantes sin conservar evidencia en auditoría.

### Trazabilidad

Cada pago, declaración o modificación debe poder relacionarse con el usuario que realizó la acción.

### Respaldo

La base de datos debe contar con copias de seguridad periódicas.

### Protección documental

Los archivos fiscales deben contar con control de acceso y respaldo.

---

## 17. Tecnologías sugeridas

El proyecto puede implementarse con diferentes tecnologías.

### Backend

- Java.
- Spring Boot.
- Spring Data JPA.
- Spring Security.

### Base de datos

- MySQL.
- PostgreSQL.

### Frontend

- React.
- HTML.
- CSS.
- JavaScript.

### Herramientas de modelado

- dbdiagram.io.
- MySQL Workbench.
- Draw.io.

---

## 18. Estructura sugerida del backend

```text
src/
└── main/
    └── java/
        └── com/
            └── comercializadora/
                ├── controller/
                ├── service/
                ├── repository/
                ├── entity/
                ├── dto/
                ├── security/
                ├── config/
                └── exception/
```

---

## 19. Módulos sugeridos

```text
1. Autenticación
2. Usuarios
3. Instituciones
4. Obligaciones
5. Declaraciones
6. Pagos
7. Alertas
8. Documentos
9. Comercio exterior
10. Productos importados
11. ISN Chiapas
12. Licencias y permisos
13. CFDI
14. Auditoría
15. Reportes
```

---

## 20. Reportes sugeridos

El sistema podría generar:

- Obligaciones pendientes.
- Obligaciones vencidas.
- Pagos por institución.
- Pagos por periodo.
- Historial de ISR.
- Historial de IVA.
- Historial de ISN.
- Importaciones por periodo.
- IGI pagado.
- DTA pagado.
- IVA de importación.
- Licencias próximas a vencer.
- Alertas pendientes.
- Auditoría de usuarios.

---

## 21. Beneficios del sistema

La implementación del sistema permitiría:

- Reducir errores administrativos.
- Evitar pagos fuera de tiempo.
- Disminuir riesgo de multas.
- Mantener centralizados los documentos.
- Facilitar auditorías.
- Tener trazabilidad de cada obligación.
- Controlar obligaciones federales, estatales y municipales desde una sola plataforma.
- Mejorar la administración financiera de la empresa.
- Facilitar el control de operaciones de importación.

---

## 22. Consideraciones importantes

- El costo de la licencia de funcionamiento depende del municipio.
- El costo del uso de suelo depende del municipio.
- No todos los productos electrónicos requieren permisos sanitarios.
- No existe una única tasa de IGI para todos los productos electrónicos.
- La fracción arancelaria debe determinarse para cada mercancía.
- Los honorarios del agente aduanal no son una tarifa gubernamental.
- El sistema debe permitir actualizar tasas, costos y reglas cuando cambie la legislación.

---

## 23. Conclusión

El sistema propuesto permitirá a una comercializadora de productos electrónicos ubicada en Chiapas mantener un control organizado de sus obligaciones fiscales, aduanales y administrativas.

La base de datos centraliza instituciones, obligaciones, declaraciones, pagos, documentos, importaciones, licencias, alertas y auditorías.

El diseño busca que la empresa pueda identificar rápidamente qué debe pagar, cuánto debe pagar, cuándo vence una obligación, qué documentación la respalda y qué usuario fue responsable de cada operación.

Esto permite mejorar el cumplimiento fiscal y administrativo, reducir riesgos y facilitar el crecimiento futuro de la empresa.
