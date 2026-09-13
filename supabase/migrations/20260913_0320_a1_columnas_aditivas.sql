-- Área 1 · Issue #24 · RN-A1-01, RN-A1-02, RN-A1-07, RN-A1-18
-- Qué hace: columnas aditivas (opcionales o con default) en productos y entradas_producto, CHECK de moneda
-- y tipo de cambio, índice único parcial de SKU e índices de las FK nuevas. No toca columnas del área 3.
-- flete_unitario, impuestos_unitarios y tipo_cambio ya existen desde la migración del área 3 (I-01);
-- aquí no se repiten.

ALTER TABLE productos
    ADD COLUMN sku                   VARCHAR(50),
    ADD COLUMN codigo_barras         VARCHAR(50),
    ADD COLUMN categoria             VARCHAR(100),
    ADD COLUMN marca                 VARCHAR(100),
    ADD COLUMN modelo                VARCHAR(100),
    ADD COLUMN unidad_medida         VARCHAR(20) NOT NULL DEFAULT 'PIEZA',
    ADD COLUMN precio_venta_sugerido DECIMAL(12,2),
    ADD COLUMN stock_minimo          INT NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0);
CREATE UNIQUE INDEX uq_productos_sku ON productos(sku) WHERE sku IS NOT NULL;   -- RN-A1-01

ALTER TABLE entradas_producto
    ADD COLUMN id_proveedor              INT REFERENCES proveedores(id_proveedor),
    ADD COLUMN id_almacen                INT REFERENCES almacenes(id_almacen),
    ADD COLUMN id_lote                   INT REFERENCES lotes(id_lote),
    ADD COLUMN id_orden_produccion       INT UNIQUE REFERENCES ordenes_produccion(id_orden),   -- RN-A1-12
    ADD COLUMN cantidad_esperada         INT CHECK (cantidad_esperada IS NULL OR cantidad_esperada > 0),
    ADD COLUMN estado_mercancia          estado_mercancia NOT NULL DEFAULT 'BUEN_ESTADO',
    ADD COLUMN moneda                    VARCHAR(3) NOT NULL DEFAULT 'MXN',
    ADD COLUMN pais_origen               VARCHAR(60),
    ADD COLUMN numero_orden_compra       VARCHAR(50),
    ADD COLUMN numero_factura_proveedor  VARCHAR(50),
    ADD COLUMN fecha_factura_proveedor   DATE,
    ADD COLUMN documento_importacion_ref VARCHAR(100),
    ADD COLUMN responsable_recepcion     VARCHAR(150),
    ADD COLUMN observaciones             TEXT,
    ADD CONSTRAINT ck_tipo_cambio_moneda CHECK (                                          -- RN-A1-07
        (moneda = 'MXN' AND tipo_cambio = 1) OR (moneda <> 'MXN' AND tipo_cambio <> 1)
    );
-- RN-A1-18 se valida en trigger (fn_valida_entrada) para no rechazar filas históricas del área 3.

CREATE INDEX ix_entradas_proveedor ON entradas_producto(id_proveedor);
CREATE INDEX ix_entradas_almacen   ON entradas_producto(id_almacen);
CREATE INDEX ix_entradas_lote      ON entradas_producto(id_lote);
