---
name: actualizar-estado
description: Agrega o mueve la línea de un issue en el ESTADO.md del área (Hecho, En progreso, Bloqueado, Próximo) con la fecha
disable-model-invocation: true
arguments: [issue, estado]
allowed-tools: Bash(gh issue view *) Bash(date *) Read Edit Glob
---

Actualiza la bitácora del área para el issue #$issue con el estado "$estado".

1. Lee el issue con `gh issue view $issue --json title,labels,assignees` para obtener título, área y persona asignada. Si no hay acceso a `gh`, pide esos tres datos.
2. Abre `docs/areaN-*/ESTADO.md` del área del issue.
3. Estados válidos y sección destino:
   - `hecho` → `## Hecho`, con checkbox marcado y "mergeado AAAA-MM-DD".
   - `progreso` → `## En progreso`, con "PR abierto" o "en rama" según se indique.
   - `bloqueado` → `## Bloqueado`, con el motivo (pídelo si no se dio).
   - `proximo` → `## Próximo`.
4. Si el issue ya aparece en otra sección, quítalo de ahí y ponlo en la nueva. Formato de línea:
   `- [ ] #$issue <título corto> (<persona>) — <nota>`
5. Actualiza la línea `Última actualización: AAAA-MM-DD por <quien>` con la fecha de hoy.
6. Agrega una línea en la `## Bitácora` del día de hoy describiendo el cambio en una frase.
7. Muestra el diff resultante.

No toques ningún otro archivo ni hagas commit.
