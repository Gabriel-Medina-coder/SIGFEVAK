# Migraciones

Formato de nombre: `AAAAMMDD_HHMM_aN_descripcion.sql` (N = área dueña; `00` = compartido del coordinador). Se aplican en orden alfabético.

Nunca se edita una migración existente; un cambio es una migración nueva. Encabezado obligatorio:

```sql
-- Área N · Issue #nn · RN-AN-xx
-- Qué hace: una línea.
```

Con Claude Code: `/nueva-migracion N descripción`.
