# Migraciones

Formato de nombre: `AAAAMMDD_HHMM_aN_descripcion.sql` (N = área dueña; `00` = compartido del coordinador). Se aplican en orden alfabético.

Nunca se edita una migración existente; un cambio es una migración nueva. Encabezado obligatorio:

```sql
-- Área N · Issue #nn · RN-AN-xx
-- Qué hace: una línea.
```

Con Claude Code: `/nueva-migracion N descripción`.

## Cómo se aplican

Sin Supabase CLI (D-10). La coordinación aplica y registra cada migración con:

```text
node supabase/sql.mjs migrate supabase/migrations/<archivo>.sql
```

El script usa el token de `.env.supabase`, que no se sube. Para ver las ya registradas: `node supabase/sql.mjs migrations`.

## Seguridad

Toda vista nueva se crea con `CREATE VIEW nombre WITH (security_invoker = true) AS ...`; sin eso se salta el RLS y queda legible sin sesión (D-11). Después de aplicar, corre `node supabase/sql.mjs file supabase/tests/coord/seguridad.sql`.
