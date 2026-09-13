---
paths:
  - "docs/area1-entradas/**"
  - "src/services/area1/**"
  - "src/modules/area1-entradas/**"
  - "supabase/migrations/*_a1_*.sql"
  - "supabase/seed/seed_area1.sql"
  - "supabase/tests/area1/**"
---

# Reglas del área 1 (entradas)

- Lee `docs/area1-entradas/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A1-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area1:`.
- Al terminar, recuerda a la persona actualizar `docs/area1-entradas/ESTADO.md` (o usar `/actualizar-estado`).
