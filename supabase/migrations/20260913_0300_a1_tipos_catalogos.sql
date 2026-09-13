-- Área 1 · Issue #23 · RN-A1-06
-- Qué hace: enums del área (estado_mercancia, tipo_almacen, estado_orden, resultado_calidad) y catálogos
-- proveedores y almacenes con RLS mínima.

CREATE TYPE estado_mercancia  AS ENUM ('BUEN_ESTADO', 'DANADO', 'INCOMPLETO');
CREATE TYPE tipo_almacen      AS ENUM ('INSUMOS', 'PRODUCTO_TERMINADO');
CREATE TYPE estado_orden      AS ENUM ('PLANEADA', 'EN_PROCESO', 'EN_CALIDAD', 'TERMINADA', 'CANCELADA');
CREATE TYPE resultado_calidad AS ENUM ('APROBADO', 'RECHAZADO');

CREATE TABLE proveedores (
    id_proveedor INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL UNIQUE,
    rfc          VARCHAR(13) UNIQUE,                 -- NULL para proveedores extranjeros
    pais         VARCHAR(60) NOT NULL DEFAULT 'México',
    contacto     VARCHAR(150),
    activo       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE almacenes (
    id_almacen INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre     VARCHAR(100) NOT NULL UNIQUE,
    tipo       tipo_almacen NOT NULL,               -- RN-A1-06: INSUMOS o PRODUCTO_TERMINADO
    ubicacion  VARCHAR(150),
    activo     BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE almacenes   ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_proveedores_auth ON proveedores FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_almacenes_auth   ON almacenes   FOR ALL TO authenticated USING (true) WITH CHECK (true);
