#!/usr/bin/env bash
# Hook PreToolUse de Claude Code.
# Bloquea cualquier comando `git commit` cuyo mensaje deje rastro de herramientas de IA.
# Los coautores humanos (Co-Authored-By: Nombre <usuario@users.noreply.github.com>) sí se permiten;
# lo que se rechaza es el nombre de una herramienta en cualquier parte del mensaje.
# (regla D-08 de PLAN.md). Recibe por stdin el JSON de la llamada a la herramienta.
# Solo se inspecciona el campo tool_input.command; el resto del JSON (rutas de sesión,
# directorio de trabajo) puede contener palabras que no vienen del mensaje de commit.

input="$(cat)"

# Extraer únicamente el comando. Con jq si existe; si no, con sed sobre el campo "command".
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\(\\.\|[^"\\]\)*\)".*/\1/p' | head -n 1)"
fi

[ -z "$cmd" ] && exit 0

# Solo nos interesan los comandos que crean o reescriben commits.
case "$cmd" in
  *"git commit"*|*"git merge"*|*"git rebase"*|*"git cherry-pick"*) ;;
  *) exit 0 ;;
esac

# Patrones prohibidos en el comando (mayúsculas o minúsculas).
if printf '%s' "$cmd" | grep -qiE 'generated with|anthropic|copilot|chatgpt|openai|cursor|claude|🤖'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Regla D-08: el mensaje de commit contiene rastro de herramientas de IA (Co-Authored-By, Generated with, nombre de herramienta o enlace de sesión). Reescribe el mensaje con el formato 'areaN: verbo objeto #issue'."
  }
}
JSON
  exit 0
fi

exit 0
