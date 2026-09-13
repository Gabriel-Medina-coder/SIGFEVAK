---
name: revisar-pr
description: Para líderes. Revisa el diff de un PR contra las reglas del área (alcance, RN citadas, migraciones, RLS, rastro de IA, secretos) y devuelve observaciones. No aprueba ni comenta en GitHub.
disable-model-invocation: true
arguments: [pr]
allowed-tools: Bash(gh pr view *) Bash(gh pr diff *) Bash(gh pr checks *) Bash(gh pr review *) Bash(gh pr comment *) Read Grep Glob
---

Revisa el pull request #$pr como lo haría el líder del área. Primero analiza; publica en GitHub solo cuando el líder confirme.

1. `gh pr view $pr --json title,body,labels,author,files,baseRefName,headRefName` y `gh pr diff $pr`.
2. Identifica el área por la etiqueta o por la rama `areaN/...`. Lee `docs/areaN-*/CONTEXTO.md`.
3. Verifica y reporta cada punto como ✅, ⚠️ o ❌ con una línea de explicación:
   - **Alcance:** todos los archivos dentro de las carpetas del área. Archivos compartidos (`src/lib`, `src/components`, `App.jsx`, `.github`, `docs/*.md` de raíz) requieren al coordinador.
   - **Issue enlazado:** la descripción dice `Closes #nn` y el issue es del área.
   - **Reglas RN:** el PR cita las RN que implementa y el código las respeta. Si toca stock, comisiones, obligaciones o cálculos fiscales, compara contra la sección de reglas del `CONTEXTO.md`.
   - **Migraciones:** ninguna migración existente fue editada; las nuevas siguen el nombre `AAAAMMDD_HHMM_aN_*.sql` y llevan encabezado; toda tabla nueva activa RLS.
   - **Frontend:** ningún componente llama a `supabase.from()` directo; no hay SQL crudo; no hay cliente Supabase nuevo.
   - **Rastro de IA:** ni en commits, ni en descripción, ni en comentarios de código (`co-authored-by`, `generated with`, nombres de herramientas, enlaces de sesión).
   - **Secretos:** no hay `.env` ni llaves.
   - **Dependencias:** si `package.json` cambia, el PR lo justifica y no hay `package-lock.json`.
   - **Evidencia:** la descripción incluye captura, salida de consola o prueba SQL.
   - **ESTADO.md:** el PR o la persona actualizó la bitácora del área.
4. Cierra con una recomendación: "Listo para aprobar", "Pedir cambios: ..." o "Requiere al coordinador porque ...".
5. Pregunta al líder qué quiere hacer y ejecuta solo lo que confirme:
   - Aprobar: `gh pr review $pr --approve --body "<resumen corto>"`.
   - Pedir cambios: `gh pr review $pr --request-changes --body "<lista de observaciones>"`.
   - Solo comentar: `gh pr comment $pr --body "<observaciones>"`.
   El texto que publiques no lleva ninguna mención a herramientas de IA (regla D-08). El merge lo hace el líder desde GitHub con squash, revisando el mensaje final.

No modifiques archivos del repo.
