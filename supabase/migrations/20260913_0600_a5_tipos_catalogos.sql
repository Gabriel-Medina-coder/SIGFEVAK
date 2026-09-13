-- Área 5 · Issue #87 · RN-A5-02, RN-A5-12, RN-A5-19, RN-A5-20
-- Qué hace: los 8 enums del área, catálogos instituciones y tipos_obligacion, parametros_fiscales con vigencia y
-- fn_parametro_fiscal, y la tabla del modelo base impuestos_licencias (dueña: área 5) con RLS.

CREATE TYPE estado_obligacion     AS ENUM ('PENDIENTE', 'CALCULADO', 'PRESENTADO', 'LINEA_GENERADA', 'AUTORIZADO', 'PAGADO', 'CONCILIADO', 'CERRADO', 'VENCIDO');
CREATE TYPE ambito_institucion    AS ENUM ('FEDERAL', 'ESTATAL', 'MUNICIPAL');
CREATE TYPE frecuencia_obligacion AS ENUM ('MENSUAL', 'BIMESTRAL', 'TRIMESTRAL', 'ANUAL', 'POR_OPERACION', 'SEGUN_VIGENCIA');
CREATE TYPE nivel_alerta          AS ENUM ('PREVENTIVA', 'ALTA', 'CRITICA', 'VENCIDA');
CREATE TYPE estado_envio_alerta   AS ENUM ('PENDIENTE', 'MOSTRADA', 'ATENDIDA');
CREATE TYPE metodo_pago_fiscal    AS ENUM ('TRANSFERENCIA', 'SPEI', 'VENTANILLA', 'TARJETA', 'PORTAL');
CREATE TYPE tipo_documento_fiscal AS ENUM ('ACUSE_SAT', 'COMPROBANTE_BANCARIO', 'CFDI', 'PEDIMENTO', 'MANIFESTACION_E2', 'LICENCIA_FUNCIONAMIENTO', 'USO_SUELO', 'DICTAMEN_PROTECCION_CIVIL', 'REGISTRO_SIEM', 'OTRO');
CREATE TYPE estado_licencia       AS ENUM ('EN_TRAMITE', 'VIGENTE', 'POR_VENCER', 'VENCIDA');

CREATE TABLE instituciones (
    id_institucion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL UNIQUE,
    siglas         VARCHAR(20),
    ambito         ambito_institucion NOT NULL,
    entidad        VARCHAR(50),
    portal_url     VARCHAR(255)
);

CREATE TABLE tipos_obligacion (
    id_tipo_obligacion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_institucion     INT NOT NULL REFERENCES instituciones(id_institucion),   -- RN-A5-02
    clave              VARCHAR(30) NOT NULL UNIQUE,
    nombre             VARCHAR(150) NOT NULL,
    frecuencia         frecuencia_obligacion NOT NULL,
    dias_vencimiento   INT,                                                      -- día del mes siguiente en que vence
    critica            BOOLEAN NOT NULL DEFAULT TRUE,                            -- RN-A5-06
    descripcion        TEXT
);

-- RN-A5-20: toda tasa, tarifa o valor legal vive aquí con vigencia; nunca en código
CREATE TABLE parametros_fiscales (
    id_parametro    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave           VARCHAR(40) NOT NULL,
    entidad         VARCHAR(50),
    fraccion        VARCHAR(10),
    valor           DECIMAL(14,6),
    tabla           JSONB,
    vigencia_inicio DATE NOT NULL,
    vigencia_fin    DATE,
    fuente          VARCHAR(150),
    CONSTRAINT ck_param_valor_o_tabla CHECK ((valor IS NULL) <> (tabla IS NULL)),
    CONSTRAINT ck_igi_con_fraccion CHECK (clave <> 'TASA_IGI' OR fraccion IS NOT NULL)   -- RN-A5-12
);
CREATE INDEX ix_param_fiscal ON parametros_fiscales(clave, entidad, fraccion, vigencia_inicio);

-- RN-A5-20: parámetro fiscal vigente a una fecha
CREATE OR REPLACE FUNCTION fn_parametro_fiscal(p_clave VARCHAR, p_entidad VARCHAR, p_fraccion VARCHAR, p_fecha DATE)
RETURNS DECIMAL LANGUAGE sql STABLE AS $$
    SELECT valor FROM parametros_fiscales
     WHERE clave = p_clave
       AND (entidad  IS NOT DISTINCT FROM p_entidad)
       AND (fraccion IS NOT DISTINCT FROM p_fraccion)
       AND vigencia_inicio <= p_fecha
       AND (vigencia_fin IS NULL OR vigencia_fin >= p_fecha)
     ORDER BY vigencia_inicio DESC LIMIT 1;
$$;

-- Modelo base: permiso, impuesto o trámite aduanal ligado a un producto (docs/MODELO_DATOS.md, dueña el área 5)
CREATE TABLE impuestos_licencias (
    id_permiso        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto       INT NOT NULL REFERENCES productos(id_producto),
    tipo              tipo_permiso NOT NULL,
    costo             DECIMAL(12,2),
    fecha_vencimiento DATE,
    estado_pago       estado_pago NOT NULL DEFAULT 'PENDIENTE'
);
CREATE INDEX ix_impuestos_producto ON impuestos_licencias(id_producto);

ALTER TABLE instituciones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipos_obligacion    ENABLE ROW LEVEL SECURITY;
ALTER TABLE parametros_fiscales ENABLE ROW LEVEL SECURITY;
ALTER TABLE impuestos_licencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_instituciones_auth ON instituciones       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_tipos_obl_auth     ON tipos_obligacion    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_param_fiscal_auth  ON parametros_fiscales FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_imp_lic_auth       ON impuestos_licencias FOR ALL TO authenticated USING (true) WITH CHECK (true);
