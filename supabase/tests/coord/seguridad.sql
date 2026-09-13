-- Coordinación · Pruebas de seguridad (D-02)
-- Falla si alguna vista no usa security_invoker, si anon conserva privilegios en public, o si una tabla no tiene RLS.
-- Correr después de cada migración nueva: node supabase/sql.mjs file supabase/tests/coord/seguridad.sql
DO $$
DECLARE v_lista TEXT;
BEGIN
    SELECT string_agg(c.relname, ', ') INTO v_lista
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relkind = 'v'
       AND NOT COALESCE((SELECT bool_or(o = 'security_invoker=true') FROM unnest(c.reloptions) o), FALSE);
    IF v_lista IS NOT NULL THEN
        RAISE EXCEPTION 'Vistas sin security_invoker (se saltan RLS): %', v_lista;
    END IF;

    SELECT string_agg(DISTINCT table_name, ', ') INTO v_lista
      FROM information_schema.role_table_grants WHERE table_schema = 'public' AND grantee = 'anon';
    IF v_lista IS NOT NULL THEN
        RAISE EXCEPTION 'anon conserva privilegios sobre: %', v_lista;
    END IF;

    SELECT string_agg(p.proname, ', ') INTO v_lista
      FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND has_function_privilege('anon', p.oid, 'EXECUTE');
    IF v_lista IS NOT NULL THEN
        RAISE EXCEPTION 'anon puede ejecutar: %', v_lista;
    END IF;

    SELECT string_agg(tablename, ', ') INTO v_lista FROM pg_tables WHERE schemaname = 'public' AND NOT rowsecurity;
    IF v_lista IS NOT NULL THEN
        RAISE EXCEPTION 'Tablas sin RLS: %', v_lista;
    END IF;

    RAISE NOTICE 'Seguridad: todas las pruebas pasaron';
END $$;
