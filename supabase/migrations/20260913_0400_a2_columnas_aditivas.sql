-- Área 2 · Issue #45 · RN-A2-05, RN-A2-09, RN-A2-10, RN-A2-11
-- Qué hace: agrega a clientes y facturas las columnas que piden el enunciado y las áreas 4, 5 y 6, las
-- secuencias de folios, el CHECK de RFC e índices. RLS de clientes y facturas ya viene de la migración base
-- (p_clientes_auth, p_facturas_auth); no se repite. Las columnas base del área 3 no se tocan.

CREATE SEQUENCE IF NOT EXISTS seq_comercializador START 1;
CREATE SEQUENCE IF NOT EXISTS seq_folio_factura   START 1;

ALTER TABLE clientes
    ADD COLUMN numero_comercializador VARCHAR(20) UNIQUE,                  -- RN-A2-11
    ADD COLUMN dias_credito           INT NOT NULL DEFAULT 30,             -- RN-A2-09
    ADD COLUMN activo                 BOOLEAN NOT NULL DEFAULT TRUE,       -- RN-A2-10
    ADD CONSTRAINT ck_dias_credito CHECK (dias_credito >= 0),
    ADD CONSTRAINT ck_rfc_formato CHECK (                                  -- RN-A2-05
        rfc IS NULL OR rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$'
    );

ALTER TABLE facturas
    ADD COLUMN folio             VARCHAR(20) UNIQUE,                       -- RN-A2-11
    ADD COLUMN subtotal          DECIMAL(14,2) NOT NULL DEFAULT 0,         -- RN-A2-02
    ADD COLUMN fecha_vencimiento DATE,                                     -- RN-A2-09
    ADD COLUMN fecha_cobro       DATE,                                     -- RN-A2-08
    ADD COLUMN uuid_cfdi         VARCHAR(36) UNIQUE;                       -- I-07, opcional

CREATE INDEX ix_facturas_estado_pago ON facturas(estado_pago);
CREATE INDEX ix_facturas_fecha_cobro ON facturas(fecha_cobro);
CREATE INDEX ix_facturas_vencimiento ON facturas(fecha_vencimiento);
CREATE INDEX ix_clientes_activo      ON clientes(activo);

COMMENT ON COLUMN facturas.subtotal    IS 'Derivada: suma de importe de los renglones. La escribe fn_recalcular_factura (RN-A2-02).';
COMMENT ON COLUMN facturas.fecha_cobro IS 'Derivada: la llena fn_estado_pago_factura al pasar a PAGADO (RN-A2-08).';
