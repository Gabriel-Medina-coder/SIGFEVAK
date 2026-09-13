# Publicar la app (deploy)

SIGFEVAK es un frontend estático que habla con Supabase (ya en la nube). Se publica como sitio estático; no hace falta servidor propio. La opción recomendada es Vercel (gratis, HTTPS automático). El repositorio ya trae `vercel.json` con la rerouteo del SPA y las cabeceras de seguridad.

## Antes de empezar

- El repositorio en GitHub al día (`git push`).
- Tener a la mano las dos variables del proyecto Supabase:
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY` (la llave `anon`, que es pública por diseño; RLS protege los datos)
- Estas dos las copias del `.env` local o del panel de Supabase (Project Settings, API).

> Nunca pongas en el hosting el token de administración (`.env.supabase`): ese no va a producción, no es de la app.

## Pasos en Vercel

1. Entra a vercel.com y crea una cuenta con tu GitHub.
2. "Add New… > Project" y elige el repositorio `SIGFEVAK`.
3. Vercel detecta Vite. Deja el comando de build en `pnpm build` y la carpeta de salida en `dist` (ya vienen en `vercel.json`).
4. En "Environment Variables" agrega las dos: `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`. Van en los tres entornos (Production, Preview, Development).
5. "Deploy". En un par de minutos te da una URL pública con HTTPS.

Cada `git push` a `main` vuelve a publicar solo.

## Comprobar que quedó bien

- Abre la URL: debe cargar la landing con la tipografía correcta (si se ve sin fuentes, revisa que la CSP permita `fonts.googleapis.com`, que ya está en `vercel.json`).
- Entra con una cuenta y recorre un par de módulos.
- Recarga estando en `/app/nomina`: debe seguir en esa pantalla (el reruteo del SPA lo maneja `vercel.json`).
- En las herramientas del navegador (pestaña Network, respuesta del documento) verifica las cabeceras: `Content-Security-Policy`, `X-Frame-Options`, `Strict-Transport-Security`.

## Alternativa: Netlify

Funciona igual. Comando `pnpm build`, carpeta `dist`, las mismas dos variables, y un archivo `_redirects` con `/*  /index.html  200` para el SPA (o usa la reescritura equivalente). Las cabeceras se ponen en un archivo `netlify.toml` o en el panel.

## Nota sobre las cuentas de demostración

Las seis cuentas por rol viven en Supabase Auth. La app publicada usa la misma base, así que las contraseñas de demostración funcionan igual. Para una demo con datos limpios, la coordinación puede reconstruir la base antes de presentar.
