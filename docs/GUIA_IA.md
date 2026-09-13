# Guía para trabajar con IA en SIGFEVAK

Para las personas, no para los agentes. Las reglas que leen los agentes están en `AGENTS.md` y `CLAUDE.md`.

## Configuración inicial (una sola vez, antes de tu primer commit)

1. Clona tu fork y entra a la carpeta.
2. Activa el hook de git que revisa los mensajes de commit:

   ```text
   git config core.hooksPath .githooks
   ```

   En Windows con Git Bash funciona igual. Si usas PowerShell, el comando es el mismo.
3. Si usas **Claude Code**: no tienes que configurar nada. Al abrirlo en el repo lee `CLAUDE.md`, `.claude/settings.json` (atribución apagada, hook anti-rastro) y las skills.
4. Si usas **Cursor**: en su configuración de reglas apunta a `AGENTS.md`. No aceptes los mensajes de commit que sugiere sin leerlos.
5. Si usas **Copilot**: crea `.github/copilot-instructions.md` local con el contenido de `AGENTS.md` si quieres que lo lea; no lo subas. Desactiva la sugerencia automática de mensajes de commit o edítalos siempre.
6. Si usas **ChatGPT u otro chat**: pega el contenido de `AGENTS.md` y del `CONTEXTO.md` de tu área al inicio de la conversación.

## Regla de oro: cero rastro (D-08)

Usar IA está permitido y es bienvenido. Lo que **no** puede pasar es que quede registrado. Antes de cada push revisa:

- `git log -3` sin `Generated with`, enlaces de sesión ni nombres de herramientas. Las líneas `Co-Authored-By` con personas del equipo están bien; con una herramienta, no.
- La descripción del PR sin "con ayuda de", "generado por", emojis de robot ni enlaces de sesión.
- El código sin comentarios tipo `// generado por ...`.

El hook `.githooks/commit-msg` rechaza el commit si ve algo de eso. Si ya se coló y no has hecho push: `git commit --amend` y corrige el mensaje. Si hiciste push a tu fork pero el PR no se ha mergeado: corrige con `git rebase -i` y `git push --force-with-lease` a tu rama. Si ya se mergeó, avisa al coordinador.

## Cuándo sí, cuándo con cuidado, cuándo no

| Sí | Con cuidado (verifica contra el CONTEXTO.md) | No |
| --- | --- | --- |
| Boilerplate de componentes y servicios | Cálculos fiscales: ISR, IVA, IGI, DTA, ISN. La IA inventa tasas | Decidir alcance o cambiar el modelo de datos |
| Explicar un error de Supabase o de React | Triggers de stock: tiende a actualizar `stock` a mano | Tocar archivos de otra área |
| Escribir una migración a partir del diccionario de datos | RLS: olvida las políticas y todo regresa vacío | Escribir la descripción del PR sin leer el diff |
| Redactar pruebas SQL | Fórmulas de comisiones y bonos del Área 4 | Resolver una pregunta abierta por tu cuenta |
| Revisar tu propio PR antes de subirlo | Cualquier cosa que cruce dos áreas | |

## Prompt base (copia y pega)

```text
Estoy trabajando en el issue #NN del área N del proyecto SIGFEVAK.
Lee primero AGENTS.md y docs/areaN-*/CONTEXTO.md.
El objetivo del issue es: <pegar objetivo y criterios de aceptación>.
Solo modifica archivos dentro de <carpetas del área>.
Cita las reglas RN-AN-xx que apliquen.
Si algo no está definido en CONTEXTO.md, pregúntame antes de asumir.
No agregues ninguna mención a herramientas de IA en commits, código ni documentación.
```

## Skills de Claude Code (las mismas para todos)

| Skill | Cuándo usarla |
| --- | --- |
| `/tomar-issue 42` | Al empezar un issue: carga contexto y crea la rama |
| `/contexto-area 3` | Para entender un área antes de pedir código |
| `/nueva-migracion 3 trigger salida` | Para crear el archivo de migración con nombre correcto |
| `/preparar-pr` | Al terminar: lint, rastro, alcance; si todo pasa, hace push y abre el PR |
| `/actualizar-estado 42 progreso` | Para mover el issue en `ESTADO.md` |
| `/revisar-pr 57` | Líderes: revisión del diff contra las reglas del área; aprueba o pide cambios si tú lo confirmas |

El agente puede hacer push, abrir PRs y, para líderes, publicar la revisión. Lo que sigue siendo tuyo: leer el diff antes de que se suba y hacer el merge desde GitHub.

## Revisión obligatoria

Todo código generado por IA lo lees línea por línea antes de abrir el PR. La casilla "Revisé y entiendo cada cambio" de la plantilla es un compromiso, no un trámite. Si no puedes explicar una línea a tu líder, no la subas.

## Primer diagnóstico cuando "no funciona"

1. ¿La consulta regresa vacío teniendo datos? Es RLS. Revisa que la tabla tenga política para `authenticated`.
2. ¿El stock se duplicó? Alguien actualizó `productos.stock` a mano. Solo los triggers lo tocan.
3. ¿La migración falla al aplicar? Revisa que el nombre siga el formato y que no dependa de una migración con nombre alfabéticamente posterior.
4. ¿`pnpm install` falla por `engine-strict`? Estás usando npm. Instala pnpm.
