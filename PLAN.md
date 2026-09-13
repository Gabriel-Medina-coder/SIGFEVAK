# PLAN.md — Plan de organización del proyecto SIGFEVAK

> **Estado: MODO PLAN. Nada de lo descrito aquí está implementado todavía.**
> Este documento define cómo se va a estructurar el repositorio, el equipo, el flujo de trabajo,
> las reglas de estilo y el uso de agentes de IA. Cuando se apruebe, se ejecuta el checklist de la sección 12.

| Campo | Valor |
| --- | --- |
| Proyecto | Sistema de gestión para una comercializadora mexicana de productos electrónicos y manufactura nacional |
| Repositorio | `Gabriel-Medina-coder/SIGFEVAK` (GitHub) |
| Personas | 31 (coordinador + 6 líderes + integrantes) |
| Equipos | 6 áreas, ~5 personas cada una, 1 líder por área |
| Responsable de este plan | Coordinador general (estructura, reglas, issues, guía de IA) |
| Inicio | Sábado 12 de septiembre de 2026 (preparación); equipos desde el domingo 13 |
| Entrega | Jueves 17 de septiembre de 2026 (D-07) |
| Versión del plan | 3 (2026-09-12) |

---

## 0. Índice

1. Contexto y necesidades del sistema
2. Qué hay hoy en el repo y qué problemas tiene
3. Decisiones que hay que cerrar ANTES de empezar
4. Organización del equipo (31 personas en 6 áreas)
5. Estructura propuesta del repositorio
6. Flujo de trabajo en GitHub (líderes, forks, issues, PRs)
7. Sistema de issues y etiquetas
8. Convenciones y reglas de estilo
9. Guía de uso de IA y agentes
10. Documentos guía por área (los markdowns de seguimiento)
11. Rol del líder: evaluación de habilidades y reporte final
12. Cronograma por fases y checklist de arranque
13. Riesgos y preguntas abiertas

---

## 1. Contexto y necesidades del sistema

Empresa mexicana de comercialización a nivel nacional. El sistema debe cubrir **seis necesidades**, y cada una corresponde a un área/equipo:

| Área | Necesidad | Nombre corto | Etiqueta |
| --- | --- | --- | --- |
| 1 | Registro de entradas de productos electrónicos y manufactura nacional (valor, capital de inversión, volumen de comercialización) | Entradas y manufactura | `area:1-entradas` |
| 2 | Registro contable de valores en factura y número de comercializadores/clientes | Contabilidad y facturación | `area:2-contabilidad` |
| 3 | Base de datos de todos los productos, entradas y salidas | Inventario (BD) | `area:3-inventario` |
| 4 | Asignación de salarios, sueldos y bonificaciones a agentes de ventas | Nómina de agentes | `area:4-nomina` |
| 5 | Registro, regulación y pago automático de licencias, permisos, impuestos aduanales y de gobierno | Fiscal y permisos | `area:5-fiscal` |
| 6 | Costo, registro e investigación de marketing externo y directo a clientes | Marketing | `area:6-marketing` |

Además, hay un requisito transversal para **todos los líderes**:

> El líder deberá evaluar y reconocer habilidades de cada integrante del equipo, con la posibilidad de modificar las acciones o tareas que tengan asignadas, y entregará un reporte al final del proyecto.

Esto se resuelve en la sección 11 con plantillas fijas para que los 6 líderes entreguen lo mismo.

---

## 2. Qué hay hoy en el repo y qué problemas tiene

| Archivo actual | Qué es realmente | Problema |
| --- | --- | --- |
| `docs/area5-fiscal/CONTEXTO.md` | Documento del **Área 5** (SAT, ANAM, VUCEM, ISN Chiapas, licencias). Propone Java + Spring Boot + MySQL/PostgreSQL + React. | El nombre no dice de qué área es. Propone un stack distinto al del Área 3. |
| `docs/area3-inventario/CONTEXTO.md` | Documento del **Área 3**. Muy completo: ER, DDL, triggers, RLS, vistas, contratos con otras áreas. Fija **PostgreSQL 15 en Supabase + `supabase-js`, sin GraphQL**. Declara su esquema como cerrado. | Su tabla `productos` tiene 7 columnas y no contempla SKU, lote, almacén ni número de serie. Es el documento mejor estructurado y sirve de **modelo para los demás**. |
| `docs/area1-entradas/CONTEXTO.md` | Documento del **Área 1**. Pide SKU, código de barras, número de serie, lote, almacenes, órdenes de producción, BOM, control de calidad. | Choca directamente con el esquema cerrado del Área 3. Habla de "necesidad 1, 3, 4, 5" con una numeración distinta a la oficial. |
| `docs/area4-nomina/CONTEXTO.md` | Documento del **Área 4** (nómina, comisiones y bonos). Escrito ya en el formato común a partir del plan del líder del área. Aditivo sobre `agentes_ventas` del modelo base; no crea tabla de ventas propia, lee `facturas` por vista. **Autorizado por el coordinador el 2026-09-11.** | Necesita `fecha_cobro` en `facturas` (área 2). Timbrado CFDI y SPEI quedan fuera de alcance. |
| `README.md` | Vacío | Hay que escribirlo. |

**Conclusión:** los documentos de las áreas 1, 3 y 5 fueron escritos por separado y se contradicen en stack, modelo de datos y numeración de áreas. El del Área 4 ya nació alineado. La primera tarea del proyecto es unificar eso, no empezar a programar.

---

## 3. Decisiones que hay que cerrar ANTES de empezar

Estas decisiones son del grupo de líderes + coordinador. Sin ellas los equipos van a construir cosas incompatibles. Se documentan en `docs/DECISIONES.md` con formato ADR (Architecture Decision Record: contexto, opciones, decisión, consecuencias).

### D-01 · Stack tecnológico único

**Cerrada el 2026-09-11.** El coordinador decidió cuatro capas; el resto se deriva de ellas.

#### Decisiones del coordinador

| Capa | Tecnología |
| --- | --- |
| Frontend | React |
| Backend | La API de Supabase (PostgREST + Auth + funciones de PostgreSQL). No hay servidor propio |
| Base de datos | PostgreSQL alojado en Supabase, un solo proyecto para las 6 áreas |
| Gestor de paquetes | pnpm, estandarizado. npm prohibido |

#### Lo que se deriva (definido por el plan, no requiere decisión)

| Capa | Tecnología | Por qué |
| --- | --- | --- |
| Empaquetador del frontend | Vite | Es el estándar actual para React sin servidor propio; arranca en segundos |
| Lenguaje | JavaScript en todo el repo: `.js` y `.jsx`, nunca `.ts` ni `.tsx`. JSDoc opcional para documentar | Menos fricción para 31 personas de niveles distintos; sin paso de compilación de tipos que bloquee PRs. La referencia de UI ya está convertida a JSX |
| Acceso a datos | `supabase-js` | Es el cliente oficial de la API de Supabase; consultas anidadas sin GraphQL, como ya documentó el Área 3 |
| Lógica de negocio | Funciones y triggers de PostgreSQL | Al no haber backend propio, las reglas críticas (stock, comisiones, obligaciones) viven en la base y nadie las salta desde el editor SQL |
| Migraciones | Supabase CLI (`supabase db push`, `supabase db reset`) | Herramienta oficial; formato de nombre según D-09 |
| Autenticación y roles | Supabase Auth + tabla `usuarios` con columna `rol` | Cubre los roles que pide el Área 5 (administrador, contador, autorizador) y la separación de funciones del Área 4 |
| Seguridad por fila | RLS activado en todas las tablas, política mínima para `authenticated` | Sin RLS Supabase regresa vacío; con políticas mínimas basta para el alcance |
| UI | Tailwind CSS v4 con los tokens de `docs/GUIA_ESTILO.md`, derivados del dashboard de Figma Make en `docs/referencia-ui/` | Un solo estilo visual para las 6 áreas: tema oscuro, DM Sans + JetBrains Mono, componentes compartidos en `src/components/`; sin librerías de componentes, iconos ni gráficas |
| Ruteo | `react-router` | Una ruta por área, menú común en `App.jsx` |
| Formularios y validación | Zod | Esquemas reutilizables por área; valida antes de mandar a Supabase |
| Estado global | Ninguno de inicio | El estado vive en cada módulo; se agrega Zustand solo si un área lo justifica en un PR |
| Runtime | Node 20 LTS | Requerido por Vite y Supabase CLI; se fija en `.nvmrc` y `engines` |
| Bloqueo de npm | `.npmrc` con `engine-strict=true` y `packageManager: "pnpm@9"` en `package.json`; solo `pnpm-lock.yaml` en el repo | npm falla al instalar y un `package-lock.json` en un PR se rechaza |
| Formato y lint | Prettier + ESLint, obligatorios en CI | Un solo estilo para 31 personas |
| Pruebas | SQL de prueba para triggers y funciones (por área, en `supabase/tests/`); frontend manual con captura en el PR | Lo crítico es la base; en 5 días no hay tiempo para pruebas de UI automatizadas |
| CI (GitHub Actions) | `lint.yml` (prettier + eslint) y `sql-lint.yml` (nombre de migración y que no se edite una aplicada) | Lo mínimo que evita PRs rotos |
| Despliegue | Local con `pnpm dev` para la presentación | Opcional Vercel para el frontend si sobra tiempo; la base ya está en la nube |
| Diagramas | Mermaid dentro de los markdown | GitHub los renderiza sin herramienta externa |
| Editor | VS Code con extensiones recomendadas en `.vscode/extensions.json` | Prettier, ESLint, Tailwind, Mermaid |
| Sistemas operativos | Mezclados | `CONTRIBUTING.md` da los comandos en PowerShell y bash |

#### Consecuencias en otros documentos

- El Área 5 cambia su sección 17 "Tecnologías sugeridas" (Java, Spring Boot) por este stack. Su lógica de negocio no cambia.
- El Área 3 queda como está: ya asumía Supabase y `supabase-js`.
- El Área 4 queda como está: su DDL es PostgreSQL.
- La estructura del repo de la sección 5 se mantiene; no hay carpeta de backend.

### D-02 · Una sola base de datos, un solo esquema

Las seis áreas comparten **una BD** (así lo define el Área 3). Fronteras lógicas: cualquier área lee todo, cada área escribe sólo en sus tablas. Se necesita:

- Un documento maestro `docs/MODELO_DATOS.md` con **todas** las tablas de las seis áreas y quién es dueño de cada una.
- Un solo directorio `supabase/migrations/` numerado. Cada área agrega migraciones con prefijo de área (ver sección 5).

### D-03 · Conflicto Área 1 vs Área 3 en el catálogo de productos

#### El problema, explicado

El Área 3 escribió su documento primero y dejó la tabla `productos` con 7 columnas: `id_producto`, `tipo`, `nombre`, `valor_entrada`, `capital_inversion`, `volumen`, `stock`. Y la tabla `entradas_producto` con 7 columnas: `id_entrada`, `id_producto`, `fecha`, `cantidad`, `costo_unitario`, `proveedor` (texto libre), `documento_ref`. Además declaró: "no inventes tablas ni columnas, el esquema está cerrado".

El Área 1 escribió su documento por separado y su requerimiento dice que una entrada necesita, como mínimo: SKU, código de barras, número de serie, lote, categoría, marca, modelo, proveedor como catálogo (no texto libre), país de origen, orden de compra, factura del proveedor, almacén destino, cantidad esperada vs recibida, estado de la mercancía, flete, impuestos, moneda, tipo de cambio. Y para manufactura: materias primas, órdenes de producción, BOM (lista de materiales), consumo, control de calidad.

Si cada área hace lo suyo sin hablar, pasan dos cosas malas:

- El Área 1 crea su propia tabla de productos o de entradas, y entonces hay **dos catálogos** y el stock del Área 3 no refleja lo que entró por el Área 1.
- O el Área 1 modifica `productos` a su gusto y rompe los triggers, vistas y contratos que el Área 3 ya publicó para las áreas 2, 4 y 6.

#### La solución: ampliar sin romper (migraciones aditivas)

La regla es: **el Área 1 sólo agrega, nunca cambia ni quita.** Todo lo que el Área 3 ya definió sigue existiendo con el mismo nombre, el mismo tipo y el mismo comportamiento. Lo nuevo se agrega en columnas opcionales y tablas nuevas. Así, el código, los triggers y las vistas del Área 3 siguen funcionando aunque nadie del Área 3 toque nada.

**Paso 1 · Columnas nuevas en `productos` (todas opcionales o con default).**

| Columna nueva | Tipo | Por qué no rompe nada |
| --- | --- | --- |
| `sku` | VARCHAR(50) UNIQUE, NULL | Es NULL para los productos que ya existen. El Área 3 nunca la lee. |
| `codigo_barras` | VARCHAR(50), NULL | Igual. |
| `categoria` | VARCHAR(100), NULL | Igual. |
| `marca` | VARCHAR(100), NULL | Igual. |
| `modelo` | VARCHAR(100), NULL | Igual. |
| `unidad_medida` | VARCHAR(20) DEFAULT 'PIEZA' | Tiene default, así que los INSERT del Área 3 que no la mencionan siguen funcionando. |
| `precio_venta_sugerido` | DECIMAL(12,2), NULL | Igual. |
| `stock_minimo` | INT DEFAULT 0 | Resuelve la pregunta abierta 5 del Área 3. |

Lo que **no** se toca: `valor_entrada`, `capital_inversion`, `volumen`, `stock` y sus CHECK. Esas cuatro columnas son el corazón del Área 3 y de sus contratos con las áreas 1, 2, 4 y 6.

**Paso 2 · Tablas nuevas, propiedad del Área 1.**

```text
proveedores          (id_proveedor, nombre, rfc, pais, contacto)
almacenes            (id_almacen, nombre, tipo: INSUMOS | PRODUCTO_TERMINADO, ubicacion)
lotes                (id_lote, id_producto, numero_lote, fecha_fabricacion, fecha_vence_garantia)
materias_primas      (id_materia, sku, nombre, unidad_medida, costo_unitario, stock, id_almacen)
ordenes_produccion   (id_orden, folio, id_producto_destino, cantidad_planeada, fecha_inicio, fecha_fin, responsable, estado)
bom                  (id_bom, id_producto_destino, id_materia, cantidad_por_unidad)
consumo_produccion   (id_consumo, id_orden, id_materia, cantidad_real, merma, motivo_merma, fecha)
control_calidad      (id_qc, id_orden, aprobadas, rechazadas, motivo_rechazo, responsable, fecha)
```

Ninguna de estas tablas existía en el Área 3, así que agregarlas no rompe nada. Todas apuntan a `productos` por `id_producto`, que sí existe. El Área 3 puede ignorarlas por completo.

**Paso 3 · Columnas nuevas en `entradas_producto` (opcionales).**

| Columna nueva | Para qué |
| --- | --- |
| `id_proveedor` FK → `proveedores`, NULL | Sustituye al texto libre `proveedor`. El texto libre **se conserva** para no romper `v_kardex`, que lo usa. |
| `id_almacen` FK → `almacenes`, NULL | Almacén destino. |
| `id_lote` FK → `lotes`, NULL | Trazabilidad por lote. |
| `id_orden_produccion` FK → `ordenes_produccion`, NULL | Si la entrada viene de manufactura (Vía B), aquí se liga. Si es compra directa (Vía A), queda NULL. |
| `cantidad_esperada` INT, NULL | Para detectar faltantes contra la orden de compra. |
| `estado_mercancia` VARCHAR(20) DEFAULT 'BUEN_ESTADO' | |
| `flete_unitario` DECIMAL(12,2) DEFAULT 0 | Parte de la fórmula de capital del Área 1. |
| `impuestos_unitarios` DECIMAL(12,2) DEFAULT 0 | Parte de la fórmula. Se llena con lo que calcule el Área 5. |
| `moneda` VARCHAR(3) DEFAULT 'MXN' | |
| `tipo_cambio` DECIMAL(10,4) DEFAULT 1 | |
| `pais_origen` VARCHAR(60), NULL | Lo lee el Área 5 para aduanas. |
| `numero_orden_compra`, `numero_factura_proveedor` VARCHAR(50), NULL | Enlace con contabilidad (Área 2). |
| `responsable_recepcion` VARCHAR(150), NULL | Trazabilidad. |

Como todas tienen NULL o default, un INSERT del Área 3 que sólo manda `id_producto, cantidad, costo_unitario` sigue funcionando exactamente igual.

**Paso 4 · El único punto donde sí hay que tocar algo del Área 3: el trigger de entrada.**

Hoy el trigger `fn_entrada_producto` hace:

```sql
capital_inversion = capital_inversion + (NEW.cantidad * NEW.costo_unitario)
```

El Área 1 validó con Finanzas que el capital real es `(costo + flete + impuesto) × cantidad`. Entonces el trigger cambia a:

```sql
capital_inversion = capital_inversion
    + NEW.cantidad * (NEW.costo_unitario + NEW.flete_unitario + NEW.impuestos_unitarios) * NEW.tipo_cambio
```

Como `flete_unitario` e `impuestos_unitarios` tienen default 0 y `tipo_cambio` default 1, **para una entrada del Área 3 que no manda esos campos el resultado es idéntico al de antes.** El cambio es compatible hacia atrás. Se hace en una migración nueva (`CREATE OR REPLACE FUNCTION`), nunca editando la migración original.

Este es el único cambio que necesita acuerdo explícito entre el líder 1 y el líder 3, y queda registrado como issue `tipo:integracion` con ambos líderes.

**Paso 5 · Las vistas del Área 3 no cambian de firma.**

`v_inventario_actual`, `v_kardex`, `v_rotacion`, `v_entradas_area1`, `v_salidas_area2` siguen devolviendo las mismas columnas. Las áreas 2, 4 y 6 que las consumen no se enteran de nada. Si el Área 1 quiere reportes con SKU, lote o almacén, crea **vistas nuevas** (`v_entradas_detalle`, `v_stock_por_almacen`) en vez de modificar las existentes.

#### Quién es dueño de qué después de D-03

| Objeto | Dueño | Nota |
| --- | --- | --- |
| `productos` (columnas originales + triggers + CHECK) | Área 3 | |
| `productos` (columnas nuevas: sku, marca, modelo, etc.) | Área 1 | Migración aditiva del Área 1 |
| `entradas_producto` (columnas originales) | Área 3 | |
| `entradas_producto` (columnas nuevas) | Área 1 | Migración aditiva del Área 1 |
| `fn_entrada_producto` | Área 3 | Cambio de fórmula acordado con Área 1, migración del Área 3 |
| `proveedores`, `almacenes`, `lotes`, `materias_primas`, `ordenes_produccion`, `bom`, `consumo_produccion`, `control_calidad` | Área 1 | |
| `ajustes_inventario`, `fn_salida_producto`, `fn_ajuste_inventario`, vistas `v_*` existentes | Área 3 | |

#### Lo que queda fuera por los 5 días

- Trazabilidad por **número de serie individual** (una fila por unidad física). Se deja el campo `numero_serie` en `lotes` como texto opcional con rangos, no una tabla de unidades. Si sobra tiempo, se agrega.
- **Multi-almacén en el stock**: `productos.stock` sigue siendo un total global. `id_almacen` en entradas permite saber por dónde entró, pero no hay stock por almacén. Es la pregunta abierta 1 del Área 3 y se responde "no, por ahora".
- Evidencia fotográfica de recepción: se guarda una URL en `documento_ref`, no hay carga de archivos.

**Estado: RECOMENDADO. Lo cierran los líderes 1 y 3 el domingo 13, día 1, en el issue de integración I-01.**

### D-04 · Alcance de "pago automático" (Área 5)

"Pago automático direccionado" no puede ser una transferencia bancaria real en un proyecto escolar. Se define como: **generación de la orden de pago + línea de captura + flujo de autorización + registro del comprobante**, como ya describe `docs/area5-fiscal/CONTEXTO.md`. Hay que dejarlo escrito para que nadie intente integrar un banco.

### D-05 · Frontend: ¿uno solo o uno por área?

**Recomendación:** una sola app React (Vite) con un módulo/carpeta por área y un menú común. Evita seis logins y seis estilos distintos. Cada área es dueña de `src/modules/areaN/`.

### D-06 · Idioma

Todo en **español**: código (nombres de tablas, columnas, funciones de negocio), commits, issues, documentación. Palabras reservadas y APIs de librerías quedan en inglés, obviamente.

### D-07 · Duración total del proyecto

**Cerrada (versión corregida el 12 de septiembre).** La coordinación prepara el repo el sábado 12. Los equipos trabajan del **domingo 13 al jueves 17 de septiembre de 2026, cinco días**. Entrega el jueves 17. Congelamiento de alcance el miércoles 16 a las 18:00. El viernes 18 no forma parte del plan.

Con 31 personas y cinco días la única forma de terminar es que el domingo sea de arranque real (contexto leído, roles asignados, integraciones acordadas) y que el alcance mínimo de la sección 12.3 sea la meta, no el piso.

### D-08 · Cero rastro de IA en el repositorio

**Cerrada.** Ningún commit, PR, issue, comentario ni documento entregable menciona el uso de IA. Detalle en la sección 8.6. Esto no prohíbe usar IA; prohíbe que quede registrado.

### D-09 · Orden de migraciones

Supabase aplica las migraciones por orden alfabético del nombre. Con prefijos `a1_`, `a3_` el orden alfabético no coincide con el orden de dependencias. Se usa numeración global con fecha y hora más sufijo de área: `20260912_1030_a3_triggers.sql`, que es lo que genera `supabase migration new`. **Recomendada; se confirma junto con el stack.**

---

## 4. Organización del equipo (31 personas en 6 áreas)

### 4.1 Distribución numérica

```text
31 personas
 = 1 coordinador general (tú)
 + 6 líderes de área
 + 24 integrantes  →  4 por área
```

**Cerrado:** el coordinador **sólo coordina**, no lidera ningún área. Cada área es 1 líder + 4 integrantes. Los nombres van en `docs/EQUIPOS.md`.

### 4.2 Roles

| Rol | Cuántos | Acceso al repo | Responsabilidades |
| --- | --- | --- | --- |
| **Coordinador general** | 1 | Admin | Estructura del repo, reglas, plantillas, etiquetas, tablero, guía de IA, revisión de PRs entre áreas, integración final. |
| **Líder de área** | 6 | Colaborador con permiso de escritura (write) | Dueño de `docs/areaN/`. Crea/refina issues de su área, asigna, revisa y aprueba PRs de su área, mantiene `ESTADO.md`, evalúa integrantes, entrega reporte final. |
| **Integrante** | 24 | Sin acceso directo. Trabaja en **fork** | Toma issues de su área, abre PRs desde su fork, actualiza su parte de la bitácora. |

### 4.3 Roles sugeridos dentro de cada equipo de área

Cada líder los asigna según la evaluación inicial de habilidades (sección 11). No todos los equipos necesitan los cuatro; una persona puede cubrir dos.

| Rol interno | Qué hace | Entregable típico |
| --- | --- | --- |
| Datos / BD | Migraciones, triggers, vistas, RLS de su área | Migraciones aplicadas sin error |
| Backend / lógica | Servicios `src/services/areaN/`, validaciones, cálculos | Funciones con pruebas |
| Frontend | Pantallas del módulo `src/modules/areaN/` | Pantallas funcionando contra Supabase |
| Documentación y pruebas | Mantiene `docs/areaN/`, datos de prueba (seed), capturas, contratos con otras áreas | Docs actualizados, seed, evidencias |

### 4.4 Comunicación entre áreas

Las dependencias entre áreas ya están identificadas en el doc del Área 3 (sección 11, "contratos de interfaz"). Regla: **las otras áreas consumen vistas, nunca tablas.** Cada dependencia se registra como issue con etiqueta `tipo:integracion` y las dos áreas involucradas.

Dependencias conocidas:

```text
Área 1 (entradas)   escribe: entradas_producto, proveedores, almacenes, lotes, órdenes de producción
Área 3 (inventario) dueño de: productos, ajustes_inventario, triggers de stock, vistas v_*
Área 2 (contable)   escribe: facturas, detalle_factura (el trigger del área 3 valida stock), clientes
Área 4 (nómina)     escribe: agentes_ventas, nómina, comisiones      lee: v_rotacion, facturas por agente
Área 5 (fiscal)     escribe: obligaciones, pagos, importaciones, licencias, alertas   lee: entradas (país de origen, impuestos)
Área 6 (marketing)  escribe: marketing, clientes_marketing            lee: v_rotacion, clientes
```

---

## 5. Estructura propuesta del repositorio

```text
SIGFEVAK/
├── README.md                     ← qué es el proyecto, cómo arrancar, enlaces a todo
├── PLAN.md                       ← este archivo
├── CLAUDE.md                     ← reglas generales para Claude Code (todo el equipo lo hereda al clonar)
├── AGENTS.md                     ← mismo contenido para Cursor, Codex, Copilot y demás
├── .claude/                      ← configuración compartida de Claude Code (ver sección 9.4)
│   ├── settings.json             ← attribution apagada, permisos base, hook anti-rastro
│   ├── rules/                    ← reglas por ruta: una por área, se cargan solo al tocar esa carpeta
│   │   ├── area1-entradas.md
│   │   ├── ...
│   │   └── migraciones.md
│   ├── skills/                   ← skills compartidas: todos tienen las mismas
│   │   ├── tomar-issue/SKILL.md
│   │   ├── nueva-migracion/SKILL.md
│   │   ├── preparar-pr/SKILL.md
│   │   ├── actualizar-estado/SKILL.md
│   │   └── contexto-area/SKILL.md
│   ├── agents/                   ← subagentes opcionales (revisor de PR, verificador de RN)
│   └── hooks/
│       └── check-commit.sh       ← bloquea commits con "Co-Authored-By" o "Generated with"
├── CONTRIBUTING.md               ← flujo de fork → issue → rama → PR, paso a paso con comandos
├── CODE_OF_CONDUCT.md            ← corto: respeto, no subir credenciales, no borrar trabajo ajeno
├── LICENSE
├── .gitignore
├── .env.example                  ← SUPABASE_URL, SUPABASE_ANON_KEY (nunca el service_role)
├── .editorconfig
├── .prettierrc                   ← formato único
├── .eslintrc.cjs
├── package.json
│
├── .github/
│   ├── CODEOWNERS                ← cada docs/areaN/ y src/modules/areaN/ → su líder
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── tarea.yml             ← tarea normal de un área
│   │   ├── bug.yml
│   │   ├── integracion.yml       ← dependencia entre dos áreas
│   │   └── config.yml
│   ├── labels.yml                ← definición de etiquetas (se aplica con un script/acción)
│   └── workflows/
│       ├── lint.yml              ← prettier + eslint en cada PR
│       └── sql-lint.yml          ← valida que las migraciones tengan prefijo y no se editen las aplicadas
│
├── docs/
│   ├── DECISIONES.md             ← ADRs D-01 … D-nn
│   ├── EQUIPOS.md                ← quién está en qué área, líderes, roles internos
│   ├── MODELO_DATOS.md           ← modelo ER completo de las 6 áreas + dueño de cada tabla
│   ├── GLOSARIO.md               ← términos de negocio (stock vs volumen, pedimento, NICO, kardex…)
│   ├── GUIA_IA.md                ← cómo trabajar con agentes, prompts base, qué revisar
│   ├── GUIA_GIT.md               ← fork, sync, ramas, commits, PR (con capturas si hace falta)
│   ├── GUIA_ESTILO.md            ← tokens, componentes y reglas visuales (referencia Figma Make)
│   ├── referencia-ui/            ← App.jsx e index.css exportados de Figma Make; no se editan
│   ├── plantillas/
│   │   ├── EVALUACION_HABILIDADES.md
│   │   ├── REPORTE_FINAL_LIDER.md
│   │   └── BITACORA_SEMANAL.md
│   ├── area1-entradas/
│   │   ├── CONTEXTO.md           ← fuente de verdad del área (formato común de 17 secciones)
│   │   ├── ESTADO.md             ← bitácora viva: qué está hecho, en curso, bloqueado
│   │   ├── TAREAS.md             ← desglose de issues planeados antes de subirlos a GitHub
│   │   ├── EVALUACION.md         ← matriz de habilidades del equipo (la llena el líder)
│   │   ├── evidencias/           ← capturas y pruebas por issue; respaldo de todo lo entregado
│   │   └── originales/           ← documentos tal como los entregó el equipo; no se editan
│   ├── area2-contabilidad/       ← mismos 4 archivos
│   ├── area3-inventario/         ← mismos archivos
│   ├── area4-nomina/
│   ├── area5-fiscal/             ← mismos archivos
│   └── area6-marketing/
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 0000_tipos_enum.sql             ← compartido (coordinador / área 3)
│   │   ├── 0001_tablas_base.sql            ← tablas compartidas
│   │   ├── a3_0001_tablas_inventario.sql   ← prefijo aN_ = área dueña
│   │   ├── a3_0002_triggers.sql
│   │   ├── a1_0001_proveedores_almacenes.sql
│   │   ├── a2_0001_facturas.sql
│   │   ├── a4_0001_nomina.sql
│   │   ├── a5_0001_obligaciones.sql
│   │   ├── a6_0001_marketing.sql
│   │   └── ...
│   └── seed/
│       ├── seed_area1.sql
│       └── ...
│
└── src/
    ├── lib/
    │   └── supabaseClient.js     ← único cliente; nadie crea otro
    ├── services/
    │   ├── area1/                ← funciones de acceso a datos de cada área
    │   ├── area2/
    │   └── ...
    ├── modules/
    │   ├── area1-entradas/       ← pantallas React del área
    │   ├── area2-contabilidad/
    │   └── ...
    ├── components/               ← componentes compartidos (tabla, formulario, layout)
    └── App.jsx                   ← menú principal con un enlace por área
```

**Reglas de propiedad:**

- `docs/areaN/`, `src/services/areaN/`, `src/modules/areaN/` y `supabase/migrations/aN_*` son del área N. `CODEOWNERS` obliga a que el líder de esa área apruebe cualquier PR que los toque.
- `src/lib/`, `src/components/`, `supabase/migrations/0000_*`, `docs/*.md` de raíz y `.github/` son del coordinador.
- Ningún área modifica archivos de otra área sin un issue `tipo:integracion` aprobado por ambos líderes.

> Nota sobre el orden de migraciones: ver D-09. Los nombres `aN_0001_*` del árbol de arriba son ilustrativos; el formato final es `AAAAMMDD_HHMM_aN_descripcion.sql`.

---

## 6. Flujo de trabajo en GitHub

> **Modo vigente desde el 13 de septiembre.** La coordinación construye las seis áreas con cada líder como coautor de los commits de su área. Ramas por bloque, un commit por bloque con `Cierra #nn`, merge a `main` en local y push. Sin pull request obligatorio. La coordinación puede crear, asignar y cerrar issues, aprobar y mergear PRs de cualquier área y subir a `main`. Los líderes e integrantes contribuyen por PR cuando quieran. Lo que sigue en esta sección es el flujo de PR para esas contribuciones.

### 6.1 Ramas

```text
main            ← protegida. Sólo se entra por PR aprobado. Siempre debe funcionar.
develop         ← (opcional) integración. Si el grupo es poco experimentado, mejor NO usarla.
areaN/<issue>-<descripcion>   ← ramas de trabajo, viven en el fork del integrante
```

Recomendación: **sin `develop`**. PRs pequeños directo a `main`. Menos conflictos, menos confusión para 31 personas.

### 6.2 Protección de `main`

- Opcional en el modo vigente: `main` no está protegida porque la coordinación sube directo por bloques. Si se activa, requeriría PR con 1 aprobación y revisión de dueños de código.

### 6.3 Flujo del integrante (va en `CONTRIBUTING.md` con comandos exactos)

1. Hace **fork** del repo una sola vez.
2. Clona su fork y agrega `upstream` apuntando al repo original.
3. Elige un issue de su área con etiqueta `estado:disponible`, comenta "lo tomo", el líder lo asigna.
4. Sincroniza `main` con upstream, crea rama `areaN/<num-issue>-<descripcion-corta>`.
5. Trabaja. Commits con el formato de la sección 8.
6. Abre PR contra `main` del repo original. Llena la plantilla (qué issue cierra, qué se probó, si usó IA).
7. El líder revisa. Si hay cambios, los hace en la misma rama. Cuando aprueba, el líder hace merge.
8. El integrante actualiza su línea en `docs/areaN/ESTADO.md` (puede ir en el mismo PR).

### 6.4 Flujo del líder

- Fase 0: llena `EVALUACION.md` de su equipo y `TAREAS.md` con el desglose de su área.
- Sube las tareas como issues usando la plantilla, con etiquetas de área, tipo y prioridad.
- Revisa PRs de su área en menos de 12 h.
- Actualiza `ESTADO.md` todos los días al cierre.
- Reasigna tareas cuando alguien va atrasado o cuando descubre que alguien es mejor en otra cosa (esto queda registrado en `EVALUACION.md`, es parte del requisito).
- Al final entrega `REPORTE_FINAL.md` usando la plantilla.

### 6.5 Tablero (GitHub Projects)

Un solo tablero "SIGFEVAK" con vistas:

- **Por área** (agrupado por etiqueta `area:*`).
- **Por estado**: Backlog → Disponible → En progreso → En revisión → Hecho.
- **Bloqueados** (filtro `estado:bloqueado`).

Los issues se agregan automáticamente al tablero con un workflow.

---

## 7. Sistema de issues y etiquetas

### 7.1 Etiquetas (`.github/labels.yml`)

| Grupo | Etiquetas | Color sugerido |
| --- | --- | --- |
| Área | `area:1-entradas` `area:2-contabilidad` `area:3-inventario` `area:4-nomina` `area:5-fiscal` `area:6-marketing` `area:transversal` | un color por área |
| Tipo | `tipo:bd` `tipo:backend` `tipo:frontend` `tipo:docs` `tipo:pruebas` `tipo:integracion` `tipo:bug` | azules |
| Prioridad | `prioridad:alta` `prioridad:media` `prioridad:baja` | rojo / naranja / gris |
| Estado | `estado:disponible` `estado:en-progreso` `estado:en-revision` `estado:bloqueado` | verdes/amarillo |
| Dificultad | `nivel:inicial` `nivel:medio` `nivel:avanzado` | para que cada quien elija según su nivel |
| Especial | `buena-primera-tarea` `necesita-decision` | — |

`nivel:*` es importante porque el requisito dice que "puede que algunos trabajen más, menos". Una persona con menos experiencia toma tareas `nivel:inicial`; el líder lo registra en la evaluación.

### 7.2 Plantilla de issue de tarea (`tarea.yml`)

Campos obligatorios:

- **Área** (desplegable).
- **Objetivo** en una frase.
- **Contexto**: enlace a la sección de `docs/areaN/CONTEXTO.md` que aplica.
- **Criterios de aceptación**: lista verificable ("la migración se aplica sin error", "la pantalla muestra X", "el trigger rechaza stock negativo").
- **Archivos que se espera tocar**.
- **Reglas de negocio involucradas** (`RN-xx` del área).
- **Depende de** (otros issues).

### 7.3 Definición de "hecho"

Un issue se cierra sólo cuando:

1. El PR está mergeado en `main`.
2. Los criterios de aceptación están marcados.
3. Hay evidencia (captura, salida de consola o prueba) guardada en `docs/areaN-*/evidencias/` y enlazada en el PR.
4. `docs/areaN/ESTADO.md` refleja el cambio.

---

## 8. Convenciones y reglas de estilo

### 8.1 Commits

Formato: `areaN: <verbo en presente> <objeto> (RN-xx opcional) #issue`

```text
area3: agrega trigger de conciliación (RN-A3-07) #42
area1: crea tabla proveedores y almacenes #17
area5: corrige cálculo de DTA con tasa 8 al millar #58
docs: actualiza ESTADO del área 2
coord: agrega plantilla de PR
```

Prefijos válidos: `area1` … `area6`, `docs`, `coord`, `fix`, `ci`.

### 8.2 Base de datos (heredado del Área 3, aplica a todas)

- Tablas y columnas en `minusculas_con_guion_bajo`, en español.
- Tablas en plural (`productos`), llaves en singular (`id_producto`).
- Enums como tipos PostgreSQL. Los valores se documentan en `MODELO_DATOS.md`. **No se agregan valores sin registrarlo.**
- Migraciones numeradas con prefijo de área. **Nunca se edita una migración ya aplicada**; cualquier cambio es una migración nueva.
- Toda función y trigger lleva comentario con el `RN-xx` que implementa.
- Validaciones de negocio críticas viven en la BD (CHECK, trigger), no sólo en el frontend.
- RLS activado en todas las tablas con política mínima para `authenticated`.

### 8.3 JavaScript / React

- Prettier + ESLint con la configuración del repo. El CI falla si no está formateado.
- Gestor de paquetes único: pnpm o bun según S-11. **Nunca npm.** Un solo lockfile en el repo; si aparece un `package-lock.json` en un PR, se rechaza.
- Un solo cliente Supabase en `src/lib/supabaseClient.js`.
- El acceso a datos va en `src/services/areaN/*.js`. Los componentes React **no** llaman a `supabase.from()` directamente.
- Nombres de funciones en español y descriptivos: `registrarEntrada`, `obtenerKardex`, `calcularISN`.
- Nada de SQL crudo desde el frontend; consultas por `supabase-js`, vistas para reportes.
- Componentes en `PascalCase`, archivos de componentes `NombreComponente.jsx`.

### 8.4 Documentación

- Cada área tiene exactamente los 4 archivos de la sección 5. Los nombres no cambian.
- Reglas de negocio numeradas por área: `RN-A1-01`, `RN-A3-07`, etc., para que no choquen entre áreas.
- Diagramas en Mermaid dentro del markdown (GitHub los renderiza).

### 8.5 Seguridad mínima

- `.env` en `.gitignore`. Sólo `.env.example` se sube.
- Nunca subir la `service_role` key de Supabase.
- Contraseñas de usuarios del sistema con hash (Supabase Auth lo resuelve).

### 8.6 Cero rastro de IA (regla D-08)

Usar IA está permitido y hay guía para hacerlo bien (sección 9). Lo que **no** está permitido es que quede registrado en ningún lado. Concretamente:

| Dónde | Prohibido | Cómo se evita |
| --- | --- | --- |
| Commits | Líneas `Co-Authored-By` de una herramienta, `Generated with`, enlaces de sesión, o cualquier mención a IA en el mensaje. Los `Co-Authored-By` de personas del equipo sí se permiten y se recomiendan para reconocer quién participó | En Claude Code: `"includeCoAuthoredBy": false` en `~/.claude/settings.json` (se indica en `docs/GUIA_IA.md`). En Copilot y Cursor no se acepta el mensaje de commit generado sin leerlo. Antes de hacer push: `git log -1` y revisar. |
| PRs | Cualquier texto tipo "generado con", "con ayuda de IA", enlaces a sesiones, emojis de robot | La plantilla de PR no tiene casilla de IA. El líder rechaza el PR si lo ve y pide reescribir la descripción. |
| Issues y comentarios | Igual que arriba | Igual que arriba. |
| Etiquetas | No existen etiquetas `ia-*` | Eliminadas de `labels.yml`. |
| Documentación entregable, reportes, ESTADO.md | No hay sección "uso de IA" ni menciones | Las plantillas no la incluyen. |
| Código | Comentarios tipo "// generado por ChatGPT", "// AI-generated" | Revisión del líder antes de merge. |
| Historial | Si un commit con rastro ya se mergeó | El coordinador lo corrige con `git commit --amend` o `rebase` **antes** de que otros sincronicen; por eso el merge es por squash: se puede reescribir el mensaje final del squash en GitHub. |

**Sobre los archivos de guía (P-05, cerrada):** `CLAUDE.md`, `AGENTS.md` y la carpeta `.claude/` **sí se suben al repo**, siguiendo el estándar de Claude Code (sección 9.4). La regla de cero rastro aplica a commits, PRs, issues, comentarios de código y documentos entregables; no a los archivos de configuración de herramientas. La ventaja de subirlos es que las 31 personas heredan la misma configuración, las mismas reglas y las mismas skills con solo clonar, y la `attribution` queda apagada para todos sin que cada quien tenga que configurarla.

---

## 9. Guía de uso de IA y agentes

El objetivo es que 31 personas con niveles distintos puedan usar Claude Code, Copilot, Cursor o ChatGPT **sin romper el proyecto**. Se apoya en tres piezas:

### 9.1 `CLAUDE.md` / `AGENTS.md` en la raíz

Archivo que los agentes leen automáticamente. Contenido planeado:

```text
# Reglas para agentes de IA en SIGFEVAK

1. Antes de tocar cualquier cosa, lee docs/areaN/CONTEXTO.md del área del issue.
   Ese archivo es la fuente de verdad. Si el código lo contradice, el código está mal.
2. No inventes tablas, columnas ni valores de enum. Si falta algo, escríbelo como
   pregunta abierta en docs/areaN/CONTEXTO.md sección "Preguntas abiertas" y detente.
3. No toques archivos fuera de la carpeta del área del issue (docs/areaN, src/services/areaN,
   src/modules/areaN, supabase/migrations/aN_*). Si necesitas algo de otra área, dilo.
4. Nunca escribas productos.stock directamente (RN-A3-06). Los triggers lo hacen.
5. Nunca edites una migración ya existente. Crea una nueva.
6. Cita la regla de negocio (RN-xx) en comentarios, commits y PR.
7. Commits en español con formato areaN: verbo objeto #issue.
8. No agregues dependencias sin justificarlo en el PR. Instala siempre con pnpm (o bun), nunca con npm: los lockfiles se corrompen al mezclar gestores.
9. No subas .env ni llaves.
10. Stack fijo: React + Vite, supabase-js, PostgreSQL en Supabase, pnpm. No propongas otro ni agregues backend.
11. Nunca agregues líneas Co-Authored-By, "Generated with", enlaces de sesión ni ninguna
    mención a IA en commits, PRs, issues, comentarios de código ni documentación.
    El mensaje de commit es solo "areaN: verbo objeto #issue".
```

Más una sección "Mapa del repo" y "Comandos" (`pnpm dev`, `pnpm lint`, `supabase db push`).

`CLAUDE.md` vive en la raíz del repo y se sube (P-05 cerrada). `AGENTS.md` tiene el mismo contenido para quien use Cursor, Codex o Copilot; `CLAUDE.md` lo importa con la línea `@AGENTS.md` para no mantener dos copias.

### 9.2 `docs/GUIA_IA.md` (para humanos)

- **Cuándo sí**: generar boilerplate, explicar un error, escribir una migración a partir del diccionario de datos, redactar pruebas, revisar tu propio PR antes de subirlo.
- **Cuándo con cuidado**: cálculos fiscales (ISR, IVA, IGI, DTA), triggers de stock, RLS. Siempre verificar contra `CONTEXTO.md`; la IA inventa tasas y columnas.
- **Cuándo no**: decisiones de alcance, cambiar el modelo de datos, tocar otra área.
- **Prompt base** (copiar y pegar):

  ```text
  Estoy trabajando en el issue #NN del área N del proyecto SIGFEVAK.
  Lee primero CLAUDE.md y docs/areaN/CONTEXTO.md.
  El objetivo del issue es: <pegar objetivo y criterios de aceptación>.
  Sólo modifica archivos dentro de <carpetas del área>.
  Cita las reglas RN-xx que apliquen. Si algo no está definido en CONTEXTO.md, pregúntame antes de asumir.
  ```

- **Revisión obligatoria**: todo código generado por IA lo lee la persona línea por línea antes de abrir el PR. La plantilla de PR tiene la casilla "Revisé y entiendo cada cambio: [ ]", sin mencionar IA.
- **Antes de cada push**, checklist de limpieza: `git log -1` sin líneas de coautoría, descripción del PR sin menciones a herramientas, sin comentarios "generado por" en el código.
- **Configuración inicial**: quien use Claude Code ya hereda la atribución apagada y el hook anti-rastro desde `.claude/settings.json` al clonar (sección 9.4). Quien use Copilot o Cursor no acepta mensajes de commit sugeridos sin editarlos.
- **La sección 1 de cada `CONTEXTO.md`** ("Cómo debe usar este documento un agente", que el Área 3 ya tiene) se generaliza a las seis áreas. Es la instrucción específica del área; `CLAUDE.md` es la general.

### 9.3 Tareas donde la IA suele fallar (para que el líder lo sepa al asignar)

No se etiqueta en el issue (regla D-08), pero el líder lo tiene en cuenta y lo dice de palabra:

- Cálculos fiscales del Área 5 (ISR, IVA, IGI, DTA, ISN): la IA inventa tasas. Verificar contra `CONTEXTO.md`.
- Triggers de stock del Área 3: la IA tiende a actualizar `stock` a mano y duplica el incremento.
- RLS de Supabase: la IA olvida las políticas y todo regresa vacío.
- Cualquier cosa que cruce dos áreas.

### 9.4 Estándar de la carpeta `.claude/` y skills compartidas

Verificado contra la documentación oficial de Claude Code (septiembre 2026). Todo esto se sube al repo para que las 31 personas hereden lo mismo al clonar.

#### Archivos y qué hace cada uno

| Ruta | Qué es | Se sube |
| --- | --- | --- |
| `CLAUDE.md` (raíz) | Memoria del proyecto. Claude Code la lee al iniciar en el repo. Contiene las 11 reglas de 9.1, el mapa del repo y los comandos. | Sí |
| `CLAUDE.local.md` | Notas personales de cada quien. | No (en `.gitignore`) |
| `AGENTS.md` | Mismo contenido para otras herramientas. `CLAUDE.md` lo importa con `@AGENTS.md`. | Sí |
| `.claude/settings.json` | Configuración compartida del proyecto: atribución apagada, permisos base, hooks. | Sí |
| `.claude/settings.local.json` | Overrides personales. Claude Code lo crea al cambiar un ajuste. | No (en `.gitignore`) |
| `.claude/rules/<nombre>.md` | Reglas por ruta. Con frontmatter `paths:` se cargan sólo cuando se toca esa carpeta. Una por área más una de migraciones. | Sí |
| `.claude/skills/<nombre>/SKILL.md` | Skills invocables con `/nombre`. Reemplazan a `.claude/commands/`, que está deprecado. | Sí |
| `.claude/agents/<nombre>.md` | Subagentes con frontmatter `name`, `description`, `tools`, `model`. Opcionales. | Sí |
| `.claude/hooks/check-commit.sh` | Script que revisa el mensaje de commit antes de ejecutarlo. | Sí |

#### `.claude/settings.json` planeado

```json
{
  "attribution": {
    "commit": false,
    "pr": false,
    "sessionUrl": false
  },
  "permissions": {
    "allow": [
      "Bash(pnpm lint)",
      "Bash(pnpm dev)",
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git diff *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "if": "Bash(git commit *)",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/check-commit.sh" }
        ]
      }
    ]
  }
}
```

- `attribution` con los tres valores en `false` elimina las líneas `Co-Authored-By`, el pie de PR y el enlace de sesión. La clave vieja `includeCoAuthoredBy` está deprecada; no se usa.
- El hook `PreToolUse` corre antes de cada `git commit` que lance Claude Code y lo **bloquea** si el mensaje contiene `Co-Authored-By`, `Generated with`, `Claude`, `Copilot`, `ChatGPT` o `Cursor`. Es la red de seguridad de la regla D-08 para quien use Claude Code; quien use otra herramienta depende de la revisión manual y del líder.
- `permissions.deny` sobre `.env` evita que un agente lea y pegue llaves en un PR.

#### `.claude/rules/` planeado

Una regla por área, con `paths:` apuntando a sus carpetas. Ejemplo para el área 4:

```markdown
---
paths:
  - "docs/area4-nomina/**"
  - "src/services/area4/**"
  - "src/modules/area4-nomina/**"
  - "supabase/migrations/*_a4_*.sql"
---

# Reglas del área 4
- Lee docs/area4-nomina/CONTEXTO.md antes de cualquier cambio.
- Toda tasa o tope legal se lee de parametros_legales; nunca se escribe en código (RN-A4-14).
- No modifiques facturas, clientes ni productos: son de las áreas 2 y 3.
- Cita RN-A4-xx en commits y comentarios.
```

Y una regla `migraciones.md` con `paths: ["supabase/migrations/**"]`: nunca editar una migración existente, nombre `AAAAMMDD_HHMM_aN_descripcion.sql`, comentario con la RN que implementa.

#### Skills compartidas planeadas

Todas con `disable-model-invocation: true` para que sólo las dispare la persona, no el agente por su cuenta.

| Skill | Qué hace al invocarla | Argumentos |
| --- | --- | --- |
| `/tomar-issue` | Lee el issue de GitHub con `gh issue view`, identifica el área por la etiqueta, carga el `CONTEXTO.md` de esa área, sincroniza `main` con `upstream`, crea la rama `areaN/<num>-<slug>` y resume qué archivos se espera tocar y qué RN aplican. | número de issue |
| `/contexto-area` | Carga `docs/areaN/CONTEXTO.md` y responde con: tablas de escritura y lectura, reglas RN numeradas, preguntas abiertas. Para orientarse antes de pedir código. | número de área |
| `/nueva-migracion` | Crea `supabase/migrations/AAAAMMDD_HHMM_aN_<slug>.sql` con encabezado (área, issue, RN), y recuerda que no se edita una migración aplicada. | área, descripción |
| `/preparar-pr` | Corre `pnpm lint`, revisa `git log` de la rama buscando rastro de IA, verifica que los archivos tocados estén dentro de la carpeta del área, redacta la descripción con la plantilla y, si todo pasa, hace push y abre el PR. | ninguno |
| `/actualizar-estado` | Agrega o mueve la línea del issue en `docs/areaN/ESTADO.md` (Hecho, En progreso, Bloqueado) con la fecha. | número de issue, estado |
| `/revisar-pr` | Para líderes. Lee el diff de un PR con `gh pr diff`, verifica que sólo toque la carpeta del área, que cite RN, que no tenga rastro de IA ni `.env`, y devuelve una lista de observaciones. Aprueba, pide cambios o comenta en GitHub si el líder lo confirma. | número de PR |

Formato de cada `SKILL.md` (verificado):

```markdown
---
name: tomar-issue
description: Toma un issue de GitHub, carga el contexto del área y crea la rama de trabajo
disable-model-invocation: true
arguments: [issue]
allowed-tools: Bash(gh issue view *) Bash(git fetch *) Bash(git checkout *) Bash(git switch *) Read Grep
---

Pasos para el issue #$issue:
1. ...
```

Cada área puede agregar skills propias en la misma carpeta con prefijo `area4-`, por ejemplo `/area4-calcular-periodo`, siempre por PR revisado por el coordinador.

#### Subagentes opcionales

Sólo si sobra tiempo en la fase 0. Candidato: `.claude/agents/verificador-rn.md`, un revisor de solo lectura (`tools: Read, Grep, Glob`) que recibe un diff y una lista de reglas RN y dice cuáles se cumplen y cuáles no.

#### Qué va en `.gitignore` por esto

```text
CLAUDE.local.md
.claude/settings.local.json
.env
.env.*
!.env.example
```

---

## 10. Documentos guía por área (los markdowns de seguimiento)

Cada `docs/areaN/` tendrá estos cuatro archivos con estructura fija. El coordinador crea los esqueletos; el líder los llena.

### `CONTEXTO.md` — fuente de verdad del área

Estructura (tomada del doc del Área 3, que es el mejor ejemplo):

1. Cómo debe usar este documento un agente
2. Contexto de negocio del área
3. Alcance: qué sí, qué no, tablas de escritura y de lectura
4. Modelo ER del área (Mermaid)
5. Diccionario de datos
6. Flujos (Mermaid)
7. Reglas de negocio numeradas `RN-AN-xx`
8. DDL / migraciones
9. Vistas y contratos con otras áreas
10. Preguntas abiertas
11. Glosario

### `ESTADO.md` — bitácora viva

```text
# Estado — Área N

Última actualización: AAAA-MM-DD por <líder>

## Semáforo
🟢 En tiempo / 🟡 Riesgo / 🔴 Atrasado — <una línea de por qué>

## Hecho
- [x] #12 tabla proveedores (Ana) — mergeado 2026-09-15
## En progreso
- [ ] #14 pantalla de entradas (Luis) — PR abierto
## Bloqueado
- [ ] #16 trigger de capital — espera decisión D-03 con área 3
## Próximo
- #18, #19

## Bitácora
### Semana 1 (fechas)
- Qué se hizo, qué se aprendió, qué se cambió de asignación y por qué.
```

### `TAREAS.md` — desglose previo a issues

Lista de tareas con: título, tipo, nivel, dependencias, estimación (S/M/L), persona sugerida. Se convierte en issues cuando el líder la aprueba. Sirve para que el coordinador vea la carga total antes de arrancar.

### `EVALUACION.md` — matriz de habilidades (la llena el líder, ver sección 11)

---

## 11. Rol del líder: evaluación de habilidades y reporte final

Este es un requisito explícito del proyecto y se estandariza para las 6 áreas.

### 11.1 Evaluación inicial (fase 0) — `docs/plantillas/EVALUACION_HABILIDADES.md`

Cada líder aplica un cuestionario corto a su equipo (10 min) y llena la matriz:

| Integrante | Git/GitHub | SQL/BD | JavaScript | React | Documentación | Uso de IA | Disponibilidad (h/sem) | Interés | Rol asignado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Nombre | 1-5 | 1-5 | 1-5 | 1-5 | 1-5 | 1-5 | n | texto | Datos / Backend / Frontend / Docs |

Escala: 1 = nunca lo ha usado, 3 = lo ha usado con ayuda, 5 = puede enseñar a otros.

Con esto el líder asigna roles internos (sección 4.3) y elige issues con `nivel:*` acorde.

### 11.2 Evaluación continua (matriz con pesos, estándar para las 6 áreas)

Propuesta por el líder del Área 4 y adoptada para todos. Al cierre de cada día el líder califica a cada integrante de 1 a 5 en cinco criterios; el promedio ponderado es la calificación del día.

| Criterio | Peso | Qué observa el líder |
| --- | --- | --- |
| Cumplimiento de entregas | 30% | Entrega a tiempo y completa |
| Calidad técnica | 25% | Errores encontrados en revisión o pruebas |
| Comunicación y colaboración | 20% | Avisa bloqueos, apoya a otros, asiste a reuniones |
| Solución de problemas e iniciativa | 15% | Propone mejoras, resuelve sin esperar instrucciones |
| Aprendizaje y adaptación | 10% | Aplica la retroalimentación recibida |

### 11.3 Reglas para reasignar tareas

- Si un integrante saca **menos de 3** en una tarea crítica, o esa tarea lleva **más de medio día de retraso**, el líder la reasigna o pone a otro integrante a trabajar en pareja.
- Si alguien saca **4.5 o más** de forma sostenida, puede recibir tareas de mayor complejidad o liderar una subparte.

Cada cambio se anota en `EVALUACION.md`, sección "Registro de control de cambios":

| Fecha | Tarea (issue) | Responsable anterior | Nuevo responsable | Motivo | Impacto en cronograma | Vo.Bo. líder |
| --- | --- | --- | --- | --- | --- | --- |

Esto es evidencia directa del requisito "con la posibilidad de modificar las acciones o tareas".

### 11.3 Reporte final — `docs/plantillas/REPORTE_FINAL_LIDER.md`

Secciones fijas:

1. Resumen del área: objetivo, qué se entregó, qué quedó fuera y por qué.
2. Equipo: tabla con integrante, rol, issues cerrados, PRs, aporte cualitativo.
3. Evaluación individual: habilidades detectadas al inicio vs al final (misma matriz), fortalezas, áreas de mejora.
4. Cambios de asignación realizados y su resultado.
5. Integraciones con otras áreas: qué se acordó, qué funcionó, qué no.
6. Lecciones aprendidas.
7. Evidencias: enlaces a PRs, capturas, vistas funcionando.

El coordinador consolida los 6 reportes en `docs/REPORTE_FINAL_PROYECTO.md`.

---

## 12. Cronograma día por día (12 al 17 de septiembre) y checklist de preparación

### 12.1 Calendario

La coordinación preparó el repo el sábado 12. Los equipos trabajan **cinco días**, del domingo 13 al jueves 17. El viernes 18 no forma parte del plan. Versión corregida el 12 de septiembre: la anterior tenía los nombres de día corridos y la entrega un día tarde.

| Día | Fecha | Fase | Coordinador | Líderes | Integrantes | Hito del día |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Sáb 12 sep | Preparación | Repo publicado con contextos, tareas, guías, `CODEOWNERS` y flujo de la app. Sube los issues de las seis áreas. Avisa a los líderes con el enlace a `docs/EMPIEZA_AQUI.md`. | Reciben el enlace. Leen `EMPIEZA_AQUI.md` y su `CONTEXTO.md`. | Nada todavía. | Todo publicado; issues creados. |
| 1 | Dom 13 sep | Arranque | Migración base (enums compartidos, `usuarios`, tablas base) y seed compartido. App base con menú y módulos vacíos. Destraba integraciones reuniendo a los dos líderes que haga falta. | Leen el contexto con su equipo. Evaluación inicial de habilidades y roles internos. Cierran los acuerdos de integración I-01 a I-13 con su contraparte, en el issue. Asignan los issues del lunes. | Fork, clonar, `upstream`, hook de commit. PR de bienvenida con su nombre en `EQUIPOS.md`. Leen su contexto. | Seis equipos con roles, forks hechos, integraciones acordadas, app base corre. |
| 2 | Lun 14 sep | Base de datos | Revisa PRs de migraciones, resuelve choques entre áreas. | Revisan y mergean migraciones y seed. `ESTADO.md` y evaluación al cierre. | Migraciones del área, seed, triggers, RLS, pruebas SQL. | `supabase db reset` levanta las seis áreas sin errores, con seed. |
| 3 | Mar 15 sep | Vistas, servicios y captura | Revisa vistas de contrato y estilo de pantallas. Resumen general con datos del seed. | Reasignan según avance (queda en `EVALUACION.md`). PRs en menos de 6 h. | Vistas `v_*` publicadas. `src/services/areaN/`. Pantallas de alta y listado conectadas. | Cada área captura y lista desde la app; las demás ya leen sus vistas. |
| 4 | Mié 16 sep | Flujos e integración | Prueba el flujo de 14 pasos de `docs/FLUJO_APP.md`. **18:00 congelamiento de alcance.** | Cierran issues `tipo:integracion`. Validan cifras contra el seed. Deciden qué extra entra antes de las 18:00. | Pantallas de flujo con estados y reportes. Pruebas de punta a punta con las áreas contraparte. | El flujo completo corre de punta a punta. Alcance cerrado. |
| 5 | Jue 17 sep | Cierre y entrega | Consolida los seis reportes. Verifica el historial (D-08). Entrega. | `REPORTE_FINAL.md` antes de las 14:00. Evaluación final. | Corrección de bugs en la mañana. Evidencias en `docs/areaN-*/evidencias/`. Contexto actualizado. | **Entrega.** |

Reglas del calendario:

- Los PRs se revisan el mismo día. Un PR que espera más de 6 h bloquea a alguien; si el líder no alcanza, aprueba la coordinación.
- Cada líder actualiza `ESTADO.md` **todos los días** al cierre y llena la evaluación del día.
- Nada nuevo entra después del miércoles 16 a las 18:00. Sin excepciones; es la única forma de entregar el jueves.
- La coordinación puede tomar issues de cualquier área, asignárselos, revisar, aprobar y mergear PRs de cualquier área. Lo único que GitHub no permite es aprobar el PR propio: los PRs de la coordinación los aprueba el dueño del repo o el líder del área que tocan.

### 12.2 Checklist de preparación (sábado 12, coordinación)

Hecho:

- [x] Decisiones D-01 a D-09 escritas en `docs/DECISIONES.md`.
- [x] Estructura de carpetas, README, CONTRIBUTING, guías, glosario, plantillas.
- [x] Plantillas de issue y PR, `CODEOWNERS` con los seis líderes y la coordinación, etiquetas, workflows de lint y de migraciones.
- [x] `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json` con atribución apagada y hook anti-rastro, reglas por área, seis skills compartidas.
- [x] Los seis `CONTEXTO.md` en formato común, con los originales de cada equipo respaldados.
- [x] `TAREAS.md` de las seis áreas: 126 tareas consolidadas.
- [x] `docs/FLUJO_APP.md`, `docs/CRONOGRAMA.md`, `docs/EMPIEZA_AQUI.md`.
- [x] Repo público.

Pendiente:

- [ ] Subir los 126 issues con etiquetas de área, tipo y nivel.
- [ ] Proteger `main` (lo hace el dueño del repo): PR obligatorio, 1 aprobación, revisión de dueños de código, sin bypass.
- [ ] Migración base (`a00`: enums compartidos, `usuarios`, tablas base) y seed compartido como archivos en `supabase/`.
- [ ] Inicializar la app React (Vite) con el layout, los componentes de la referencia y un módulo por área.
- [ ] Crear el proyecto de Supabase y repartir la URL y la llave `anon`.
- [ ] Crear el tablero de GitHub Projects.

Las fases 1 a 5 están desglosadas por día en la tabla 12.1.

### 12.3 Alcance mínimo por área para el jueves 17

Para que "se logra acabar" sea verdad, cada área entrega como mínimo esto. Lo que sobre es extra.

| Área | Mínimo entregable |
| --- | --- |
| 1 | Catálogo de proveedores y almacenes. Pantalla de registro de entrada con SKU, lote, flete e impuestos. Una orden de producción con BOM y su entrada a inventario. Vista `v_entradas_detalle`. |
| 2 | Catálogo de clientes. Alta de factura con renglones (el trigger del A3 valida stock). Reporte de facturado por cliente e IVA desglosado. |
| 3 | Todo lo que ya tiene en su documento: migraciones, 3 triggers, RLS, 6 vistas, 20 productos y 10 movimientos de seed. Conciliación con ajuste. |
| 4 | Catálogo de agentes con sueldo base y comisión. Cálculo de comisión por periodo a partir de facturas. Reporte de nómina del periodo. |
| 5 | Catálogo de instituciones y tipos de obligación. Alta de obligación con vencimiento y estados. Alertas por días de anticipación (vista o consulta, no correo). Registro de pago con comprobante. Cálculo de ISN e IVA de importación. |
| 6 | Catálogo de campañas con costo y tipo. Relación campaña-cliente. Reporte de costo por campaña y productos de baja rotación (desde `v_rotacion`). |

---

## 13. Riesgos y preguntas abiertas

| # | Riesgo / pregunta | Impacto | Mitigación / quién decide |
| --- | --- | --- | --- |
| R-01 | Los tres docs existentes se contradicen en stack y modelo | Alto | D-01, D-02, D-03 en fase 0 antes de cualquier código |
| R-02 | 24 personas haciendo fork por primera vez → PRs rotos, ramas mal sincronizadas | Alto | `CONTRIBUTING.md` con comandos exactos, `GUIA_GIT.md`, sesión de Git en fase 0, etiqueta `buena-primera-tarea` |
| R-03 | Código generado por IA que inventa tablas o tasas fiscales | Alto | Guía de agentes, sección 9.3 para líderes, revisión línea por línea, revisión del líder |
| R-04 | Área 3 declaró su esquema cerrado, Área 1 lo necesita ampliado | Alto | D-03: migración aditiva acordada entre líderes 1 y 3 el domingo 13 (I-01) |
| R-05 | "Pago automático" del Área 5 malinterpretado como integración bancaria | Medio | D-04 escrito en `DECISIONES.md` |
| R-06 | Carga desigual: unos hacen mucho, otros poco | Medio | Etiquetas `nivel:*`, matriz de habilidades, reasignación registrada por el líder |
| R-07 | Dos áreas editan la misma tabla compartida (`detalle_factura`, `productos`) | Medio | `CODEOWNERS` + regla "otras áreas consumen vistas, nunca tablas" |
| R-08 | Sólo 5 días de trabajo para los equipos | Alto | Preparación completa el sábado 12, alcance mínimo por área (12.3), congelamiento miércoles 16 18:00, PRs revisados en menos de 6 h, coordinación como revisora de respaldo |
| R-09 | Supabase RLS regresa vacío y parece que todo falló | Bajo | Ya documentado por Área 3; ponerlo en `GUIA_IA.md` y en el README como "primer diagnóstico" |
| R-10 | Alguien sube un commit con coautoría de IA y ya se mergeó | Medio | Squash merge permite editar el mensaje final; coordinador revisa `git log` el viernes 18 antes de entregar |
| R-11 | Calendario con nombres de día corridos y entrega un día tarde en la versión 2 del plan | Cerrado | Corregido el 12 de septiembre: entrega jueves 17, equipos del domingo 13 |
| P-01 | ¿El coordinador también lidera un área? | Cerrada | No. Sólo coordina. 6 equipos de 1 líder + 4 integrantes |
| P-02 | ¿Se usa GitHub Projects o basta con `ESTADO.md`? | — | Recomendación: ambos; Projects para el día a día, `ESTADO.md` como evidencia entregable |
| P-03 | ¿Hay entrega intermedia o sólo final? | — | Con 5 días, sólo final. Si el viernes 18 hay presentación, se agrega al calendario |
| P-04 | ¿Se requiere autenticación con roles reales? | Cerrada | Sí: Supabase Auth + tabla `usuarios` con `rol` (derivado de D-01) |
| P-05 | ¿`CLAUDE.md` / `.claude/` se suben al repo? | Cerrada | Sí, siguiendo el estándar de la sección 9.4, con skills compartidas |
| P-06 | Stack definitivo | Cerrada | React + API de Supabase + PostgreSQL en Supabase + pnpm. Ver D-01 |
| P-07 | `fecha_cobro` en `facturas` | — | Lo pide el Área 4 al Área 2 el día 1; sin eso las comisiones se calculan por mes de facturación |

---

## Anexo A — Cómo se relaciona cada documento actual con esta estructura

| Hoy | Después |
| --- | --- |
| `docs/area5-fiscal/CONTEXTO.md` | `docs/area5-fiscal/CONTEXTO.md` (se adapta al formato de 11 secciones; se cambia la sección 17 "Tecnologías" al stack acordado) |
| `docs/area3-inventario/CONTEXTO.md` | `docs/area3-inventario/CONTEXTO.md` (queda casi igual; se renumeran reglas a `RN-A3-xx`; se ajusta sección 12 "Convenciones" a la estructura global) |
| `docs/area1-entradas/CONTEXTO.md` | `docs/area1-entradas/CONTEXTO.md` (se reestructura a las 11 secciones; se corrige la numeración de necesidades a la oficial; se agrega el modelo ER que hoy no tiene) |
| `docs/area4-nomina/CONTEXTO.md` | `docs/area4-nomina/CONTEXTO.md` (ya está en el formato común; se mueve tal cual) |
| `README.md` (vacío) | README real con: descripción, áreas, cómo arrancar, enlaces a `CONTRIBUTING.md`, `PLAN.md` y `docs/` |

## Anexo B — Estado de los seis contextos

Los seis `CONTEXTO.md` están en el formato común de 17 secciones y los originales de cada equipo se conservan en `docs/areaN-*/originales/`. Las áreas 3, 4 y 6 entregaron documentos completos que se adaptaron a las decisiones globales; las áreas 1 y 5 entregaron requerimientos que se reestructuraron; el Área 2 entregó un documento alineado desde el inicio, con 25 issues que sirvieron de base a su `TAREAS.md`. Cada adaptación lleva una nota "Adaptado" con lo que proponía el equipo y por qué cambió.
