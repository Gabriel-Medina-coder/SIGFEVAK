-- Área 6 · Issue #108 · RN-A6-06, RN-A6-09
-- Qué hace: los 6 enums del área (tipo_marketing y estado_pago ya existen en el modelo base) y los catálogos
-- canales_marketing y proveedores_marketing con baja lógica, auditoría y fn_a6_set_actualizado_en.

CREATE TYPE categoria_canal          AS ENUM ('TRADICIONAL', 'DIGITAL', 'DIRECTO', 'EVENTOS');
CREATE TYPE tipo_proveedor_marketing AS ENUM ('AGENCIA', 'MEDIO', 'FREELANCER', 'PLATAFORMA_DIGITAL', 'ESTUDIO_MERCADO', 'OTRO');
CREATE TYPE estatus_campana          AS ENUM ('PLANEADA', 'ACTIVA', 'PAUSADA', 'FINALIZADA', 'CANCELADA');
CREATE TYPE estado_contacto          AS ENUM ('OBJETIVO', 'CONTACTADO', 'RESPONDIO', 'CONVERTIDO', 'NO_INTERESADO');
CREATE TYPE tipo_investigacion       AS ENUM ('ENCUESTA', 'FOCUS_GROUP', 'ANALISIS_MERCADO', 'BENCHMARKING_COMPETENCIA', 'ESTUDIO_SATISFACCION', 'OTRO');
CREATE TYPE estado_investigacion     AS ENUM ('PLANEADA', 'EN_CURSO', 'FINALIZADA', 'CANCELADA');

CREATE TABLE canales_marketing (
    id_canal       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL UNIQUE,
    categoria      categoria_canal NOT NULL,
    descripcion    TEXT,
    activo         BOOLEAN NOT NULL DEFAULT TRUE,                 -- baja lógica (RN-A6-06)
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- El área 1 ya es dueña de proveedores (mercancía); este es el catálogo de agencias, medios y plataformas
CREATE TABLE proveedores_marketing (
    id_proveedor_marketing INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    razon_social      VARCHAR(200) NOT NULL,
    rfc               VARCHAR(13),
    tipo_servicio     tipo_proveedor_marketing NOT NULL,
    contacto_nombre   VARCHAR(150),
    contacto_email    VARCHAR(150),
    contacto_telefono VARCHAR(20),
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RN-A6-09: actualizado_en lo mantiene la base; ninguna aplicación lo escribe
CREATE OR REPLACE FUNCTION fn_a6_set_actualizado_en() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.actualizado_en := NOW();
    RETURN NEW;
END; $$;
