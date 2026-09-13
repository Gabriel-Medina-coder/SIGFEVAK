-- Área 5 · Issue #94 · RN-A5-08, RN-A5-09, RN-A5-12, RN-A5-13, RN-A5-15, RN-A5-17
-- Qué hace: importaciones, productos_importados y licencias_permisos; triggers que toman la tasa IGI por fracción
-- y la congelan por producto, recalculan IGI, DTA e IVA de importación y actualizan el monto de la obligación;
-- fn_actualizar_estado_licencias y v_licencias_por_vencer; bitácora y RLS.

CREATE TABLE importaciones (
    id_importacion       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion        INT NOT NULL REFERENCES obligaciones(id_obligacion),         -- RN-A5-08
    id_entrada           INT REFERENCES entradas_producto(id_entrada),                 -- I-04
    numero_pedimento     VARCHAR(30) NOT NULL UNIQUE,
    aduana               VARCHAR(100) NOT NULL,
    agente_aduanal       VARCHAR(150),
    pais_origen          VARCHAR(60) NOT NULL,
    pais_procedencia     VARCHAR(60) NOT NULL,
    fecha_importacion    DATE NOT NULL,
    valor_aduanero       DECIMAL(14,2) NOT NULL CHECK (valor_aduanero >= 0),
    igi                  DECIMAL(14,2) NOT NULL DEFAULT 0,
    dta                  DECIMAL(14,2) NOT NULL DEFAULT 0,
    iva_importacion      DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_contribuciones DECIMAL(14,2) GENERATED ALWAYS AS (igi + dta + iva_importacion) STORED,
    numero_e2            VARCHAR(30),
    padron_importador    VARCHAR(30),
    encargo_conferido    VARCHAR(30)
);
CREATE INDEX ix_importaciones_obligacion ON importaciones(id_obligacion);

CREATE TABLE productos_importados (
    id_producto_importado INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_importacion        INT NOT NULL REFERENCES importaciones(id_importacion) ON DELETE CASCADE,   -- RN-A5-09
    id_producto           INT REFERENCES productos(id_producto),
    nombre                VARCHAR(150) NOT NULL,
    marca                 VARCHAR(100),
    modelo                VARCHAR(100),
    cantidad              INT NOT NULL CHECK (cantidad > 0),
    valor_unitario        DECIMAL(12,2) NOT NULL CHECK (valor_unitario >= 0),
    valor_total           DECIMAL(14,2) GENERATED ALWAYS AS (cantidad * valor_unitario) STORED,
    fraccion_arancelaria  VARCHAR(10),                                                  -- RN-A5-10
    nico                  VARCHAR(4),                                                   -- RN-A5-11
    tasa_igi              DECIMAL(6,4) NOT NULL DEFAULT 0,                              -- RN-A5-13: congelada por producto
    igi_producto          DECIMAL(14,2) GENERATED ALWAYS AS (cantidad * valor_unitario * tasa_igi) STORED,
    nom_aplicable         VARCHAR(30)
);
CREATE INDEX ix_prod_importados_importacion ON productos_importados(id_importacion);

CREATE TABLE licencias_permisos (
    id_licencia       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_obligacion     INT REFERENCES obligaciones(id_obligacion),
    tipo_licencia     VARCHAR(60) NOT NULL,
    autoridad_emisora VARCHAR(150) NOT NULL,
    municipio         VARCHAR(80),
    numero_licencia   VARCHAR(60),
    fecha_emision     DATE,
    fecha_vencimiento DATE,
    costo             DECIMAL(12,2),
    estado            estado_licencia NOT NULL DEFAULT 'EN_TRAMITE',
    CONSTRAINT ck_municipio_obligatorio CHECK (
        tipo_licencia NOT IN ('USO_SUELO', 'LICENCIA_FUNCIONAMIENTO') OR municipio IS NOT NULL)   -- RN-A5-15
);

-- RN-A5-08: la obligación de una importación es de tipo PEDIMENTO
CREATE OR REPLACE FUNCTION fn_valida_importacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_clave TEXT; v_dta DECIMAL; v_iva DECIMAL;
BEGIN
    SELECT t.clave INTO v_clave FROM obligaciones o JOIN tipos_obligacion t USING (id_tipo_obligacion) WHERE o.id_obligacion = NEW.id_obligacion;
    IF v_clave IS DISTINCT FROM 'PEDIMENTO' THEN
        RAISE EXCEPTION 'RN-A5-08: la obligación % no es de tipo PEDIMENTO', NEW.id_obligacion;
    END IF;
    -- DTA e IVA de importación con los parámetros vigentes a la fecha de importación (RN-A5-20)
    v_dta := fn_parametro_fiscal('TASA_DTA', NULL, NULL, NEW.fecha_importacion);
    v_iva := fn_parametro_fiscal('TASA_IVA', NULL, NULL, NEW.fecha_importacion);
    IF v_dta IS NULL OR v_iva IS NULL THEN
        RAISE EXCEPTION 'RN-A5-20: faltan TASA_DTA o TASA_IVA vigentes al %', NEW.fecha_importacion;
    END IF;
    NEW.dta := ROUND(NEW.valor_aduanero * v_dta, 2);
    NEW.iva_importacion := ROUND((NEW.valor_aduanero + NEW.igi + NEW.dta) * v_iva, 2);
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_valida_importacion BEFORE INSERT OR UPDATE OF valor_aduanero, igi, fecha_importacion, id_obligacion ON importaciones
FOR EACH ROW EXECUTE FUNCTION fn_valida_importacion();

-- RN-A5-12, RN-A5-13: la tasa IGI se toma de parametros_fiscales por fracción y se congela en el producto
CREATE OR REPLACE FUNCTION fn_calcular_igi_producto() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_fecha DATE; v_tasa DECIMAL;
BEGIN
    IF NEW.fraccion_arancelaria IS NULL THEN
        NEW.tasa_igi := 0;
        RETURN NEW;
    END IF;
    SELECT fecha_importacion INTO v_fecha FROM importaciones WHERE id_importacion = NEW.id_importacion;
    v_tasa := fn_parametro_fiscal('TASA_IGI', NULL, NEW.fraccion_arancelaria, v_fecha);
    IF v_tasa IS NULL THEN
        RAISE EXCEPTION 'RN-A5-12: no hay TASA_IGI vigente para la fracción % al %', NEW.fraccion_arancelaria, v_fecha;
    END IF;
    NEW.tasa_igi := v_tasa;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_calcular_igi_producto BEFORE INSERT OR UPDATE OF fraccion_arancelaria, id_importacion ON productos_importados
FOR EACH ROW EXECUTE FUNCTION fn_calcular_igi_producto();

-- Recalcula el IGI de la importación (el trigger de importaciones recalcula DTA e IVA) y actualiza el monto de la obligación
CREATE OR REPLACE FUNCTION fn_recalcular_importacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_id INT; v_obl INT; v_total DECIMAL;
BEGIN
    v_id := COALESCE(NEW.id_importacion, OLD.id_importacion);
    UPDATE importaciones SET igi = (SELECT COALESCE(SUM(igi_producto), 0) FROM productos_importados WHERE id_importacion = v_id)
     WHERE id_importacion = v_id;
    SELECT id_obligacion, total_contribuciones INTO v_obl, v_total FROM importaciones WHERE id_importacion = v_id;
    UPDATE obligaciones SET monto_estimado = v_total
     WHERE id_obligacion = v_obl AND estado IN ('PENDIENTE', 'CALCULADO');
    RETURN NULL;
END; $$;
CREATE TRIGGER tg_recalcular_importacion AFTER INSERT OR UPDATE OR DELETE ON productos_importados
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_importacion();

-- 6.4: POR_VENCER 30 días antes del vencimiento; VENCIDA al día siguiente si no se renovó
CREATE OR REPLACE FUNCTION fn_actualizar_estado_licencias() RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_n INT := 0; v_m INT;
BEGIN
    UPDATE licencias_permisos SET estado = 'VENCIDA'
     WHERE estado IN ('VIGENTE', 'POR_VENCER') AND fecha_vencimiento < CURRENT_DATE;
    GET DIAGNOSTICS v_m = ROW_COUNT; v_n := v_n + v_m;
    UPDATE licencias_permisos SET estado = 'POR_VENCER'
     WHERE estado = 'VIGENTE' AND fecha_vencimiento >= CURRENT_DATE AND fecha_vencimiento - 30 <= CURRENT_DATE;
    GET DIAGNOSTICS v_m = ROW_COUNT; v_n := v_n + v_m;
    RETURN v_n;
END; $$;

CREATE OR REPLACE VIEW v_licencias_por_vencer AS
SELECT id_licencia, tipo_licencia, autoridad_emisora, municipio, numero_licencia,
       fecha_vencimiento, (fecha_vencimiento - CURRENT_DATE) AS dias_restantes, costo, estado
FROM licencias_permisos
WHERE estado IN ('VIGENTE', 'POR_VENCER', 'VENCIDA')
ORDER BY fecha_vencimiento;

-- RN-A5-17: bitácora de importaciones y licencias
CREATE TRIGGER tg_bitacora_importaciones AFTER INSERT OR UPDATE ON importaciones
FOR EACH ROW EXECUTE FUNCTION fn_bitacora_fiscal();
CREATE TRIGGER tg_bitacora_licencias AFTER INSERT OR UPDATE ON licencias_permisos
FOR EACH ROW EXECUTE FUNCTION fn_bitacora_fiscal();

ALTER TABLE importaciones        ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos_importados ENABLE ROW LEVEL SECURITY;
ALTER TABLE licencias_permisos   ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_importaciones_auth ON importaciones        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_prod_imp_auth      ON productos_importados FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_licencias_auth     ON licencias_permisos   FOR ALL TO authenticated USING (true) WITH CHECK (true);
