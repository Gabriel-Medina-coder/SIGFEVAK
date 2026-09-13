-- Área 6 · Issue #109 · RN-A6-01, RN-A6-04, RN-A6-07, RN-A6-10, RN-A6-16
-- Qué hace: campanas, costos_marketing, metricas_marketing, investigaciones_mercado y las uniones
-- campana_productos (área 3) y campana_clientes (área 2). Sustituyen a las tablas marcador marketing y
-- clientes_marketing del modelo base (I-09).

CREATE TABLE campanas (
    id_campana           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre               VARCHAR(200) NOT NULL,
    tipo_marketing       tipo_marketing NOT NULL,                        -- RN-A6-01: EXTERNO o DIRECTO
    objetivo             TEXT,
    descripcion          TEXT,
    fecha_inicio         DATE NOT NULL,
    fecha_fin            DATE,
    presupuesto_asignado DECIMAL(14,2) NOT NULL CHECK (presupuesto_asignado >= 0),
    moneda               CHAR(3) NOT NULL DEFAULT 'MXN',
    estatus              estatus_campana NOT NULL DEFAULT 'PLANEADA',
    id_responsable       UUID REFERENCES usuarios(id_usuario),
    creado_por           UUID REFERENCES usuarios(id_usuario),
    creado_en            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_campana_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)   -- RN-A6-10
);

CREATE TABLE costos_marketing (
    id_costo               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_campana             INT NOT NULL REFERENCES campanas(id_campana) ON DELETE RESTRICT,   -- RN-A6-04
    id_canal               INT NOT NULL REFERENCES canales_marketing(id_canal),
    id_proveedor_marketing INT REFERENCES proveedores_marketing(id_proveedor_marketing),     -- nulo = gasto interno
    concepto               VARCHAR(200) NOT NULL,
    monto                  DECIMAL(14,2) NOT NULL CHECK (monto > 0),
    moneda                 CHAR(3) NOT NULL DEFAULT 'MXN',
    fecha_gasto            DATE NOT NULL,
    id_factura             INT REFERENCES facturas(id_factura),          -- área 2, solo lectura; comprobante opcional
    estado_pago            estado_pago NOT NULL DEFAULT 'PENDIENTE',
    creado_en              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE metricas_marketing (
    id_metrica        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_campana        INT NOT NULL REFERENCES campanas(id_campana) ON DELETE CASCADE,
    id_canal          INT REFERENCES canales_marketing(id_canal),        -- nulo = métrica agregada de la campaña
    periodo_inicio    DATE NOT NULL,
    periodo_fin       DATE NOT NULL,
    impresiones       BIGINT NOT NULL DEFAULT 0,
    alcance           BIGINT NOT NULL DEFAULT 0,
    clics             BIGINT NOT NULL DEFAULT 0,
    leads_generados   INT NOT NULL DEFAULT 0,
    conversiones      INT NOT NULL DEFAULT 0,
    ingreso_atribuido DECIMAL(14,2) NOT NULL DEFAULT 0,                  -- estimado del equipo; el real sale de facturas (RN-A6-14)
    fuente_dato       VARCHAR(100),
    creado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_metrica_periodo CHECK (periodo_fin >= periodo_inicio)
);

CREATE TABLE investigaciones_mercado (
    id_investigacion       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo                 VARCHAR(200) NOT NULL,
    tipo                   tipo_investigacion NOT NULL,
    id_campana             INT REFERENCES campanas(id_campana) ON DELETE SET NULL,   -- RN-A6-16
    objetivo               TEXT,
    metodologia            TEXT,
    tamano_muestra         INT,
    id_proveedor_marketing INT REFERENCES proveedores_marketing(id_proveedor_marketing),
    costo                  DECIMAL(14,2) NOT NULL DEFAULT 0,
    fecha_inicio           DATE,
    fecha_fin              DATE,
    estado                 estado_investigacion NOT NULL DEFAULT 'PLANEADA',
    resumen_hallazgos      TEXT,
    url_reporte            TEXT,
    creado_por             UUID REFERENCES usuarios(id_usuario),
    creado_en              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Uniones con otras áreas (RN-A6-07): las FK garantizan que el producto y el cliente existen
CREATE TABLE campana_productos (
    id_campana  INT NOT NULL REFERENCES campanas(id_campana) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES productos(id_producto),          -- área 3, solo lectura
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_campana, id_producto)
);

CREATE TABLE campana_clientes (
    id_campana      INT NOT NULL REFERENCES campanas(id_campana) ON DELETE CASCADE,
    id_cliente      INT NOT NULL REFERENCES clientes(id_cliente),        -- área 2, solo lectura
    id_canal        INT REFERENCES canales_marketing(id_canal),
    fecha_contacto  DATE,
    estado_contacto estado_contacto NOT NULL DEFAULT 'OBJETIVO',
    notas           TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_campana, id_cliente)
);
