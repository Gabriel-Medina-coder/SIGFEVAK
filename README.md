<div align="center">

# SIGFEVAK

**Sistema de gestión para una comercializadora mexicana de productos electrónicos y manufactura nacional.**
Entradas, contabilidad, inventario, nómina de agentes, cumplimiento fiscal y marketing en una sola plataforma.

[![lint](https://github.com/Gabriel-Medina-coder/SIGFEVAK/actions/workflows/lint.yml/badge.svg)](https://github.com/Gabriel-Medina-coder/SIGFEVAK/actions/workflows/lint.yml)
[![sql-lint](https://github.com/Gabriel-Medina-coder/SIGFEVAK/actions/workflows/sql-lint.yml/badge.svg)](https://github.com/Gabriel-Medina-coder/SIGFEVAK/actions/workflows/sql-lint.yml)
![React](https://img.shields.io/badge/React-19-20232a?logo=react&logoColor=61dafb)
![Vite](https://img.shields.io/badge/Vite-8-646cff?logo=vite&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ecf8e?logo=supabase&logoColor=white)
![pnpm](https://img.shields.io/badge/pnpm-9-f69220?logo=pnpm&logoColor=white)
![Tailwind](https://img.shields.io/badge/Tailwind-4-06b6d4?logo=tailwindcss&logoColor=white)

[Plan del proyecto](PLAN.md) · [Cómo contribuir](CONTRIBUTING.md) · [Decisiones](docs/DECISIONES.md) · [Modelo de datos](docs/MODELO_DATOS.md) · [Guía de estilo](docs/GUIA_ESTILO.md)

</div>

---

## Índice

1. [Descripción](#descripción)
2. [Módulos](#módulos)
3. [Arquitectura](#arquitectura)
4. [Stack](#stack)
5. [Estructura del repositorio](#estructura-del-repositorio)
6. [Primeros pasos](#primeros-pasos)
7. [Flujo de trabajo](#flujo-de-trabajo)
8. [Convenciones](#convenciones)
9. [Documentación](#documentación)
10. [Equipo](#equipo)
11. [Solución de problemas](#solución-de-problemas)

---

## Descripción

SIGFEVAK centraliza la operación administrativa de una comercializadora con presencia nacional: qué mercancía entra y cuánto capital representa, qué se factura y a quién, cuánto inventario hay, cuánto se paga a los agentes de ventas, qué obligaciones fiscales y aduanales vencen, y qué rinde el marketing.

El sistema se construye en **seis módulos independientes** que comparten una sola base de datos. Cada módulo lo desarrolla un equipo de cinco personas con un líder; el trabajo se coordina desde este repositorio mediante issues etiquetados por área, pull requests desde forks y revisión obligatoria del líder.

## Módulos

| # | Módulo | Qué resuelve | Documento |
| --- | --- | --- | --- |
| 1 | **Entradas y manufactura** | Registro de entradas de productos electrónicos y de manufactura nacional: proveedores, lotes, almacenes, órdenes de producción, capital de inversión y volumen | [`docs/area1-entradas/`](docs/area1-entradas/CONTEXTO.md) |
| 2 | **Contabilidad y facturación** | Clientes comercializadores, facturas con IVA desglosado, estado de pago y cartera | [`docs/area2-contabilidad/`](docs/area2-contabilidad/CONTEXTO.md) |
| 3 | **Inventario** | Catálogo de productos, kardex de entradas y salidas, conciliación física, rotación. Los triggers de stock viven aquí | [`docs/area3-inventario/`](docs/area3-inventario/CONTEXTO.md) |
| 4 | **Nómina de agentes** | Sueldo base, comisiones escalonadas sobre ventas cobradas, bonos, ISR, IMSS e ISN, periodos con autorización | [`docs/area4-nomina/`](docs/area4-nomina/CONTEXTO.md) |
| 5 | **Fiscal y permisos** | Obligaciones ante SAT, aduanas, estado y municipio; alertas de vencimiento, líneas de captura, autorización y comprobantes de pago | [`docs/area5-fiscal/`](docs/area5-fiscal/CONTEXTO.md) |
| 6 | **Marketing** | Campañas externas y directas, costo, alcance, conversiones y relación con clientes | [`docs/area6-marketing/`](docs/area6-marketing/CONTEXTO.md) |

Cada módulo tiene una pantalla en el menú lateral de la aplicación, más un resumen general a cargo de la coordinación.

## Arquitectura

```text
┌──────────────────────────────────────────────────────────────┐
│  Frontend · React + Vite · un módulo por área                │
│  src/modules/areaN-*  →  src/services/areaN  →  supabase-js  │
└──────────────────────────────┬───────────────────────────────┘
                               │  API de Supabase (PostgREST + Auth)
┌──────────────────────────────▼───────────────────────────────┐
│  PostgreSQL en Supabase · una sola base para las 6 áreas      │
│  · Tablas con dueño por área      · Funciones y triggers      │
│  · Vistas de contrato v_*         · RLS en todas las tablas   │
└──────────────────────────────────────────────────────────────┘
```

Principios:

- **No hay backend propio.** El frontend habla con la API de Supabase y la lógica de negocio crítica (stock, comisiones, obligaciones) vive en funciones y triggers de PostgreSQL, donde nadie puede saltársela.
- **Fronteras lógicas, no físicas.** Cualquier área lee todo; cada área escribe solo en sus tablas. Las demás consumen **vistas**, nunca tablas. Quién es dueño de qué está en [`docs/MODELO_DATOS.md`](docs/MODELO_DATOS.md).
- **Cambios de esquema siempre aditivos.** Una migración nunca se edita; un cambio es una migración nueva.

## Stack

| Capa | Tecnología |
| --- | --- |
| Frontend | React 19 · Vite · JavaScript (`.js` / `.jsx`) · Tailwind CSS 4 · react-router · Zod |
| Backend | API de Supabase (PostgREST, Auth). Sin servidor propio |
| Base de datos | PostgreSQL alojado en Supabase, un solo proyecto |
| Acceso a datos | `supabase-js` |
| Migraciones | Archivos SQL aplicados con `node supabase/sql.mjs migrate` (sin CLI, D-10) |
| Autenticación | Supabase Auth con roles en tabla `usuarios` |
| Paquetes | **pnpm** (npm bloqueado por `.npmrc`) |
| Calidad | Prettier · oxlint · GitHub Actions (lint, validación de migraciones) |
| Diseño | Tema oscuro definido en [`docs/GUIA_ESTILO.md`](docs/GUIA_ESTILO.md), derivado de la referencia en `docs/referencia-ui/` |

El detalle y el porqué de cada elección están en [`docs/DECISIONES.md`](docs/DECISIONES.md).

## Estructura del repositorio

```text
SIGFEVAK/
├── PLAN.md                  Plan completo del proyecto
├── CONTRIBUTING.md          Fork → issue → rama → PR, con comandos
├── AGENTS.md / CLAUDE.md    Reglas para herramientas de IA
├── .claude/                 Configuración, reglas por área y skills compartidas
├── .githooks/               Hook de commit-msg (formato y limpieza del historial)
├── .github/                 Plantillas de issue y PR, CODEOWNERS, etiquetas, workflows
├── docs/
│   ├── DECISIONES.md        Decisiones de arquitectura (ADR)
│   ├── MODELO_DATOS.md      Todas las tablas, vistas y enums, con su dueño
│   ├── GUIA_ESTILO.md       Tokens, componentes y reglas visuales
│   ├── GUIA_GIT.md          Git para el proyecto
│   ├── GUIA_IA.md           Cómo usar IA sin romper el proyecto
│   ├── GLOSARIO.md          Términos de negocio
│   ├── EQUIPOS.md           Quién está en qué área
│   ├── EMPIEZA_AQUI.md      Guía de arranque para líderes e integrantes
│   ├── CRONOGRAMA.md        Fechas, hitos y alcance mínimo por área
│   ├── FLUJO_APP.md         La app de punta a punta y el tablero de control
│   ├── HISTORIA_FLUJO.md    El flujo contado como historia, con capturas de la app real
│   ├── evidencias/          Capturas generales de la historia
│   ├── plantillas/          Plantillas de CONTEXTO, ESTADO, TAREAS, EVALUACION y reporte
│   ├── referencia-ui/       Dashboard de referencia (App.jsx, index.css)
│   └── areaN-*/             CONTEXTO · ESTADO · TAREAS · EVALUACION · evidencias · originales
├── supabase/
│   ├── migrations/          AAAAMMDD_HHMM_aN_descripcion.sql
│   ├── seed/                seed_areaN.sql y seed_historico.sql (dos años de operación)
│   └── tests/               Pruebas SQL de triggers y funciones por área
└── src/
    ├── lib/                 Cliente Supabase único
    ├── components/          Componentes compartidos (KpiCard, Panel, Table, …)
    ├── services/areaN/      Acceso a datos por área
    └── modules/areaN-*/     Pantallas por área
```

## Primeros pasos

Requisitos: Node 20 o superior, pnpm y Git. No se necesita Supabase CLI ni Docker: la base ya vive en el proyecto de Supabase de la coordinación.

```text
# 1. Fork en GitHub, luego:
git clone https://github.com/<tu-usuario>/SIGFEVAK.git
cd SIGFEVAK
git remote add upstream https://github.com/Gabriel-Medina-coder/SIGFEVAK.git
git config core.hooksPath .githooks

# 2. Dependencias (nunca npm)
pnpm install

# 3. Variables de entorno: el archivo .env va en la raíz, junto a package.json
cp .env.example .env        # ya trae la URL y la llave pública del proyecto

# 4. Levantar la app
pnpm dev                    # abre http://localhost:5173
```

## Entrar a la app

1. Con `pnpm dev` corriendo, abre `http://localhost:5173`. Aparece la página de inicio.
2. Da clic en **Entrar** y escribe correo y contraseña.
3. Entras al **Resumen General**. El menú lateral tiene los siete módulos; todos se ven, pero solo puedes capturar en los de tu rol.
4. Para salir, usa el ícono junto a tu nombre al pie del menú.

Cuentas de prueba, una por rol. Las contraseñas las da la coordinación y nunca se escriben en el repo.

| Correo | Rol | Captura en |
| --- | --- | --- |
| `admin@sigfevak.mx` | ADMINISTRADOR | Todos los módulos y catálogos |
| `almacen@sigfevak.mx` | ALMACEN | Entradas de Producción, Base de Productos |
| `contador@sigfevak.mx` | CONTADOR | Registro Contable, Regulación y Pagos; calcula la nómina |
| `gerente@sigfevak.mx` | GERENTE_VENTAS | Nómina: revisa y rechaza periodos |
| `autorizador@sigfevak.mx` | AUTORIZADOR | Nómina y Regulación: autoriza, paga y concilia |
| `marketing@sigfevak.mx` | MARKETING | Marketing |

Para ver un recorrido completo antes de entrar, lee [`docs/HISTORIA_FLUJO.md`](docs/HISTORIA_FLUJO.md): una semana de la empresa en 15 capítulos con capturas.

Para probar la separación de funciones usa dos cuentas: una calcula o registra y otra autoriza. La base rechaza que la misma persona haga ambas cosas.

Sin sesión no se ve ningún dato: la base rechaza toda lectura anónima. Una cuenta nueva la crea la coordinación en Supabase Auth y le asigna el rol en la tabla `usuarios`.

Si usas Claude Code, al abrir el repo se cargan automáticamente las reglas y las skills del proyecto. Para otras herramientas, apunta a [`AGENTS.md`](AGENTS.md).

## Flujo de trabajo

La coordinación construye las seis áreas por bloques, con el líder de cada área como coautor de los commits de su área. Cada bloque va en una rama, un commit con `Closes #nn`, merge a `main` y push. Los líderes e integrantes contribuyen por pull request cuando quieran. Detalle en [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Convenciones

| Ámbito | Regla |
| --- | --- |
| Idioma | Español en código de negocio, commits, issues y documentación |
| Commits | `areaN: verbo objeto (RN-AN-xx) #issue`. Prefijos válidos: `area1`…`area6`, `docs`, `coord`, `fix`, `ci`, `chore` |
| Historial | Sin menciones a herramientas de IA en commits, PRs, issues ni código. Un hook lo verifica |
| Base de datos | `snake_case` en español, tablas en plural, llaves en singular. Enums como tipos. Toda función y trigger cita su regla `RN-AN-xx`. RLS en toda tabla |
| Migraciones | `AAAAMMDD_HHMM_aN_descripcion.sql`, con encabezado. Nunca se edita una aplicada |
| Frontend | Solo `.js`/`.jsx`. Un solo cliente Supabase. Los componentes no consultan la base; eso va en `services/`. Solo tokens y componentes de la guía de estilo |
| Reglas de negocio | Numeradas por área (`RN-A3-06`) y citadas en código, commits y PR |

## Documentación

| Documento | Para quién | Qué contiene |
| --- | --- | --- |
| [`PLAN.md`](PLAN.md) | Todos | Organización, decisiones, estructura, cronograma, riesgos |
| [`docs/DECISIONES.md`](docs/DECISIONES.md) | Todos | Registro de decisiones de arquitectura |
| [`docs/MODELO_DATOS.md`](docs/MODELO_DATOS.md) | Devs de BD | Dueño de cada tabla, vistas de contrato, enums, integraciones pendientes |
| [`docs/areaN-*/CONTEXTO.md`](docs/) | Cada equipo | Fuente de verdad del área: alcance, modelo, reglas, DDL, vistas |
| [`docs/GUIA_ESTILO.md`](docs/GUIA_ESTILO.md) | Frontend | Paleta, tipografía, componentes, semántica de color |
| [`docs/GUIA_GIT.md`](docs/GUIA_GIT.md) | Todos | Fork, sync, ramas, rebase, problemas comunes |
| [`docs/GUIA_IA.md`](docs/GUIA_IA.md) | Todos | Configuración, prompt base, skills, qué revisar |
| [`docs/GLOSARIO.md`](docs/GLOSARIO.md) | Todos | Términos de negocio compartidos |
| [`docs/EMPIEZA_AQUI.md`](docs/EMPIEZA_AQUI.md) | Todos | Guía de arranque: qué hacer el primer día y dónde está cada cosa |
| [`docs/CRONOGRAMA.md`](docs/CRONOGRAMA.md) | Todos | Fechas, hitos y alcance mínimo por área |
| [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md) | Coordinación | Auditoría OWASP, huecos cerrados y controles |
| [`docs/QA.md`](docs/QA.md) | Todos | Niveles de prueba, criterios de aceptación y métricas |
| [`docs/FLUJO_APP.md`](docs/FLUJO_APP.md) | Todos | La app de punta a punta: pantallas, roles, flujo de negocio en 14 pasos y tablero de control |
| [`docs/HISTORIA_FLUJO.md`](docs/HISTORIA_FLUJO.md) | Todos | El mismo flujo grabado en la app real: 15 capítulos con capturas y cifras de la base |

## Equipo

31 personas: coordinación general, seis líderes de área y veinticuatro integrantes. Los líderes tienen permiso de escritura y revisan los PRs de su área; los integrantes trabajan desde forks. La lista completa está en [`docs/EQUIPOS.md`](docs/EQUIPOS.md).

Cada líder evalúa a su equipo con una matriz ponderada, puede reasignar tareas y entrega un reporte final. Las plantillas están en [`docs/plantillas/`](docs/plantillas/).

## Solución de problemas

| Síntoma | Causa probable | Qué hacer |
| --- | --- | --- |
| Una consulta regresa vacío aunque hay datos | RLS sin política | Verifica que la tabla tenga política para `authenticated` |
| El stock se duplicó | Alguien actualizó `productos.stock` a mano | Solo los triggers lo modifican (RN-A3-06) |
| `pnpm install` falla por `engine-strict` | Usaste npm | Instala pnpm y borra `package-lock.json` |
| La app no carga y la consola dice "Faltan VITE_SUPABASE_URL" | No existe `.env` en la raíz | Copia `.env.example` a `.env` y reinicia `pnpm dev` |
| "Correo o contraseña incorrectos" | Contraseña distinta o cuenta sin crear | Pide a la coordinación que la restablezca en Supabase Auth |
| Una pantalla dice "Tu sesión no tiene permiso para esta operación" | El rol no escribe en ese módulo | Entra con la cuenta del rol correcto |
| No aparece el botón de autorizar | Tú calculaste o registraste ese registro | Autoriza con otra cuenta (RN-A4-15, RN-A5-18) |
| El commit fue rechazado por el hook | Mensaje con rastro de IA o prefijo inválido | Reescribe: `areaN: verbo objeto #issue` |
| Una migración falla al aplicar | Nombre fuera de formato u orden alfabético incorrecto | Revisa `supabase/migrations/README.md` |
| Una vista nueva se lee sin sesión | Se creó sin `security_invoker` | Recréala con `WITH (security_invoker = true)` y corre `supabase/tests/coord/seguridad.sql` |

---

<div align="center">
<sub>Proyecto académico · Septiembre 2026 · Todo el contenido en español</sub>
</div>
