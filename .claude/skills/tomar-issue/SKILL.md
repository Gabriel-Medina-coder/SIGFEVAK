---
name: tomar-issue
description: Toma un issue de GitHub, carga el contexto de su área y crea la rama de trabajo con el nombre correcto
disable-model-invocation: true
arguments: [issue]
allowed-tools: Bash(gh issue view *) Bash(git fetch *) Bash(git switch *) Bash(git checkout *) Bash(git status) Bash(git branch *) Read Grep Glob
---

Vas a preparar el trabajo para el issue #$issue. No escribas código todavía; solo deja todo listo.

1. Lee el issue con `gh issue view $issue --json title,body,labels,assignees`.
2. Identifica el área por la etiqueta `area:N-...`. Si no tiene etiqueta de área, detente y dilo.
3. Lee completo `docs/areaN-*/CONTEXTO.md` del área. Anota las reglas `RN-AN-xx` que el issue menciona o que claramente aplican.
4. Sincroniza `main` con el repositorio original:
   - `git fetch upstream`
   - `git switch main`
   - `git merge --ff-only upstream/main`
   Si `upstream` no existe, explica cómo agregarlo (ver `CONTRIBUTING.md`) y detente.
5. Crea la rama `areaN/$issue-<slug>` donde `<slug>` son 2 a 4 palabras del título en minúsculas con guiones, sin acentos. Ejemplo: `area3/42-trigger-conciliacion`.
6. Responde con un resumen corto:
   - Objetivo del issue en una frase.
   - Criterios de aceptación (copiados del issue).
   - Archivos o carpetas que se espera tocar (solo dentro de la carpeta del área).
   - Reglas RN que aplican.
   - Preguntas abiertas si algo del issue no está definido en el `CONTEXTO.md`.

En este paso no modifiques archivos ni abras PR: solo deja la rama y el contexto listos. El push y el PR se hacen al final con `/preparar-pr`.
