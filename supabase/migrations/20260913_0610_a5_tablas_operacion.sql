-- Área 5 · Issue #88 · RN-A5-01, RN-A5-03, RN-A5-07, RN-A5-18, RN-A5-21, RN-A5-22
-- Qué hace: obligaciones (tabla central), declaraciones, pagos_obligacion, documentos_fiscales, alertas y
-- bitacora_fiscal con sus CHECK, índices y RLS. Sin política de DELETE en obligaciones, pagos y documentos
-- (RN-A5-22: la baja es lógica).

CREATE TABLE obligaciones (
    id_obligacion      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_obligacion INT NOT NULL REFERENCES tipos_obligacion(id_tipo_obligacion),   -- RN-A5-01
    id_permiso         INT REFERENCES impuestos_licencias(id_permiso),
    periodo            VARCHAR(7),                                                      -- AAAA-MM o AAAA; NULL por operación
    fecha_vencimiento  DATE NOT NULL,                                                   -- RN-A5-03
    monto_estimado     DECIMAL(14,2),
    monto_final        DECIMAL(14,2),                                                   -- se congela al autorizar (RN-A5-23)
    estado             estado_obligacion NOT NULL DEFAULT 'PENDIENTE',
    id_responsable     UUID REFERENCES usuarios(id_usuario),
    id_autorizador     UUID REFERENCES usuarios(id_usuario),
    entidad            VARCHAR(50),
    comentario         TEXT,
    fecha_cierre       DATE,
    activo             BOOLEAN NOT NULL DEFAULT TRUE,                                   -- RN-A5-22
    CONSTRAINT ck_separacion_funciones CHECK (id_autorizador IS NULL OR id_autorizador <> id_responsable)   -- RN-A5-18
);
CREATE UNIQUE INDEX uq_obligacion_periodo ON obligaciones(id_tipo_obligacion, periodo) WHERE periodo IS NOT NULL;
CREATE INDEX ix_obligaciones_vencimiento ON obligaciones(fecha_vencimiento);
CREATE INDEX ix_obligaciones_estado ON obligaciones(estado);

CREATE TABLE declaraciones (
    id_declaracion     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion      INT NOT NULL REFERENCES obligaciones(id_obligacion),
    tipo_declaracion   VARCHAR(50) NOT NULL,
    numero_operacion   VARCHAR(50),
    folio              VARCHAR(50),
    linea_captura      VARCHAR(60),
    fecha_presentacion DATE NOT NULL,
    importe_declarado  DECIMAL(14,2) NOT NULL CHECK (importe_declarado >= 0),
    fecha_limite_pago  DATE
);
CREATE INDEX ix_declaraciones_obligacion ON declaraciones(id_obligacion);

CREATE TABLE pagos_obligacion (
    id_pago           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion     INT NOT NULL REFERENCES obligaciones(id_obligacion),
    fecha_pago        DATE NOT NULL,
    monto             DECIMAL(14,2) NOT NULL CHECK (monto > 0),
    banco             VARCHAR(80),
    referencia        VARCHAR(80) NOT NULL,                                             -- RN-A5-07
    linea_captura     VARCHAR(60),
    metodo_pago       metodo_pago_fiscal NOT NULL,
    estado_pago       estado_pago NOT NULL DEFAULT 'PAGADO',
    id_registrado_por UUID NOT NULL REFERENCES usuarios(id_usuario),
    id_autorizado_por UUID REFERENCES usuarios(id_usuario),
    CONSTRAINT ck_pago_separacion CHECK (id_autorizado_por IS NULL OR id_autorizado_por <> id_registrado_por)   -- RN-A5-18
);
CREATE INDEX ix_pagos_obligacion ON pagos_obligacion(id_obligacion);

CREATE TABLE documentos_fiscales (
    id_documento   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion  INT NOT NULL REFERENCES obligaciones(id_obligacion),
    id_pago        INT REFERENCES pagos_obligacion(id_pago),
    tipo_documento tipo_documento_fiscal NOT NULL,
    nombre         VARCHAR(150) NOT NULL,
    referencia     VARCHAR(255) NOT NULL,                                               -- URL o ruta; no se guarda el binario
    fecha          DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE INDEX ix_documentos_obligacion ON documentos_fiscales(id_obligacion);

CREATE TABLE alertas (
    id_alerta         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion     INT NOT NULL REFERENCES obligaciones(id_obligacion),
    fecha_alerta      DATE NOT NULL,
    dias_anticipacion INT NOT NULL,
    nivel             nivel_alerta NOT NULL,
    mensaje           TEXT NOT NULL,
    estado_envio      estado_envio_alerta NOT NULL DEFAULT 'PENDIENTE',
    id_usuario        UUID REFERENCES usuarios(id_usuario),
    CONSTRAINT uq_alerta UNIQUE (id_obligacion, dias_anticipacion)                    -- RN-A5-21
);
CREATE INDEX ix_alertas_fecha ON alertas(fecha_alerta, estado_envio);

CREATE TABLE bitacora_fiscal (
    id_bitacora    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario     UUID REFERENCES usuarios(id_usuario),
    tabla          VARCHAR(60) NOT NULL,
    id_registro    INT,
    accion         VARCHAR(20) NOT NULL,
    descripcion    TEXT,
    valor_anterior JSONB,
    valor_nuevo    JSONB,
    fecha          TIMESTAMP NOT NULL DEFAULT NOW(),
    ip             VARCHAR(45)
);
CREATE INDEX ix_bitacora_fiscal_registro ON bitacora_fiscal(tabla, id_registro);

-- ---------- RLS: sin DELETE en obligaciones, pagos y documentos (RN-A5-22) ----------
ALTER TABLE obligaciones        ENABLE ROW LEVEL SECURITY;
ALTER TABLE declaraciones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos_obligacion    ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos_fiscales ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertas             ENABLE ROW LEVEL SECURITY;
ALTER TABLE bitacora_fiscal     ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_obligaciones_sel ON obligaciones FOR SELECT TO authenticated USING (true);
CREATE POLICY p_obligaciones_ins ON obligaciones FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY p_obligaciones_upd ON obligaciones FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_pagos_sel ON pagos_obligacion FOR SELECT TO authenticated USING (true);
CREATE POLICY p_pagos_ins ON pagos_obligacion FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY p_pagos_upd ON pagos_obligacion FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_documentos_sel ON documentos_fiscales FOR SELECT TO authenticated USING (true);
CREATE POLICY p_documentos_ins ON documentos_fiscales FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY p_documentos_upd ON documentos_fiscales FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_declaraciones_auth ON declaraciones   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_alertas_auth       ON alertas         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_bitacora_f_sel     ON bitacora_fiscal FOR SELECT TO authenticated USING (true);
CREATE POLICY p_bitacora_f_ins     ON bitacora_fiscal FOR INSERT TO authenticated WITH CHECK (true);
