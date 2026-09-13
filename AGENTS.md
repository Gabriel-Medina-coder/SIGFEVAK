# Reglas para agentes de IA en SIGFEVAK

Este archivo lo leen Claude Code (vía `CLAUDE.md`), Cursor, Codex, Copilot y cualquier otra herramienta. Aplica a todo el repositorio.

## Qué es este proyecto

Sistema de gestión para una comercializadora mexicana de productos electrónicos y manufactura nacional. Seis áreas, cada una con su equipo y su carpeta. El plan completo está en `PLAN.md`; léelo si necesitas contexto general.

| Área | Carpeta de docs | Etiqueta | Prefijo de commit |
| --- | --- | --- | --- |
| 1 Entradas y manufactura | `docs/area1-entradas/` | `area:1-entradas` | `area1:` |
| 2 Contabilidad y facturación | `docs/area2-contabilidad/` | `area:2-contabilidad` | `area2:` |
| 3 Inventario (BD) | `docs/area3-inventario/` | `area:3-inventario` | `area3:` |
| 4 Nómina de agentes | `docs/area4-nomina/` | `area:4-nomina` | `area4:` |
| 5 Fiscal y permisos | `docs/area5-fiscal/` | `area:5-fiscal` | `area5:` |
| 6 Marketing | `docs/area6-marketing/` | `area:6-marketing` | `area6:` |

## Reglas (obligatorias)

1. **Antes de tocar cualquier cosa, lee `docs/areaN/CONTEXTO.md` del área del issue.** Ese archivo es la fuente de verdad. Si el código lo contradice, el código está mal.
2. **No inventes tablas, columnas, valores de enum, tasas ni topes legales.** Si falta algo, escríbelo en la sección "Preguntas abiertas" del `CONTEXTO.md` del área y detente.
3. **No toques archivos fuera de la carpeta del área del issue**: `docs/areaN/`, `src/services/areaN/`, `src/modules/areaN-*/`, `supabase/migrations/*_aN_*.sql`, `supabase/seed/seed_areaN.sql`, `supabase/tests/areaN/`. Si necesitas algo de otra área, dilo y no lo hagas.
4. **Nunca escribas `productos.stock` directamente** (RN-A3-06). Los triggers de la base lo modifican.
5. **Nunca edites una migración existente.** Crea una nueva con el formato `AAAAMMDD_HHMM_aN_descripcion.sql`.
6. **Cita la regla de negocio** (`RN-AN-xx`) en comentarios de código, mensajes de commit y descripciones de PR.
7. **Commits en español** con el formato `areaN: verbo objeto (RN-AN-xx) #issue`. Ejemplo: `area3: agrega trigger de conciliación (RN-A3-07) #42`.
8. **No agregues dependencias sin justificarlo en el PR.** Instala siempre con `pnpm`, nunca con `npm`.
9. **No leas ni subas `.env` ni llaves.** Solo existe `.env.example`.
10. **Stack fijo:** React + Vite, `supabase-js`, PostgreSQL en Supabase, pnpm. No propongas otro ni agregues un backend propio. La lógica de negocio va en funciones y triggers de PostgreSQL.
11. **Nunca agregues "Generated with", enlaces de sesión ni ninguna mención a herramientas de IA** en commits, PRs, issues, comentarios de código ni documentación. Las líneas `Co-Authored-By` solo se usan para **personas del equipo**, con el formato `Co-Authored-By: Nombre <usuario@users.noreply.github.com>`; nunca para una herramienta. El mensaje de commit es `areaN: verbo objeto #issue` más los coautores humanos si los hay.
12. **Las otras áreas consumen vistas, nunca tablas.** Si necesitas datos de otra área, busca la vista `v_*` en su `CONTEXTO.md` sección "Vistas y contratos".
13. **Validaciones críticas viven en la base** (CHECK, trigger), no solo en el frontend.
14. **Todo en español**: nombres de tablas, columnas, funciones de negocio, commits, issues y documentación. Las APIs de librerías quedan en inglés.
15. **Documenta todo.** Cada issue cierra con evidencia (captura, salida de consola o prueba SQL) guardada en `docs/areaN-*/evidencias/` y enlazada desde el PR. Cada acuerdo entre áreas queda escrito en su issue de integración. Cada decisión de diseño que tomes durante un issue la anotas en el `CONTEXTO.md` del área (sección de preguntas abiertas o reglas). Si algo no está escrito, no existe.
16. **Un solo estilo visual.** Toda pantalla sigue `docs/GUIA_ESTILO.md` y la referencia `docs/referencia-ui/App.jsx`: solo los tokens de `src/index.css`, solo los componentes de `src/components/`, tema oscuro, fuentes DM Sans y JetBrains Mono, sin librerías de componentes, iconos ni gráficas. Ningún color en hex dentro de un módulo de área.

## Mapa del repositorio

```text
PLAN.md                  plan global del proyecto
CONTRIBUTING.md          flujo de fork, rama, PR con comandos
docs/
  DECISIONES.md          decisiones de arquitectura (D-01 ... D-09)
  MODELO_DATOS.md        todas las tablas y quién es dueño de cada una
  GLOSARIO.md            términos de negocio
  GUIA_IA.md             cómo trabajar con agentes
  GUIA_GIT.md            fork, sync, ramas
  GUIA_ESTILO.md         tokens, componentes y reglas visuales
  EMPIEZA_AQUI.md        guía de arranque para líderes e integrantes
  CRONOGRAMA.md          fechas, hitos y alcance mínimo por área
  FLUJO_APP.md           flujo de negocio de punta a punta, roles por pantalla, tablero de control
  plantillas/            plantillas de ESTADO, TAREAS, EVALUACION, reporte final
  areaN-*/
    CONTEXTO.md          fuente de verdad del área
    ESTADO.md            bitácora viva
    TAREAS.md            desglose de issues
    EVALUACION.md        matriz de habilidades (líder)
    evidencias/          capturas y pruebas por issue
    originales/          documento original del equipo, sin editar
supabase/
  migrations/            AAAAMMDD_HHMM_aN_descripcion.sql
  seed/                  seed_areaN.sql
  tests/areaN/           pruebas SQL de triggers y funciones
src/
  lib/supabaseClient.js  único cliente; nadie crea otro
  services/areaN/        acceso a datos por área
  modules/areaN-*/       pantallas React por área
  components/            componentes compartidos (coordinador)
```

## Convenciones de código

- Base de datos: `minusculas_con_guion_bajo`, tablas en plural, llaves en singular (`id_producto`). Enums como tipos PostgreSQL. Cada función y trigger lleva comentario con la RN que implementa. RLS activado en toda tabla.
- JavaScript en todo el repo (`.js` y `.jsx`; nunca `.ts` ni `.tsx`). Prettier + ESLint del repo. Un solo cliente Supabase en `src/lib/supabaseClient.js`. Los componentes React no llaman a `supabase.from()`; eso va en `src/services/areaN/`. Funciones en español: `registrarEntrada`, `obtenerKardex`, `calcularISN`. Componentes en `PascalCase`.
- Nada de SQL crudo desde el frontend; consultas con `supabase-js` y vistas para reportes.

## Comandos

```text
pnpm install            instalar dependencias (nunca npm install)
pnpm dev                levantar el frontend
pnpm lint               prettier + eslint
supabase db push        aplicar migraciones al proyecto
supabase db reset       recrear la base local desde cero con migraciones y seed
```

## Dónde suele fallar la IA en este proyecto

- Cálculos fiscales del área 5 (ISR, IVA, IGI, DTA, ISN): inventa tasas. Léelas del `CONTEXTO.md` o de `parametros_legales`.
- Triggers de stock del área 3: actualiza `stock` a mano y duplica el incremento.
- RLS de Supabase: olvida las políticas y todo regresa vacío. Si una consulta regresa cero filas teniendo datos, el diagnóstico es RLS.
- Cualquier cosa que cruce dos áreas: pregunta antes.
