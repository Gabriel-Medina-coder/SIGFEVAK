---
paths:
  - "docs/area4-nomina/**"
  - "src/services/area4/**"
  - "src/modules/area4-nomina/**"
  - "supabase/migrations/*_a4_*.sql"
  - "supabase/seed/seed_area4.sql"
  - "supabase/tests/area4/**"
---

# Reglas del área 4 (nomina)

- Lee `docs/area4-nomina/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A4-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area4:`.
- Al terminar, recuerda a la persona actualizar `docs/area4-nomina/ESTADO.md` (o usar `/actualizar-estado`).
