-- Área 3 · Issue #4 · RN-A3-01, RN-A3-02, RN-A3-04, RN-A3-05, RN-A3-09
-- Qué hace: tablas núcleo del inventario (productos, entradas_producto, ajustes_inventario), la tabla
-- compartida detalle_factura (la escribe el área 2, el área 3 valida stock por trigger), índices y RLS.
-- Incluye desde ya las columnas de D-03 / I-01 en entradas_producto (flete, impuestos, tipo de cambio)
-- con defaults neutros, para que el área 1 no tenga que tocar el trigger de entrada.
-- Cierra también #2: las tablas marketing y clientes_marketing no se crean (I-09).

CREATE TABLE productos (
    id_producto       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo              tipo_producto NOT NULL,
    nombre            VARCHAR(150) NOT NULL,
    valor_entrada     DECIMAL(12,2) DEFAULT 0,
    capital_inversion DECIMAL(14,2) DEFAULT 0,
    volumen           INT DEFAULT 0,
    stock             INT NOT NULL DEFAULT 0,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,                  -- baja lógica (I-09)
    CONSTRAINT ck_stock_no_negativo   CHECK (stock >= 0),            -- RN-A3-01
    CONSTRAINT ck_volumen_no_negativo CHECK (volumen >= 0),          -- RN-A3-05
    CONSTRAINT uq_producto UNIQUE (nombre, tipo)
);
COMMENT ON COLUMN productos.volumen IS 'Acumulado histórico de unidades ingresadas; nunca decrece. No es el stock (RN-A3-05).';
COMMENT ON COLUMN productos.stock   IS 'Existencia actual. Solo la modifican los triggers de entrada, salida y ajuste (RN-A3-06).';

CREATE TABLE entradas_producto (
    id_entrada         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto        INT NOT NULL REFERENCES productos(id_producto),  -- RN-A3-02
    fecha              DATE NOT NULL DEFAULT CURRENT_DATE,
    cantidad           INT NOT NULL,
    costo_unitario     DECIMAL(12,2) NOT NULL,
    proveedor          VARCHAR(150),
    documento_ref      VARCHAR(50),
    flete_unitario     DECIMAL(12,2) NOT NULL DEFAULT 0,               -- D-03 / I-01
    impuestos_unitarios DECIMAL(12,2) NOT NULL DEFAULT 0,              -- D-03 / I-01
    tipo_cambio        DECIMAL(10,4) NOT NULL DEFAULT 1,               -- D-03 / I-01
    CONSTRAINT ck_entrada_cantidad CHECK (cantidad > 0),               -- RN-A3-04
    CONSTRAINT ck_entrada_costo    CHECK (costo_unitario >= 0),
    CONSTRAINT ck_entrada_flete    CHECK (flete_unitario >= 0),
    CONSTRAINT ck_entrada_imp      CHECK (impuestos_unitarios >= 0),
    CONSTRAINT ck_entrada_tc       CHECK (tipo_cambio > 0)
);
CREATE INDEX ix_entradas_producto ON entradas_producto(id_producto);
CREATE INDEX ix_entradas_fecha    ON entradas_producto(fecha);

CREATE TABLE detalle_factura (
    id_detalle      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_factura      INT NOT NULL REFERENCES facturas(id_factura) ON DELETE CASCADE,
    id_producto     INT NOT NULL REFERENCES productos(id_producto),    -- RN-A3-02
    cantidad        INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    importe DECIMAL(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0)                -- RN-A3-04
);
CREATE INDEX ix_detalle_producto ON detalle_factura(id_producto);
CREATE INDEX ix_detalle_factura  ON detalle_factura(id_factura);

CREATE TABLE ajustes_inventario (
    id_ajuste     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto   INT NOT NULL REFERENCES productos(id_producto),      -- RN-A3-02
    fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
    stock_sistema INT NOT NULL,
    conteo_fisico INT NOT NULL,
    diferencia    INT GENERATED ALWAYS AS (conteo_fisico - stock_sistema) STORED,   -- RN-A3-07
    motivo        VARCHAR(255),
    responsable   VARCHAR(150),
    CONSTRAINT ck_conteo_no_negativo CHECK (conteo_fisico >= 0)
);
CREATE INDEX ix_ajustes_producto ON ajustes_inventario(id_producto);

-- ---------- RLS mínima del proyecto ----------
ALTER TABLE productos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE entradas_producto  ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_factura    ENABLE ROW LEVEL SECURITY;
ALTER TABLE ajustes_inventario ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_productos_auth ON productos          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_entradas_auth  ON entradas_producto  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_detalle_auth   ON detalle_factura    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_ajustes_auth   ON ajustes_inventario FOR ALL TO authenticated USING (true) WITH CHECK (true);
