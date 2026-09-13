# Cómo se trabaja en este repositorio

## Modo de construcción

La coordinación construye las seis áreas con el respaldo de cada líder, que aparece como coautor en los commits de su área. Los líderes e integrantes pueden contribuir por pull request cuando quieran; la evaluación de equipos ya se realizó fuera del repositorio.

Reglas del flujo:

- **Una rama por bloque de trabajo**, con el prefijo del área: `area3/base`, `area3/pantallas`, `coord/app-base`.
- **Un commit por bloque**, en español, con el formato `areaN: verbo objeto (RN-AN-xx) #issue`. Si el commit cierra un issue, el mensaje lleva `Closes #nn`; GitHub lo cierra al llegar a `main`.
- **Coautoría por área.** Los commits de un área llevan al líder de esa área como coautor: `Co-Authored-By: Nombre <correo>`. Solo personas; nunca herramientas.
- **Merge a `main` en local** y push. No hace falta pull request para el trabajo de coordinación; el historial por bloques es la trazabilidad.
- **La coordinación puede todo**: crear, asignar y cerrar issues, revisar, aprobar y mergear pull requests de cualquier área, y subir a `main`.
- **Evidencia** de cada bloque (captura o salida de consola) en `docs/areaN-*/evidencias/`, con el número de issue en el nombre.
- **Los hooks vigilan** el formato del mensaje y que no haya rastro de herramientas de IA. Activarlos una vez por clon: `git config core.hooksPath .githooks`.

## Si quieres contribuir por pull request

1. Clona el repo (los líderes tienen escritura) o haz fork.
2. Activa el hook: `git config core.hooksPath .githooks`.
3. Toma un issue de tu área con `estado:disponible`; asígnatelo.
4. Rama `areaN/<issue>-<slug>`, solo dentro de las carpetas de tu área: `docs/areaN-*/`, `src/services/areaN/`, `src/modules/areaN-*/`, `supabase/migrations/*_aN_*.sql`, `supabase/seed/seed_areaN.sql`, `supabase/tests/areaN/`.
5. `pnpm lint` antes de subir. Con Claude Code: `/preparar-pr`.
6. Abre el PR con la plantilla completa y evidencia. Lo revisa el líder del área o la coordinación.

## Lo que no se hace

- Tocar archivos de otra área sin un issue de integración.
- Editar una migración existente; un cambio es una migración nueva.
- Escribir `productos.stock` directamente.
- Subir `.env`, llaves o `package-lock.json`.
- Instalar con `npm`.
- Mencionar herramientas de IA en commits, PRs, issues o código.

## Comandos

```text
pnpm install            dependencias (solo pnpm)
pnpm dev                app en http://localhost:5173 (requiere .env en la raíz)
pnpm lint               prettier + oxlint
pnpm build              compilación de producción
node supabase/sql.mjs file supabase/tests/areaN/pruebas_areaN.sql   pruebas SQL de un área
node supabase/sql.mjs file supabase/tests/coord/seguridad.sql       verifica que nada se lea sin sesión
node supabase/sql.mjs migrate supabase/migrations/<archivo>.sql     aplica una migración (solo coordinación)
```

No hay Supabase CLI ni Docker. Las migraciones las aplica la coordinación con el token de `.env.supabase`, que no se sube. Quien escriba una migración la entrega en su PR y la coordinación la aplica al mergear (D-10).
