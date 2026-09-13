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

## Seguridad (coordinación)

- `20260913_0800_a00_seguridad_anon.sql`: sin sesión no se lee ni ejecuta nada (D-11).
- `20260913_0910` y `_0910`: quitan la ejecución de funciones a `anon` y `PUBLIC`; toda migración que cree funciones repite ese REVOKE/GRANT.
- `20260913_0930_a00_endurece_autorizacion.sql` y `20260913_0940_a00_rls_por_rol.sql`: control de acceso por rol en la base (D-13). Ver `docs/SEGURIDAD.md`.
