-- Área 1 · Issue #25 · RN-A1-05, RN-A1-09, RN-A1-12, RN-A1-15
-- Qué hace: tablas de manufactura (lotes, materias_primas, entradas_materia_prima, ordenes_produccion, bom,
-- consumo_produccion, control_calidad) con sus CHECK y RLS. Va antes de las columnas aditivas porque
-- entradas_producto necesita las FK a lotes y ordenes_produccion.

CREATE TABLE lotes (
    id_lote              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto          INT NOT NULL REFERENCES productos(id_producto),   -- RN-A1-05
    numero_lote          VARCHAR(50) NOT NULL,
    fecha_fabricacion    DATE,
    fecha_vence_garantia DATE,
    condiciones_garantia TEXT,
    numero_serie_rango   VARCHAR(100),
    id_almacen           INT REFERENCES almacenes(id_almacen),
    CONSTRAINT uq_lote UNIQUE (id_producto, numero_lote)
);

CREATE TABLE materias_primas (
    id_materia     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku            VARCHAR(50) NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL,
    unidad_medida  VARCHAR(20) NOT NULL DEFAULT 'PIEZA',
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (costo_unitario >= 0),
    stock          DECIMAL(12,3) NOT NULL DEFAULT 0,
    id_almacen     INT NOT NULL REFERENCES almacenes(id_almacen),        -- RN-A1-06 (trigger)
    id_proveedor   INT REFERENCES proveedores(id_proveedor),
    lote           VARCHAR(50),
    CONSTRAINT ck_mp_stock_no_negativo CHECK (stock >= 0)                -- RN-A1-09
);
COMMENT ON COLUMN materias_primas.stock IS 'Solo lo modifican fn_entrada_materia y fn_consumo_materia (RN-A1-09).';

CREATE TABLE entradas_materia_prima (
    id_entrada_mp  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_materia     INT NOT NULL REFERENCES materias_primas(id_materia),
    fecha          DATE NOT NULL DEFAULT CURRENT_DATE,
    cantidad       DECIMAL(12,3) NOT NULL CHECK (cantidad > 0),
    costo_unitario DECIMAL(12,2) NOT NULL CHECK (costo_unitario >= 0),
    id_proveedor   INT REFERENCES proveedores(id_proveedor),
    documento_ref  VARCHAR(50)
);

CREATE TABLE ordenes_produccion (
    id_orden                INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio                   VARCHAR(20) NOT NULL UNIQUE,                  -- OP-AAAA-NNNN
    id_producto_destino     INT NOT NULL REFERENCES productos(id_producto),
    cantidad_planeada       INT NOT NULL CHECK (cantidad_planeada > 0),
    cantidad_terminada      INT CHECK (cantidad_terminada >= 0),
    fecha_inicio_programada DATE NOT NULL,
    fecha_fin_programada    DATE NOT NULL,
    fecha_inicio_real       DATE,
    fecha_fin_real          DATE,
    responsable             VARCHAR(150) NOT NULL,
    estado                  estado_orden NOT NULL DEFAULT 'PLANEADA',    -- RN-A1-11 (trigger)
    costo_mano_obra         DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (costo_mano_obra >= 0),
    costos_indirectos       DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (costos_indirectos >= 0),
    CONSTRAINT ck_orden_fechas CHECK (fecha_fin_programada >= fecha_inicio_programada)
);

CREATE TABLE bom (
    id_bom              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto_destino INT NOT NULL REFERENCES productos(id_producto),
    id_materia          INT NOT NULL REFERENCES materias_primas(id_materia),
    cantidad_por_unidad DECIMAL(12,3) NOT NULL CHECK (cantidad_por_unidad > 0),
    CONSTRAINT uq_bom UNIQUE (id_producto_destino, id_materia)
);

CREATE TABLE consumo_produccion (
    id_consumo    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden      INT NOT NULL REFERENCES ordenes_produccion(id_orden),
    id_materia    INT NOT NULL REFERENCES materias_primas(id_materia),
    cantidad_real DECIMAL(12,3) NOT NULL CHECK (cantidad_real > 0),
    merma         DECIMAL(12,3) NOT NULL DEFAULT 0,
    motivo_merma  VARCHAR(255),
    fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
    turno         VARCHAR(30),
    CONSTRAINT ck_merma        CHECK (merma >= 0 AND merma <= cantidad_real),
    CONSTRAINT ck_motivo_merma CHECK (merma = 0 OR motivo_merma IS NOT NULL)
);

CREATE TABLE control_calidad (
    id_qc          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_orden       INT NOT NULL UNIQUE REFERENCES ordenes_produccion(id_orden),   -- una inspección por orden
    aprobadas      INT NOT NULL CHECK (aprobadas >= 0),
    rechazadas     INT NOT NULL CHECK (rechazadas >= 0),
    motivo_rechazo VARCHAR(255),
    responsable    VARCHAR(150) NOT NULL,                                          -- RN-A1-16 (trigger)
    fecha          DATE NOT NULL DEFAULT CURRENT_DATE,
    resultado      resultado_calidad NOT NULL,
    CONSTRAINT ck_motivo_rechazo CHECK (rechazadas = 0 OR motivo_rechazo IS NOT NULL)   -- RN-A1-15
);

CREATE INDEX ix_lotes_producto     ON lotes(id_producto);
CREATE INDEX ix_ordenes_producto   ON ordenes_produccion(id_producto_destino);
CREATE INDEX ix_ordenes_estado     ON ordenes_produccion(estado);
CREATE INDEX ix_consumo_orden      ON consumo_produccion(id_orden);
CREATE INDEX ix_entradas_mp_materia ON entradas_materia_prima(id_materia);

-- ---------- RLS mínima ----------
ALTER TABLE lotes                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE materias_primas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE entradas_materia_prima ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordenes_produccion     ENABLE ROW LEVEL SECURITY;
ALTER TABLE bom                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumo_produccion     ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_calidad        ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_lotes_auth       ON lotes                  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_materias_auth    ON materias_primas        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_entradas_mp_auth ON entradas_materia_prima FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_ordenes_auth     ON ordenes_produccion     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_bom_auth         ON bom                    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_consumo_auth     ON consumo_produccion     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_calidad_auth     ON control_calidad        FOR ALL TO authenticated USING (true) WITH CHECK (true);
