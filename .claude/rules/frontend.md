---
paths:
  - "src/**"
---

# Reglas del frontend

## Estructura y datos

- Un solo cliente Supabase: `src/lib/supabaseClient.js`. No crees otro.
- Los componentes React no llaman a `supabase.from()`. El acceso a datos va en `src/services/areaN/*.js`.
- Cada área trabaja solo en `src/services/areaN/` y `src/modules/areaN-*/`. `src/components/`, `src/lib/`, `src/index.css` y `App.jsx` son del coordinador.
- Nada de SQL crudo desde el frontend. Consultas con `supabase-js`; reportes desde vistas `v_*`.
- Solo JavaScript: archivos `.js` y `.jsx`. Nunca crees `.ts` ni `.tsx`; si copias código de la referencia o de Figma Make, quita las anotaciones de tipos.
- Funciones en español y descriptivas: `registrarEntrada`, `obtenerKardex`, `calcularISN`. Componentes en `PascalCase`, archivo `NombreComponente.jsx`.
- Validación de formularios con Zod antes de mandar a Supabase; la validación de negocio real vive en la base.
- Prettier y oxlint del repo; corre `pnpm lint` antes de proponer un PR.
- Instala con `pnpm add`, nunca con `npm`. Justifica toda dependencia nueva en el PR.
- Si una consulta regresa vacío teniendo datos, revisa RLS antes que cualquier otra cosa.

## Estilo visual (obligatorio; detalle en `docs/GUIA_ESTILO.md`)

- Antes de escribir cualquier pantalla, lee `docs/GUIA_ESTILO.md` y abre `docs/referencia-ui/App.jsx` para copiar el patrón del módulo equivalente.
- Usa **solo** los tokens definidos en `src/index.css` (`bg`, `surface`, `surface-2`, `border`, `muted`, `text`, `text-dim`, `accent`, `accent-dim`, `up`, `down`). Ningún color en hex ni `rgb()` dentro de un módulo de área.
- Usa **solo** los componentes de `src/components/`: `KpiCard`, `Panel`, `Table`, `Mono`, `Tag`, `StatusBadge`, formularios base e iconos del repo. No construyas tarjetas, tablas ni etiquetas a mano. Si falta un componente, dilo y propón un issue `area:transversal`; no lo improvises.
- Fuentes: `DM Sans` para texto y `JetBrains Mono` para folios, montos, cantidades y etiquetas. Montos siempre con `Mono`.
- Tema oscuro únicamente. No agregues modo claro ni colores de marca.
- Sin librerías de componentes, iconos ni gráficas (`MUI`, `shadcn`, `lucide`, `react-icons`, `recharts`, `chart.js`). La gráfica de barras del repo se hace con divs como en la referencia.
- Estilos con clases de Tailwind sobre los tokens (`bg-surface`, `border-border`, `text-text-dim`). Estilos en línea solo dentro de `src/components/`.
- Estructura fija de cada pantalla de área: fila de `KpiCard`, uno o más `Panel` con `Table`, botones de la topbar. El menú lateral no se modifica desde un módulo.
- Semántica de color: `up` = positivo/pagado/disponible; `down` = vencido/agotado/pendiente de pago; `accent` = en curso/bajo stock/destacado; `muted` = neutro. No cambies estos significados.
- Texto de interfaz en español.
