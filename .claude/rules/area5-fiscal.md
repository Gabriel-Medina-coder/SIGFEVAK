---
paths:
  - "docs/area5-fiscal/**"
  - "src/services/area5/**"
  - "src/modules/area5-fiscal/**"
  - "supabase/migrations/*_a5_*.sql"
  - "supabase/seed/seed_area5.sql"
  - "supabase/tests/area5/**"
---

# Reglas del área 5 (fiscal)

- Lee `docs/area5-fiscal/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A5-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area5:`.
- Al terminar, recuerda a la persona actualizar `docs/area5-fiscal/ESTADO.md` (o usar `/actualizar-estado`).
