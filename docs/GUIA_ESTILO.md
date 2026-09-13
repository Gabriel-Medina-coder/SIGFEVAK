# Guía de estilo visual

Un solo estilo para las seis áreas. La referencia es el dashboard exportado de Figma Make que está en `docs/referencia-ui/` (`App.jsx` e `index.css`). Esta guía extrae de ahí los tokens, los componentes y las reglas. **Nadie inventa colores, fuentes ni componentes nuevos**; si algo falta, se pide al coordinador y se agrega aquí y en `src/components/`.

## 1. Tokens (variables CSS)

Viven en `src/index.css` dentro de `@theme` de Tailwind v4. Se usan como `var(--color-x)` o como clase de Tailwind (`bg-surface`, `text-accent`, `border-border`).

| Token | Valor | Uso |
| --- | --- | --- |
| `--color-bg` | `#0d0d0d` | Fondo de la página y de la barra superior |
| `--color-surface` | `#161616` | Fondo de sidebar, tarjetas y paneles |
| `--color-surface-2` | `#1e1e1e` | Hover de filas y botones, barras de gráfica inactivas |
| `--color-border` | `#2a2a2a` | Todos los bordes, 1px |
| `--color-muted` | `#555555` | Encabezados de tabla, etiquetas de sección, texto terciario |
| `--color-text` | `#e8e8e8` | Texto principal |
| `--color-text-dim` | `#888888` | Texto secundario, subtítulos |
| `--color-accent` | `#f0a500` | Ámbar. Selección activa, botón primario, alertas medias, valores destacados |
| `--color-accent-dim` | `rgba(240,165,0,0.12)` | Fondo del ítem activo del menú y de la etiqueta ámbar |
| `--color-up` | `#3ecf8e` | Verde. Positivo, pagado, disponible, entradas |
| `--color-down` | `#f87171` | Rojo. Negativo, vencido, agotado, pendiente de pago |
| `--font-sans` | `'DM Sans', sans-serif` | Todo el texto |
| `--font-mono` | `'JetBrains Mono', monospace` | Folios, montos, cantidades, fechas cortas, etiquetas |

Tema: **oscuro únicamente**. No hay modo claro y no se agrega.

Tamaño base: `html { font-size: 14px }`. Escala de texto usada en la referencia:

| Uso | Tamaño | Peso | Extra |
| --- | --- | --- | --- |
| Título de página (topbar) | 15px | 600 | `letter-spacing: -0.02em` |
| Título de panel | 13px | 500 | |
| Texto de celda principal | 13px | 500 | |
| Texto secundario en celda | 12px | 400 | color `text-dim` |
| Valor KPI | 22px mono | 600 | `letter-spacing: -0.03em` |
| Etiqueta KPI, encabezado de tabla | 10 a 10.5px | 500 | mayúsculas, `letter-spacing` 0.04 a 0.06em, color `muted` o `text-dim` |
| Etiqueta (tag) | 10.5px mono | 400 | píldora, `border-radius: 20px` |
| Botón | 12px | 400 secundario / 600 primario | |
| Menú lateral | 13px | 400, 500 activo | |

Radios: tarjetas y paneles 12px; botones, ítems de menú y logo 7px; barras de gráfica 4px arriba. Espaciados: padding de tarjeta 18/20px; de panel 18/22px cabecera y 20/22px cuerpo; celdas de tabla 13/20px; separación entre tarjetas 14px; entre bloques 24px; margen del contenido 28px.

## 2. Estructura de pantalla

```text
┌─ sidebar 240px ─┬─ main ───────────────────────────────────┐
│ logo SFV        │ topbar: título del módulo + subtítulo     │
│ SIGFEVAK        │        botones [Exportar] [+ Nuevo]       │
│ ───────────     ├───────────────────────────────────────────┤
│ MÓDULOS         │ fila de KpiCard (3 o 4 columnas)          │
│ ▸ Resumen       │                                           │
│   Entradas      │ Panel con Table                           │
│   Contable      │                                           │
│   Inventario    │ (opcional) grid 1fr 300px: Panel + Panel  │
│   Nómina        │                                           │
│   Regulación    │                                           │
│   Marketing     │                                           │
│ ───────────     │                                           │
│ avatar usuario  │                                           │
└─────────────────┴───────────────────────────────────────────┘
```

- Sidebar fija, fondo `surface`, borde derecho. En menos de 960px se oculta y se abre con el botón de menú, con overlay oscuro.
- Topbar pegajosa (`sticky`), fondo `bg`, borde inferior.
- Contenido con `padding: 28px` y `gap: 24px` entre bloques.
- Grid de KPI: 4 columnas; 2 en menos de 960px; 1 en menos de 600px. Con 3 KPI: 3 columnas y 1 en móvil.
- El menú lateral tiene exactamente los 7 ítems de la referencia, en ese orden, con esos iconos. Cada área es dueña de la pantalla de su ítem; "Resumen General" es del coordinador.

## 3. Componentes compartidos

Viven en `src/components/` (propiedad del coordinador) y son los únicos bloques visuales permitidos. Las áreas los **componen**, no los copian ni los modifican.

| Componente | Props | Para qué |
| --- | --- | --- |
| `KpiCard` | `label`, `value`, `delta`, `up`, `sub?` | Tarjeta de indicador. `value` en mono 22px; `delta` verde si `up`, rojo si no |
| `Panel` | `title`, `acciones?`, `children` | Contenedor con cabecera y borde; envuelve tablas, gráficas y listas |
| `Table` | `headers[]`, `rows[][]`, `vacio?`, `onRowClick?` | Tabla con encabezados en mayúsculas, hover de fila, scroll horizontal, `min-width: 600` |
| `Mono` | `children`, `color?: text \| up \| down \| accent \| dim \| muted`, `bold?` | Texto monoespaciado 12px para folios, montos y cantidades |
| `Tag` | `children`, `color: accent \| muted \| up \| down` | Píldora de categoría |
| `StatusBadge` | `status`, `map`, `etiquetas?` | `Tag` cuyo color sale de un mapa `{ estado: color }` |
| `Sidebar`, `Topbar`, `Layout` | — | Estructura de la sección 2; una sola instancia en `App.jsx` |
| Iconos | `size?` | SVG de 16x16 con `stroke="currentColor"` y `strokeWidth 1.3`. Solo los de la referencia más los que el coordinador agregue |
| `GraficaBarras` | `data[{label, value, titulo?}]`, `alto?` | Barras con la última en `accent` y las demás en `surface-2` con borde. Sin librería de gráficas |
| `Pestanas` | `opciones[{id, etiqueta}]`, `activa`, `onCambiar` | Divide una pantalla de área en secciones: catálogo, reportes, catálogos |
| `Modal` | `abierto`, `titulo`, `onCerrar`, `ancho?` | Alta, edición y detalle con el mismo fondo y borde que `Panel`; cierra con Escape o clic fuera |
| `FilaKpi`, `RejillaForm`, `Acciones`, `Texto` | `columnas`, `dim?`, `bold?` | Rejilla de KPI de 3 o 4 columnas, rejilla de formulario de 1 a 3, botonera alineada a la derecha y texto de celda |
| `Campo`, `Entrada`, `AreaTexto`, `Selector`, `Boton`, `Mensaje`, `Cargando` | ver `Formulario.jsx` | Formularios de la sección 4. `Boton` con variante primario, secundario o peligro; `Mensaje` con tipo error, ok o info |
| `mensajeDeError(error)` | — | Convierte un error de Postgres con `RN-AN-xx` en texto legible en español |
| `useTopbar()` | `set({ acciones, subtitulo })` | Cada pantalla pone sus botones en la topbar y los quita al salir |

Todo se importa desde un solo lugar: `import { KpiCard, Panel, Table } from '@/components'`.

Si un área necesita un componente que no existe (un formulario, un modal, un selector de fecha), abre un issue `area:transversal` `tipo:frontend` y el coordinador lo agrega a `src/components/` siguiendo estos tokens. Mientras tanto no se improvisa uno local.

## 4. Formularios (no están en la referencia; se definen aquí)

La referencia solo muestra lectura. Para alta y edición se usa el mismo lenguaje:

- Campos con fondo `surface`, borde `border` de 1px, radio 7px, padding 8/12px, texto 13px, placeholder en `muted`. En foco el borde pasa a `accent`.
- Etiqueta de campo arriba, 10.5px mayúsculas `text-dim`, igual que la etiqueta de KPI.
- Botón primario ámbar con texto negro 600; secundario fondo `surface` con borde y texto `text-dim`.
- Errores de validación en 11px color `down` debajo del campo.
- Los formularios van dentro de un `Panel` o en un modal con el mismo fondo y borde; nunca en una página en blanco.

## 5. Semántica de colores (para que todas las áreas signifiquen lo mismo)

| Significado | Color | Ejemplos |
| --- | --- | --- |
| Positivo, completo, disponible | `up` | pagada, disponible, al corriente, activa, entradas, delta positivo |
| Negativo, urgente, faltante | `down` | vencida, agotado, pendiente de pago, cartera vencida, delta negativo, importación (en origen) |
| Atención, en curso, destacado | `accent` | pendiente de cobro, bajo stock, bono, ítem activo, categoría electrónico |
| Neutro, informativo | `muted` | finalizada, manufactura, tipo de obligación |

Un estado nunca cambia de color entre áreas: "pendiente" de cobro es `accent`, "pendiente" de pago de impuesto es `down`, como en la referencia.

## 6. Reglas para devs y agentes

1. Solo tokens de la sección 1. Ningún color en hex escrito en un módulo de área.
2. Solo componentes de la sección 3. Ningún `div` con borde y fondo hecho a mano en un módulo de área.
3. Solo fuentes `DM Sans` y `JetBrains Mono`. Montos, folios y cantidades siempre en `Mono`.
4. Tema oscuro. No se agregan variantes claras ni colores de marca de otra área.
5. Sin librerías de componentes ni de iconos (`MUI`, `shadcn`, `lucide`, `react-icons`). Sin librerías de gráficas.
6. Estilos con clases de Tailwind sobre los tokens (`bg-surface`, `border-border`, `text-text-dim`). Estilos en línea solo dentro de `src/components/`, nunca en módulos de área.
7. Texto de interfaz en español, mayúsculas solo en etiquetas pequeñas como en la referencia.
8. Cada pantalla de área tiene: fila de KPI, uno o más `Panel` con `Table`, y los botones de la topbar. Nada más hasta que el coordinador amplíe esta guía.
9. Cuando dudes, abre `docs/referencia-ui/App.jsx` y copia el patrón que ya existe para tu módulo (hay uno por área).

## 7. Cómo quedó en el proyecto

- `src/index.css` tiene los tokens de la referencia tal cual.
- `src/components/` tiene los componentes de la sección 3, uno por archivo, exportados desde `index.js`.
- `src/App.jsx` define las rutas: `/` página de inicio, `/login`, y `/app` con el layout y los siete módulos, que cargan bajo demanda.
- `src/lib/permisos.js` define los módulos del menú y qué rol escribe en cada uno. Las pantallas ocultan los botones con `puedeEscribir(rol, modulo)`; la base valida de todos modos.
- Cada `src/modules/areaN-*/` ya está conectado a Supabase por sus servicios en `src/services/areaN/`.

Todo el proyecto es JavaScript (D-01). Si se vuelve a exportar algo desde Figma Make, se quitan las anotaciones de tipos antes de copiarlo. Nada de archivos `.ts` ni `.tsx` en el repo.
