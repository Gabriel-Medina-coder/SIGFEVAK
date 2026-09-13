# Referencia de interfaz

Exportación del dashboard diseñado en Figma Make ("Crear dashboard minimalista"). Es la **única referencia visual** del proyecto; la guía derivada está en `docs/GUIA_ESTILO.md`.

| Archivo | Qué es |
| --- | --- |
| `index.css` | Tokens de color y tipografía en `@theme` de Tailwind v4, reset y scrollbar. Se copia tal cual a `src/index.css` |
| `App.jsx` | Layout completo (sidebar, topbar), una pantalla por área con datos de ejemplo, y los componentes `KpiCard`, `Panel`, `Table`, `Mono`, `Tag`, `StatusBadge` e iconos. Convertido de TypeScript a JavaScript (D-01); la lógica es idéntica a la exportación |
| `package.json` | Versiones que usó la exportación (React 19, Vite 8, Tailwind 4) como referencia |

No se edita. Los cambios de estilo se hacen en `src/` y se reflejan en `GUIA_ESTILO.md`.
