---
paths:
  - "docs/area6-marketing/**"
  - "src/services/area6/**"
  - "src/modules/area6-marketing/**"
  - "supabase/migrations/*_a6_*.sql"
  - "supabase/seed/seed_area6.sql"
  - "supabase/tests/area6/**"
---

# Reglas del área 6 (marketing)

- Lee `docs/area6-marketing/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A6-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area6:`.
- Al terminar, recuerda a la persona actualizar `docs/area6-marketing/ESTADO.md` (o usar `/actualizar-estado`).
