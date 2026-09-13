-- Área 00 · Coordinación · Seguridad (D-11) · RN-A3-06, RN-A4-15, RN-A5-18
-- Qué hace: cierra los huecos de control de acceso detectados en la auditoría OWASP. Con solo `authenticated` y
-- políticas `USING (true)`, cualquier usuario con sesión podía escribir en cualquier tabla, cambiar las tasas
-- legales/fiscales, mover el stock a mano y firmar pasos a nombre de otro. Aquí:
--   1. Las tablas de parámetros y catálogos (que definen el cálculo de dinero) solo las escribe ADMINISTRADOR.
--   2. `usuarios` deja de ser legible por todos: cada quien ve su fila; ADMINISTRADOR ve todas.
--   3. `productos.stock/volumen/capital/valor` solo se mueven por los triggers de inventario (RN-A3-06 en la base).
--   4. La separación de funciones de nómina y de obligaciones se ata al usuario realmente conectado (no a un
--      correo/uuid que mande el cliente). Los scripts y seeds (service_role, sin auth.uid()) no se ven afectados.
-- Las lecturas siguen abiertas a `authenticated` (las áreas se consultan entre sí por vistas de contrato).

-- ---------- Helper: correo del usuario conectado ----------
CREATE OR REPLACE FUNCTION fn_correo_actual()
RETURNS VARCHAR LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT correo FROM usuarios WHERE id_usuario = auth.uid();
$$;

-- ========== 1. Parámetros y catálogos: lectura abierta, escritura solo ADMINISTRADOR ==========
DO $$
DECLARE t TEXT; nombre TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['parametros_legales','parametros_fiscales','zonas','esquemas_compensacion',
                             'tramos_comision','bonos_catalogo','tipos_obligacion','instituciones','metas'] LOOP
        FOR nombre IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = t LOOP
            EXECUTE format('DROP POLICY %I ON public.%I', nombre, t);
        END LOOP;
        EXECUTE format('CREATE POLICY p_%s_sel   ON public.%I FOR SELECT TO authenticated USING (true)', t, t);
        EXECUTE format('CREATE POLICY p_%s_admin ON public.%I FOR ALL TO authenticated USING (fn_rol_actual() = ''ADMINISTRADOR'') WITH CHECK (fn_rol_actual() = ''ADMINISTRADOR'')', t, t);
    END LOOP;
END $$;

-- ========== 2. usuarios: cada quien su fila; ADMINISTRADOR todas ==========
DROP POLICY IF EXISTS p_usuarios_lectura ON usuarios;
CREATE POLICY p_usuarios_propia ON usuarios FOR SELECT TO authenticated
    USING (id_usuario = auth.uid() OR fn_rol_actual() = 'ADMINISTRADOR');
-- p_usuarios_admin (ALL para ADMINISTRADOR) se conserva de la migración base.

-- ========== 3. productos.stock solo por los triggers de inventario (RN-A3-06) ==========
-- Los tres triggers que sí mueven stock marcan una bandera de transacción antes de escribir.
CREATE OR REPLACE FUNCTION fn_entrada_producto() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    PERFORM set_config('sigfevak.mueve_stock', '1', true);
    UPDATE productos
       SET stock             = stock + NEW.cantidad,
           volumen           = volumen + NEW.cantidad,
           capital_inversion = capital_inversion
                               + NEW.cantidad * (NEW.costo_unitario + NEW.flete_unitario + NEW.impuestos_unitarios) * NEW.tipo_cambio,
           valor_entrada     = (NEW.costo_unitario + NEW.flete_unitario + NEW.impuestos_unitarios) * NEW.tipo_cambio
     WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION fn_salida_producto() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_stock INT; v_nombre VARCHAR;
BEGIN
    SELECT stock, nombre INTO v_stock, v_nombre FROM productos WHERE id_producto = NEW.id_producto FOR UPDATE;
    IF v_stock IS NULL THEN RAISE EXCEPTION 'RN-A3-02: el producto % no existe', NEW.id_producto; END IF;
    IF v_stock < NEW.cantidad THEN
        RAISE EXCEPTION 'RN-A3-01: stock insuficiente para "%" (disponible: %, solicitado: %)', v_nombre, v_stock, NEW.cantidad;
    END IF;
    PERFORM set_config('sigfevak.mueve_stock', '1', true);
    UPDATE productos SET stock = stock - NEW.cantidad WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION fn_ajuste_inventario() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    PERFORM set_config('sigfevak.mueve_stock', '1', true);
    UPDATE productos SET stock = NEW.conteo_fisico WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END; $$;

-- Guardia: un usuario con sesión no puede tocar stock/volumen/capital/valor por fuera de esos triggers.
CREATE OR REPLACE FUNCTION fn_guarda_stock() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF auth.uid() IS NOT NULL
       AND current_setting('sigfevak.mueve_stock', true) IS DISTINCT FROM '1'
       AND (NEW.stock IS DISTINCT FROM OLD.stock
            OR NEW.volumen IS DISTINCT FROM OLD.volumen
            OR NEW.capital_inversion IS DISTINCT FROM OLD.capital_inversion
            OR NEW.valor_entrada IS DISTINCT FROM OLD.valor_entrada) THEN
        RAISE EXCEPTION 'RN-A3-06: el stock, el volumen y el capital solo los mueven las entradas, salidas y ajustes';
    END IF;
    RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS tg_guarda_stock ON productos;
CREATE TRIGGER tg_guarda_stock BEFORE UPDATE ON productos
FOR EACH ROW EXECUTE FUNCTION fn_guarda_stock();

-- ========== 4. Separación de funciones atada al usuario conectado ==========
-- Nómina: quien registra un paso es quien lo ejecuta, y con el rol que corresponde (RN-A4-15).
CREATE OR REPLACE FUNCTION fn_identidad_periodo() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF auth.uid() IS NULL OR OLD.estatus = NEW.estatus THEN RETURN NEW; END IF;
    IF NEW.estatus = 'CALCULADO' THEN
        IF NEW.calculado_por IS DISTINCT FROM fn_correo_actual() OR fn_rol_actual() NOT IN ('CONTADOR','ADMINISTRADOR') THEN
            RAISE EXCEPTION 'RN-A4-15: el periodo lo calcula el propio contador o administrador conectado';
        END IF;
    ELSIF NEW.estatus = 'REVISADO' THEN
        IF NEW.revisado_por IS DISTINCT FROM fn_correo_actual() OR fn_rol_actual() NOT IN ('GERENTE_VENTAS','ADMINISTRADOR') THEN
            RAISE EXCEPTION 'RN-A4-15: la revisión la hace el propio gerente de ventas o administrador conectado';
        END IF;
    ELSIF NEW.estatus = 'AUTORIZADO' THEN
        IF NEW.autorizado_por IS DISTINCT FROM fn_correo_actual() OR fn_rol_actual() NOT IN ('AUTORIZADOR','ADMINISTRADOR') THEN
            RAISE EXCEPTION 'RN-A4-15: la autorización la hace el propio autorizador o administrador conectado';
        END IF;
    ELSIF NEW.estatus = 'ABIERTO' AND OLD.estatus = 'CALCULADO' THEN
        IF NEW.revisado_por IS DISTINCT FROM fn_correo_actual() OR fn_rol_actual() NOT IN ('GERENTE_VENTAS','ADMINISTRADOR') THEN
            RAISE EXCEPTION 'RN-A4-15: el rechazo lo hace el propio gerente de ventas o administrador conectado';
        END IF;
    END IF;
    RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS tg_identidad_periodo ON periodos_nomina;
CREATE TRIGGER tg_identidad_periodo BEFORE UPDATE ON periodos_nomina
FOR EACH ROW EXECUTE FUNCTION fn_identidad_periodo();

-- Obligaciones: autoriza el propio usuario, no en nombre de otro (RN-A5-18).
CREATE OR REPLACE FUNCTION fn_identidad_obligacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF auth.uid() IS NULL THEN RETURN NEW; END IF;
    IF NEW.estado = 'AUTORIZADO' AND OLD.estado IS DISTINCT FROM 'AUTORIZADO'
       AND NEW.id_autorizador IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'RN-A5-18: la obligación la autoriza el propio usuario conectado, no en nombre de otro';
    END IF;
    RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS tg_identidad_obligacion ON obligaciones;
CREATE TRIGGER tg_identidad_obligacion BEFORE UPDATE ON obligaciones
FOR EACH ROW EXECUTE FUNCTION fn_identidad_obligacion();

-- ---------- Funciones nuevas: sin ejecución para anon ni PUBLIC (D-11) ----------
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon, PUBLIC;
GRANT  EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;
