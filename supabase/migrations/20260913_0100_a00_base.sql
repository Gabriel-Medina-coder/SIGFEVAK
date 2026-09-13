-- Área 00 (coordinación) · Base compartida · docs/MODELO_DATOS.md
-- Qué hace: enums compartidos, tabla usuarios (espejo de Supabase Auth con rol) y las tablas base del
-- modelo aprobado: clientes, agentes_ventas, facturas. RLS mínima para authenticated.
-- Reglas: D-02 (una sola base, fronteras lógicas), D-09 (nunca editar esta migración; cambios en archivo nuevo).
-- detalle_factura se crea en la migración del área 3 porque referencia a productos.
-- marketing y clientes_marketing NO se crean: el área 6 trae su diseño (I-09).

-- ---------- ENUMS COMPARTIDOS ----------
CREATE TYPE tipo_producto  AS ENUM ('ELECTRONICO', 'MANUFACTURA');
CREATE TYPE tipo_marketing AS ENUM ('EXTERNO', 'DIRECTO');
CREATE TYPE estado_pago    AS ENUM ('PENDIENTE', 'PARCIAL', 'PAGADO', 'CANCELADO');
CREATE TYPE tipo_permiso   AS ENUM ('LICENCIA', 'PERMISO', 'ADUANAL', 'IMPUESTO');
CREATE TYPE rol_usuario    AS ENUM (
    'ADMINISTRADOR', 'CONTADOR', 'COMERCIO_EXTERIOR', 'AUTORIZADOR',
    'GERENTE_VENTAS', 'ALMACEN', 'MARKETING', 'CAPTURISTA'
);

-- ---------- USUARIOS (espejo de auth.users con rol) ----------
CREATE TABLE usuarios (
    id_usuario UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre     VARCHAR(150) NOT NULL,
    correo     VARCHAR(150) NOT NULL UNIQUE,
    rol        rol_usuario NOT NULL DEFAULT 'CAPTURISTA',
    area       SMALLINT CHECK (area BETWEEN 1 AND 6),
    activo     BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE usuarios IS 'Rol y área de cada cuenta de Supabase Auth. Las cuentas se crean a mano; el registro público está cerrado.';

-- Rol del usuario autenticado, para políticas y triggers de separación de funciones.
CREATE OR REPLACE FUNCTION fn_rol_actual()
RETURNS rol_usuario LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT rol FROM usuarios WHERE id_usuario = auth.uid();
$$;

-- Nombre del usuario autenticado, para columnas de auditoría (calculado_por, autorizado_por, responsable).
CREATE OR REPLACE FUNCTION fn_usuario_actual()
RETURNS VARCHAR LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT COALESCE((SELECT nombre FROM usuarios WHERE id_usuario = auth.uid()), 'sistema');
$$;

-- ---------- TABLAS BASE DEL MODELO APROBADO ----------
CREATE TABLE clientes (
    id_cliente     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_empresa VARCHAR(150) NOT NULL,
    rfc            VARCHAR(20) UNIQUE,
    estado         VARCHAR(50)
);

CREATE TABLE agentes_ventas (
    id_agente   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    sueldo_base DECIMAL(10,2),
    comision    DECIMAL(5,2)
);

CREATE TABLE facturas (
    id_factura  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente  INT NOT NULL REFERENCES clientes(id_cliente),
    id_agente   INT NOT NULL REFERENCES agentes_ventas(id_agente),
    fecha       DATE NOT NULL DEFAULT CURRENT_DATE,
    valor_total DECIMAL(14,2) DEFAULT 0,
    iva         DECIMAL(12,2) DEFAULT 0,
    estado_pago estado_pago NOT NULL DEFAULT 'PENDIENTE'
);
CREATE INDEX ix_facturas_cliente ON facturas(id_cliente);
CREATE INDEX ix_facturas_agente  ON facturas(id_agente);
CREATE INDEX ix_facturas_fecha   ON facturas(fecha);

-- ---------- RLS MÍNIMA (política del proyecto: authenticated lee y escribe) ----------
ALTER TABLE usuarios       ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE agentes_ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE facturas       ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_usuarios_lectura ON usuarios FOR SELECT TO authenticated USING (true);
CREATE POLICY p_usuarios_admin   ON usuarios FOR ALL    TO authenticated
    USING (fn_rol_actual() = 'ADMINISTRADOR') WITH CHECK (fn_rol_actual() = 'ADMINISTRADOR');
CREATE POLICY p_clientes_auth       ON clientes       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_agentes_auth        ON agentes_ventas FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY p_facturas_auth       ON facturas       FOR ALL TO authenticated USING (true) WITH CHECK (true);
