-- Área 4 · Issue #64 · RN-A4-04
-- Qué hace: enums del área, catálogos zonas, esquemas_compensacion y tramos_comision, trigger que impide
-- tramos traslapados dentro de un esquema, y RLS.

CREATE TYPE zona_salarial   AS ENUM ('GENERAL', 'ZLFN');
CREATE TYPE estatus_agente  AS ENUM ('ACTIVO', 'BAJA', 'SUSPENDIDO');
CREATE TYPE periodicidad    AS ENUM ('QUINCENAL', 'MENSUAL');
CREATE TYPE tipo_periodo    AS ENUM ('QUINCENAL', 'MENSUAL');
CREATE TYPE estatus_periodo AS ENUM ('ABIERTO', 'CALCULADO', 'REVISADO', 'AUTORIZADO', 'PAGADO', 'CERRADO');
CREATE TYPE tipo_concepto   AS ENUM ('PERCEPCION', 'DEDUCCION');

CREATE TABLE zonas (
    id_zona       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL UNIQUE,
    region        VARCHAR(50),
    zona_salarial zona_salarial NOT NULL DEFAULT 'GENERAL',   -- RN-A4-01: define el salario mínimo aplicable
    entidad       VARCHAR(50)
);

CREATE TABLE esquemas_compensacion (
    id_esquema      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    periodicidad    periodicidad NOT NULL DEFAULT 'MENSUAL',
    vigencia_inicio DATE NOT NULL,
    vigencia_fin    DATE
);

CREATE TABLE tramos_comision (
    id_tramo   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_esquema INT NOT NULL REFERENCES esquemas_compensacion(id_esquema) ON DELETE CASCADE,
    pct_min    DECIMAL(6,2) NOT NULL,
    pct_max    DECIMAL(6,2),                       -- NULL = sin tope
    tasa       DECIMAL(5,4) NOT NULL,              -- 0.0100 = 1 %
    CONSTRAINT ck_tramo_rango CHECK (pct_min >= 0 AND (pct_max IS NULL OR pct_max > pct_min)),   -- RN-A4-04
    CONSTRAINT ck_tramo_tasa  CHECK (tasa >= 0 AND tasa < 1)
);
CREATE INDEX ix_tramos_esquema ON tramos_comision(id_esquema);

-- RN-A4-04: los tramos de un esquema no se traslapan
CREATE OR REPLACE FUNCTION fn_valida_tramo() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tramos_comision t
         WHERE t.id_esquema = NEW.id_esquema
           AND t.id_tramo <> COALESCE(NEW.id_tramo, -1)
           AND NEW.pct_min < COALESCE(t.pct_max, 999999)
           AND t.pct_min   < COALESCE(NEW.pct_max, 999999)
    ) THEN
        RAISE EXCEPTION 'RN-A4-04: el tramo % a % se traslapa con otro tramo del esquema %',
            NEW.pct_min, COALESCE(NEW.pct_max::TEXT, 'sin tope'), NEW.id_esquema;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_valida_tramo BEFORE INSERT OR UPDATE ON tramos_comision
FOR EACH ROW EXECUTE FUNCTION fn_valida_tramo();

ALTER TABLE zonas                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE esquemas_compensacion  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tramos_comision        ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_zonas_auth    ON zonas                 FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_esquemas_auth ON esquemas_compensacion FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_tramos_auth   ON tramos_comision       FOR ALL TO authenticated USING (true) WITH CHECK (true);
