-- Área 00 · Coordinación · Seguridad (D-11)
-- Qué hace: lleva a la base el control de acceso por módulo que hoy solo vive en el frontend (src/lib/permisos.js).
-- Antes, cualquier usuario con sesión podía escribir en las tablas de cualquier área por la API (las políticas eran
-- `FOR ALL authenticated USING (true)`). Aquí cada tabla del modelo queda: lectura abierta a `authenticated` (las
-- áreas se leen entre sí por vistas de contrato) y escritura solo para los roles que el mismo mapa de la app le da a
-- ese módulo, más ADMINISTRADOR. No cambia lo que la app puede hacer; cierra lo que la API dejaba hacer de más.
--
-- Se dejan fuera a propósito:
--   productos            -> escritura abierta, pero stock/volumen/capital protegidos por el guard de 0930 (RN-A3-06),
--                           porque el trigger de salida (área 2) tiene que poder moverlo.
--   bitacora_nomina/fiscal -> append-only, las escriben triggers de varias áreas; se quedan abiertas a authenticated.
--   usuarios, parametros_*, zonas, esquemas_compensacion, tramos_comision, bonos_catalogo,
--   tipos_obligacion, instituciones, metas -> ya endurecidas en 0930.

DO $$
DECLARE
    -- tabla -> lista de roles que pueden escribir (ADMINISTRADOR se agrega siempre)
    mapa JSONB := '{
        "proveedores":            ["ALMACEN"],
        "almacenes":              ["ALMACEN"],
        "materias_primas":        ["ALMACEN"],
        "entradas_materia_prima": ["ALMACEN"],
        "bom":                    ["ALMACEN"],
        "ordenes_produccion":     ["ALMACEN"],
        "consumo_produccion":     ["ALMACEN"],
        "control_calidad":        ["ALMACEN"],
        "entradas_producto":      ["ALMACEN"],
        "lotes":                  ["ALMACEN"],
        "ajustes_inventario":     ["ALMACEN"],
        "clientes":               ["CONTADOR"],
        "facturas":               ["CONTADOR"],
        "detalle_factura":        ["CONTADOR"],
        "agentes_ventas":         ["CONTADOR","GERENTE_VENTAS","AUTORIZADOR"],
        "bonos_asignados":        ["CONTADOR","GERENTE_VENTAS","AUTORIZADOR"],
        "nomina_detalle":         ["CONTADOR","GERENTE_VENTAS","AUTORIZADOR"],
        "ajustes_comision":       ["CONTADOR","GERENTE_VENTAS","AUTORIZADOR"],
        "periodos_nomina":        ["CONTADOR","GERENTE_VENTAS","AUTORIZADOR"],
        "obligaciones":           ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "pagos_obligacion":       ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "documentos_fiscales":    ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "declaraciones":          ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "importaciones":          ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "productos_importados":   ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "licencias_permisos":     ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "impuestos_licencias":    ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "alertas":                ["CONTADOR","AUTORIZADOR","COMERCIO_EXTERIOR"],
        "campanas":               ["MARKETING"],
        "campana_clientes":       ["MARKETING"],
        "campana_productos":      ["MARKETING"],
        "costos_marketing":       ["MARKETING"],
        "metricas_marketing":     ["MARKETING"],
        "investigaciones_mercado":["MARKETING"],
        "canales_marketing":      ["MARKETING"],
        "proveedores_marketing":  ["MARKETING"]
    }'::JSONB;
    t TEXT; roles TEXT; nombre TEXT; cond TEXT;
BEGIN
    FOR t IN SELECT jsonb_object_keys(mapa) LOOP
        -- roles como lista SQL: 'ADMINISTRADOR','ALMACEN',...
        SELECT string_agg(quote_literal(r), ',') INTO roles
        FROM (SELECT 'ADMINISTRADOR' AS r UNION SELECT jsonb_array_elements_text(mapa->t)) x;
        cond := format('fn_rol_actual() IN (%s)', roles);

        FOR nombre IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = t LOOP
            EXECUTE format('DROP POLICY %I ON public.%I', nombre, t);
        END LOOP;
        EXECUTE format('CREATE POLICY p_%s_sel ON public.%I FOR SELECT TO authenticated USING (true)', t, t);
        EXECUTE format('CREATE POLICY p_%s_ins ON public.%I FOR INSERT TO authenticated WITH CHECK (%s)', t, t, cond);
        EXECUTE format('CREATE POLICY p_%s_upd ON public.%I FOR UPDATE TO authenticated USING (%s) WITH CHECK (%s)', t, t, cond, cond);
        EXECUTE format('CREATE POLICY p_%s_del ON public.%I FOR DELETE TO authenticated USING (%s)', t, t, cond);
    END LOOP;
END $$;
