-- Coordinación · Seguridad · D-02
-- Qué hace: cierra el acceso sin sesión. Las vistas de PostgreSQL corren con los permisos de su dueño y se saltaban
-- el RLS de las tablas: con la llave anon pública se leían las 42 vistas (nómina, RFC, CLABE) y se ejecutaban
-- funciones como fn_marcar_vencidas. Tras esta migración:
--   1. Toda vista del esquema public usa security_invoker: aplica el RLS de las tablas con el usuario que consulta.
--   2. El rol anon no tiene privilegios sobre tablas, vistas, secuencias ni funciones del esquema public.
--   3. Lo que se cree después hereda lo mismo por privilegios por defecto.
-- Los usuarios autenticados conservan su acceso; las políticas por tabla no cambian.

DO $$
DECLARE v RECORD;
BEGIN
    FOR v IN SELECT viewname FROM pg_views WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER VIEW public.%I SET (security_invoker = true)', v.viewname);
    END LOOP;
END $$;

REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon, PUBLIC;
GRANT  EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES    FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon, PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT  EXECUTE ON FUNCTIONS TO authenticated, service_role;
