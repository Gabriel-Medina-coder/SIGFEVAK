---
name: preparar-pr
description: Verifica lint, rastro de IA, alcance de carpeta y migraciones; si todo pasa, hace push de la rama y abre el pull request con la plantilla del repo
disable-model-invocation: true
allowed-tools: Bash(pnpm lint) Bash(git status) Bash(git log *) Bash(git diff *) Bash(git branch *) Bash(git push *) Bash(gh pr create *) Bash(gh pr view *) Read Grep Glob
---

Prepara la rama actual y abre el pull request. Haz las verificaciones en orden y reporta cada una como ✅ o ❌.

1. **Rama.** `git branch --show-current` debe tener el formato `areaN/<issue>-<slug>`. Extrae N y el número de issue.
2. **Lint.** Corre `pnpm lint`. Si falla, lista los errores y detente aquí.
3. **Rastro de IA.** Revisa `git log main..HEAD --format=%B` y `git diff main...HEAD`. Busca, sin distinguir mayúsculas: `co-authored-by`, `generated with`, `claude`, `anthropic`, `copilot`, `chatgpt`, `openai`, `cursor`, `claude-session`, `🤖`. Si aparece en un mensaje de commit, corrígelo con `git commit --amend` (un commit) o explica el `rebase -i` (varios). Si aparece en el código, quítalo del archivo. Vuelve a verificar.
4. **Alcance.** `git diff --name-only main...HEAD`. Todos los archivos deben estar dentro de las carpetas del área N: `docs/areaN-*/`, `src/services/areaN/`, `src/modules/areaN-*/`, `supabase/migrations/*_aN_*.sql`, `supabase/seed/seed_areaN.sql`, `supabase/tests/areaN/`. Un archivo fuera de ahí es ❌ y requiere un issue de integración; no continúes.
5. **Migraciones.** Si el diff modifica una migración que ya existía en `main`, es ❌; no continúes.
6. **Secretos.** Si el diff incluye `.env` o cadenas que parezcan llaves (`eyJ...`, `sk_...`, `service_role`), es ❌; no continúes.
7. **Prefijo de commits.** Cada commit de la rama empieza con `areaN:`, `docs:`, `coord:`, `fix:`, `ci:` o `chore:`.
8. **Descripción.** Lee `.github/PULL_REQUEST_TEMPLATE.md` y redacta el cuerpo del PR llenando cada sección con lo que ves en el diff: `Closes #nn`, área, qué se hizo, reglas RN implementadas, cómo se probó. En "Evidencia" pregunta a la persona qué captura o salida adjunta; si no tiene, deja el marcador `<!-- pendiente: adjuntar evidencia -->` y díselo.
9. **Push y PR.** Solo si todo lo anterior es ✅:
   - `git push -u origin <rama>`
   - `gh pr create --base main --repo Gabriel-Medina-coder/SIGFEVAK --title "<título del issue>" --body-file <archivo temporal con el cuerpo>`
   - Muestra la URL del PR.
10. Recuerda a la persona: el líder revisa en menos de 12 h; los cambios pedidos se hacen en la misma rama con push normal; y hay que actualizar `docs/areaN-*/ESTADO.md` (o usar `/actualizar-estado`).

El cuerpo y el título del PR no llevan ninguna mención a herramientas de IA (regla D-08).
