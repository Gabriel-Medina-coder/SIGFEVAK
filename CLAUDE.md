# SIGFEVAK — instrucciones para Claude Code

@AGENTS.md

## Extras para Claude Code

- Las reglas por área se cargan solas desde `.claude/rules/` cuando tocas la carpeta de esa área.
- Skills disponibles (invócalas con `/nombre`):
  - `/tomar-issue <número>`: lee el issue, carga el contexto del área, crea la rama.
  - `/contexto-area <N>`: resume tablas, reglas y preguntas abiertas del área N.
  - `/nueva-migracion <N> <descripción>`: crea el archivo de migración con nombre y encabezado correctos.
  - `/preparar-pr`: lint, revisión de rastro, verificación de carpeta; si todo pasa, hace push y abre el PR con la plantilla.
  - `/actualizar-estado <issue> <estado>`: mueve la línea del issue en `ESTADO.md`.
  - `/revisar-pr <número>`: para líderes; revisa el diff contra las reglas del área.
- Antes de proponer un commit, verifica que el mensaje no contenga ninguna mención a IA. El hook `.claude/hooks/check-commit.sh` lo bloquea de todos modos.
- Si un issue pide algo que no está en el `CONTEXTO.md` de su área, no lo implementes: registra la pregunta abierta y avisa.
