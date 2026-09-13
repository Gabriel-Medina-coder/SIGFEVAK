# src

Base inicializada con la plantilla oficial de Vite (`pnpm create vite --template react`), Tailwind CSS v4 y los tokens de `docs/GUIA_ESTILO.md` en `index.css`. Estructura objetivo:

```text
lib/supabaseClient.js     único cliente Supabase (coordinación)
components/               componentes compartidos (coordinación)
services/areaN/           acceso a datos por área
modules/areaN-<slug>/     pantallas por área
App.jsx                   menú principal, una ruta por área
```

Comandos: `pnpm dev`, `pnpm lint`, `pnpm build`. Nunca `npm`.
