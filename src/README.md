# src

App de React con Vite, Tailwind CSS v4 y los tokens de `docs/GUIA_ESTILO.md` en `index.css`.

```text
main.jsx                  arranque: router y proveedor de sesión
App.jsx                   rutas: /, /login y /app con los siete módulos
lib/supabaseClient.js     único cliente Supabase; lee .env de la raíz
lib/auth.jsx              sesión de Supabase Auth y fila de usuarios (nombre, rol, área)
lib/permisos.js           módulos del menú y qué rol escribe en cada uno
lib/formato.js            pesos, cantidades, fechas y periodos en es-MX
lib/useDatos.js           carga de datos con estado de carga, error y recarga
lib/consulta.js           ayudantes para las respuestas de supabase-js
lib/exportar.js           exportación a CSV
components/               componentes compartidos (coordinación)
paginas/                  landing, login, guardia de sesión, 404
services/coordinacion/    lecturas del resumen general
services/areaN/           acceso a datos por área; único lugar que llama a supabase
modules/resumen/          resumen general
modules/areaN-<slug>/     pantallas por área
```

Comandos: `pnpm dev`, `pnpm lint`, `pnpm build`. Nunca `npm`. Sin `.env` en la raíz la app no arranca.
