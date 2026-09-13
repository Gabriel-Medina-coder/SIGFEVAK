---
paths:
  - "supabase/migrations/**"
  - "supabase/seed/**"
  - "supabase/tests/**"
---

# Reglas para migraciones, seed y pruebas SQL

- **Nunca edites una migración existente.** Un cambio es una migración nueva.
- Nombre: `AAAAMMDD_HHMM_aN_descripcion.sql` (N = área dueña; `00` para lo compartido del coordinador). Ejemplo: `20260912_1030_a3_triggers_stock.sql`. Usa `/nueva-migracion` para crearla.
- Encabezado obligatorio en cada migración:
  ```sql
  -- Área N · Issue #nn · RN-AN-xx
  -- Qué hace: una línea.
  ```
- Tablas y columnas en `minusculas_con_guion_bajo`, en español. Tablas en plural, llaves en singular.
- Enums como tipos PostgreSQL. No agregues valores a un enum sin registrarlo en `docs/MODELO_DATOS.md`.
- Toda función y trigger lleva comentario con la RN que implementa.
- Validaciones críticas en la base: `CHECK` y triggers, no solo en el frontend.
- Toda tabla nueva activa RLS y define al menos la política mínima para `authenticated`.
- Toda vista nueva se crea con `CREATE VIEW nombre WITH (security_invoker = true) AS ...`. Sin eso la vista corre con permisos del dueño, se salta el RLS y queda legible sin sesión. Después de aplicar, corre `supabase/tests/coord/seguridad.sql`.
- Nunca otorgues privilegios a `anon`; todo el acceso es con sesión (`authenticated`).
- Nunca escribas `productos.stock` directamente (RN-A3-06).
- Seed: un archivo por área en `supabase/seed/seed_areaN.sql`, idempotente si es posible (`ON CONFLICT DO NOTHING`).
- Pruebas: `supabase/tests/areaN/*.sql`; cada prueba dice qué RN verifica y falla con `RAISE EXCEPTION` si no se cumple.
