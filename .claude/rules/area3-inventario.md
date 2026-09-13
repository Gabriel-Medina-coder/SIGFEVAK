---
paths:
  - "docs/area3-inventario/**"
  - "src/services/area3/**"
  - "src/modules/area3-inventario/**"
  - "supabase/migrations/*_a3_*.sql"
  - "supabase/seed/seed_area3.sql"
  - "supabase/tests/area3/**"
---

# Reglas del área 3 (inventario)

- Lee `docs/area3-inventario/CONTEXTO.md` completo antes de cualquier cambio. Es la fuente de verdad del área.
- Las reglas de negocio de esta área se numeran `RN-A3-xx`. Cítalas en commits, comentarios y PR.
- Solo escribe en las tablas que el `CONTEXTO.md` marca como "escritura". Las demás son de lectura; si necesitas cambiarlas, es un issue `tipo:integracion` con el área dueña.
- Si el issue pide algo que no está en el `CONTEXTO.md`, no lo implementes: agrégalo a "Preguntas abiertas" y avisa.
- Commits con prefijo `area3:`.
- Al terminar, recuerda a la persona actualizar `docs/area3-inventario/ESTADO.md` (o usar `/actualizar-estado`).
