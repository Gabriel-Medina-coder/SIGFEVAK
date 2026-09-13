-- Área 4 · Issue #65 · RN-A4-01, RN-A4-02, RN-A4-03, RN-A4-08, RN-A4-09, RN-A4-12, RN-A4-13, RN-A4-14
-- Qué hace: ampliación aditiva de agentes_ventas y tablas de operación (metas, bonos_catalogo, periodos_nomina,
-- bonos_asignados, nomina_detalle, ajustes_comision, parametros_legales, bitacora_nomina), índices, RLS y
-- bitácora automática de bonos capturados a mano. Las columnas base nombre, sueldo_base y comision no se tocan.

ALTER TABLE agentes_ventas
    ADD COLUMN rfc                VARCHAR(13) UNIQUE,
    ADD COLUMN curp               VARCHAR(18),
    ADD COLUMN nss                VARCHAR(11),
    ADD COLUMN fecha_ingreso      DATE,
    ADD COLUMN id_zona            INT REFERENCES zonas(id_zona),
    ADD COLUMN id_esquema         INT REFERENCES esquemas_compensacion(id_esquema),
    ADD COLUMN salario_diario     DECIMAL(10,2) DEFAULT 350.00,    -- RN-A4-01 (trigger en la siguiente migración)
    ADD COLUMN entidad_federativa VARCHAR(50),                     -- RN-A4-16: define la tasa de ISN
    ADD COLUMN clabe              VARCHAR(18),
    ADD COLUMN estatus            estatus_agente NOT NULL DEFAULT 'ACTIVO';

CREATE TABLE metas (
    id_meta      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_agente    INT NOT NULL REFERENCES agentes_ventas(id_agente),
    periodo      VARCHAR(7) NOT NULL CHECK (periodo ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),   -- 'AAAA-MM'
    monto_meta   DECIMAL(14,2) NOT NULL CHECK (monto_meta > 0),
    sin_retardos BOOLEAN NOT NULL DEFAULT TRUE,    -- bandera manual del premio de puntualidad (sección 3, fuera de alcance el control de asistencia)
    CONSTRAINT uq_meta UNIQUE (id_agente, periodo)  -- RN-A4-03
);

CREATE TABLE bonos_catalogo (
    id_bono     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave       VARCHAR(30) NOT NULL UNIQUE,      -- META, CLIENTE_NUEVO, COBRANZA_SANA, PUNTUALIDAD, TRIMESTRAL
    nombre      VARCHAR(100) NOT NULL,
    condicion   TEXT,
    monto       DECIMAL(12,2),
    porcentaje  DECIMAL(5,4),
    integra_sbc BOOLEAN NOT NULL DEFAULT TRUE,     -- RN-A4-10
    gravado_isr BOOLEAN NOT NULL DEFAULT TRUE,     -- RN-A4-12
    clave_sat   VARCHAR(3) NOT NULL DEFAULT '038',
    CONSTRAINT ck_bono_monto_o_pct CHECK ((monto IS NULL) <> (porcentaje IS NULL))
);

CREATE TABLE periodos_nomina (
    id_periodo     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo           tipo_periodo NOT NULL,
    fecha_inicio   DATE NOT NULL,
    fecha_fin      DATE NOT NULL,
    estatus        estatus_periodo NOT NULL DEFAULT 'ABIERTO',   -- RN-A4-13 (trigger en la siguiente migración)
    calculado_por  VARCHAR(150),
    revisado_por   VARCHAR(150),
    autorizado_por VARCHAR(150),                   -- RN-A4-15: distinto de calculado_por
    fecha_pago     DATE,
    comentario     TEXT,
    CONSTRAINT ck_periodo_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT uq_periodo UNIQUE (tipo, fecha_inicio)
);

CREATE TABLE bonos_asignados (
    id_bono_asignado INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_agente      INT NOT NULL REFERENCES agentes_ventas(id_agente),
    id_bono        INT NOT NULL REFERENCES bonos_catalogo(id_bono),
    id_periodo     INT NOT NULL REFERENCES periodos_nomina(id_periodo),
    monto          DECIMAL(12,2) NOT NULL CHECK (monto >= 0),
    calculado      BOOLEAN NOT NULL DEFAULT TRUE,
    autorizado_por VARCHAR(150),
    fecha          DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_bono_manual CHECK (calculado OR autorizado_por IS NOT NULL)   -- RN-A4-09
);
CREATE INDEX ix_bonos_periodo ON bonos_asignados(id_periodo);

CREATE TABLE nomina_detalle (
    id_detalle  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_periodo  INT NOT NULL REFERENCES periodos_nomina(id_periodo),
    id_agente   INT NOT NULL REFERENCES agentes_ventas(id_agente),
    concepto    VARCHAR(60) NOT NULL,
    tipo        tipo_concepto NOT NULL,
    clave_sat   VARCHAR(3) NOT NULL,
    monto       DECIMAL(12,2) NOT NULL CHECK (monto >= 0),
    gravado     DECIMAL(12,2) NOT NULL DEFAULT 0,
    exento      DECIMAL(12,2) NOT NULL DEFAULT 0,
    integra_sbc BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_gravado_exento CHECK (tipo = 'DEDUCCION' OR gravado + exento = monto)   -- RN-A4-12
);
CREATE INDEX ix_nomina_periodo ON nomina_detalle(id_periodo);
CREATE INDEX ix_nomina_agente  ON nomina_detalle(id_agente);

CREATE TABLE ajustes_comision (
    id_ajuste           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_agente           INT NOT NULL REFERENCES agentes_ventas(id_agente),
    id_factura          INT NOT NULL REFERENCES facturas(id_factura),
    id_periodo_origen   INT NOT NULL REFERENCES periodos_nomina(id_periodo),
    id_periodo_aplicado INT REFERENCES periodos_nomina(id_periodo),   -- NULL = pendiente
    monto               DECIMAL(12,2) NOT NULL CHECK (monto < 0),     -- RN-A4-08
    motivo              VARCHAR(255) NOT NULL,
    fecha               DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE INDEX ix_ajustes_pendientes ON ajustes_comision(id_agente) WHERE id_periodo_aplicado IS NULL;

CREATE TABLE parametros_legales (
    id_parametro    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave           VARCHAR(40) NOT NULL,
    entidad         VARCHAR(50),                   -- NULL = federal; nombre del estado para ISN
    valor           DECIMAL(14,4),
    tabla           JSONB,                          -- tarifas por rango (ISR art. 96)
    vigencia_inicio DATE NOT NULL,
    vigencia_fin    DATE,
    fuente          VARCHAR(150),
    CONSTRAINT ck_param_valor_o_tabla CHECK ((valor IS NULL) <> (tabla IS NULL))
);
CREATE INDEX ix_param_clave ON parametros_legales(clave, entidad, vigencia_inicio);
COMMENT ON TABLE parametros_legales IS 'Valores legales con vigencia (RN-A4-14). Cuando cambie el salario mínimo o la UMA se inserta un registro nuevo; no se toca código.';

CREATE TABLE bitacora_nomina (
    id_bitacora    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario        VARCHAR(150) NOT NULL,
    tabla          VARCHAR(60) NOT NULL,
    accion         VARCHAR(20) NOT NULL,
    valor_anterior JSONB,
    valor_nuevo    JSONB,
    fecha          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- RN-A4-09: un bono capturado a mano queda en bitácora con quien lo autorizó
CREATE OR REPLACE FUNCTION fn_bitacora_bono_manual() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT NEW.calculado THEN
        INSERT INTO bitacora_nomina (usuario, tabla, accion, valor_nuevo)
        VALUES (NEW.autorizado_por, 'bonos_asignados', 'BONO_MANUAL', to_jsonb(NEW));
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_bitacora_bono_manual AFTER INSERT ON bonos_asignados
FOR EACH ROW EXECUTE FUNCTION fn_bitacora_bono_manual();

-- ---------- RLS mínima ----------
ALTER TABLE metas              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonos_catalogo     ENABLE ROW LEVEL SECURITY;
ALTER TABLE periodos_nomina    ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonos_asignados    ENABLE ROW LEVEL SECURITY;
ALTER TABLE nomina_detalle     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ajustes_comision   ENABLE ROW LEVEL SECURITY;
ALTER TABLE parametros_legales ENABLE ROW LEVEL SECURITY;
ALTER TABLE bitacora_nomina    ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_metas_auth      ON metas              FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_bonos_cat_auth  ON bonos_catalogo     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_periodos_auth   ON periodos_nomina    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_bonos_asig_auth ON bonos_asignados    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_nomina_auth     ON nomina_detalle     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_ajustes_c_auth  ON ajustes_comision   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_param_auth      ON parametros_legales FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_bitacora_auth   ON bitacora_nomina    FOR ALL TO authenticated USING (true) WITH CHECK (true);
