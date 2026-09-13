-- Área 6 · Issue #110 · RN-A6-05, RN-A6-06, RN-A6-09
-- Qué hace: índices, RLS mínima para authenticated en las ocho tablas y el trigger de actualizado_en en las
-- siete que lo tienen. El endurecimiento por rol (RN-A6-05, RN-A6-06) queda para cuando se decida
-- (pregunta abierta 8); fn_a6_usuario_tiene_rol se deja lista.

CREATE INDEX ix_campanas_estatus        ON campanas(estatus);
CREATE INDEX ix_campanas_tipo           ON campanas(tipo_marketing);
CREATE INDEX ix_campanas_fechas         ON campanas(fecha_inicio, fecha_fin);
CREATE INDEX ix_costos_mkt_campana      ON costos_marketing(id_campana);
CREATE INDEX ix_costos_mkt_canal        ON costos_marketing(id_canal);
CREATE INDEX ix_costos_mkt_fecha        ON costos_marketing(fecha_gasto);
CREATE INDEX ix_metricas_mkt_campana    ON metricas_marketing(id_campana);
CREATE INDEX ix_metricas_mkt_periodo    ON metricas_marketing(periodo_inicio);
CREATE INDEX ix_campana_productos_prod  ON campana_productos(id_producto);
CREATE INDEX ix_campana_clientes_cli    ON campana_clientes(id_cliente);
CREATE INDEX ix_investigaciones_campana ON investigaciones_mercado(id_campana);

-- RN-A6-09
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['canales_marketing', 'proveedores_marketing', 'campanas', 'costos_marketing',
                             'metricas_marketing', 'campana_clientes', 'investigaciones_mercado'] LOOP
        EXECUTE format('CREATE TRIGGER tg_%1$s_actualizado_en BEFORE UPDATE ON %1$I
                        FOR EACH ROW EXECUTE FUNCTION fn_a6_set_actualizado_en()', t);
    END LOOP;
END $$;

-- RLS mínima del proyecto
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['canales_marketing', 'proveedores_marketing', 'campanas', 'costos_marketing',
                             'metricas_marketing', 'campana_productos', 'campana_clientes', 'investigaciones_mercado'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('CREATE POLICY p_%1$s_auth ON %1$I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;

-- RN-A6-05, RN-A6-06: lista para las políticas por rol del endurecimiento
CREATE OR REPLACE FUNCTION fn_a6_usuario_tiene_rol(roles_permitidos rol_usuario[])
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM usuarios u
         WHERE u.id_usuario = auth.uid() AND u.rol = ANY(roles_permitidos) AND u.activo
    );
$$;
