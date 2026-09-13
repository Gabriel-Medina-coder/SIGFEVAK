-- Área 00 · Coordinación · D-11
-- Qué hace: quita a anon y a PUBLIC la ejecución de las funciones creadas después de 20260913_0800_a00_seguridad_anon.
-- PostgreSQL da EXECUTE a PUBLIC en cada función nueva y el privilegio por defecto de la 0800 no lo evita en Supabase,
-- así que toda migración que cree funciones debe terminar con este mismo par de líneas (lo verifica tests/coord/seguridad.sql).

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon, PUBLIC;
GRANT  EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;
