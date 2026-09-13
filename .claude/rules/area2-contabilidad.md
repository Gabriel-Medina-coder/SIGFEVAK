---
paths:
  - "docs/area2-contabilidad/**"
  - "src/services/area2/**"
  - "src/modules/area2-contabilidad/**"
  - "supabase/migrations/*_a2_*.sql"
  - "supabase/seed/seed_area2.sql"
  - "supabase/tests/area2/**"
---

# Reglas del área 2 (contabilidad)

- Lee `docs/area2-contabilidad/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A2-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area2:`.
- Al terminar, recuerda a la persona actualizar `docs/area2-contabilidad/ESTADO.md` (o usar `/actualizar-estado`).
