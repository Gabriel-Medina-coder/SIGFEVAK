-- Área 6 · Issues #111, #112 · RN-A6-02, RN-A6-03, RN-A6-13, RN-A6-15
-- Qué hace: triggers de presupuesto (los costos no exceden lo asignado), de campaña directa (solo DIRECTO
-- acepta clientes objetivo), de campaña cerrada (sin costos ni métricas nuevos) y de activación (una DIRECTO
-- no se activa sin clientes).

-- RN-A6-02
CREATE OR REPLACE FUNCTION fn_a6_validar_campana_directa() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_tipo tipo_marketing;
BEGIN
    SELECT tipo_marketing INTO v_tipo FROM campanas WHERE id_campana = NEW.id_campana;
    IF v_tipo IS DISTINCT FROM 'DIRECTO' THEN
        RAISE EXCEPTION 'RN-A6-02: la campaña % no es de tipo DIRECTO; no se pueden asignar clientes objetivo', NEW.id_campana;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_campana_clientes_valida_tipo BEFORE INSERT ON campana_clientes
FOR EACH ROW EXECUTE FUNCTION fn_a6_validar_campana_directa();

-- RN-A6-03: FOR UPDATE bloquea la campaña para que dos costos simultáneos no pasen con el mismo saldo
CREATE OR REPLACE FUNCTION fn_a6_validar_presupuesto() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_presupuesto DECIMAL(14,2); v_gasto DECIMAL(14,2);
BEGIN
    SELECT presupuesto_asignado INTO v_presupuesto FROM campanas WHERE id_campana = NEW.id_campana FOR UPDATE;
    SELECT COALESCE(SUM(monto), 0) INTO v_gasto FROM costos_marketing WHERE id_campana = NEW.id_campana;
    IF v_gasto > v_presupuesto THEN
        RAISE EXCEPTION 'RN-A6-03: el gasto total % excede el presupuesto asignado % de la campaña %',
            v_gasto, v_presupuesto, NEW.id_campana;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_costos_mkt_valida_presupuesto AFTER INSERT OR UPDATE ON costos_marketing
FOR EACH ROW EXECUTE FUNCTION fn_a6_validar_presupuesto();

-- RN-A6-13
CREATE OR REPLACE FUNCTION fn_a6_bloquea_campana_cerrada() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_estatus estatus_campana;
BEGIN
    SELECT estatus INTO v_estatus FROM campanas WHERE id_campana = NEW.id_campana;
    IF v_estatus IN ('FINALIZADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'RN-A6-13: la campaña % está %; no acepta registros nuevos', NEW.id_campana, v_estatus;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_costos_mkt_campana_cerrada BEFORE INSERT ON costos_marketing
FOR EACH ROW EXECUTE FUNCTION fn_a6_bloquea_campana_cerrada();
CREATE TRIGGER tg_metricas_mkt_campana_cerrada BEFORE INSERT ON metricas_marketing
FOR EACH ROW EXECUTE FUNCTION fn_a6_bloquea_campana_cerrada();

-- RN-A6-15
CREATE OR REPLACE FUNCTION fn_a6_valida_activacion() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.estatus = 'ACTIVA' AND NEW.tipo_marketing = 'DIRECTO'
       AND NOT EXISTS (SELECT 1 FROM campana_clientes WHERE id_campana = NEW.id_campana) THEN
        RAISE EXCEPTION 'RN-A6-15: la campaña DIRECTO % no tiene clientes objetivo; no se puede activar', NEW.id_campana;
    END IF;
    RETURN NEW;
END; $$;
CREATE TRIGGER tg_campanas_valida_activacion BEFORE UPDATE OF estatus ON campanas
FOR EACH ROW EXECUTE FUNCTION fn_a6_valida_activacion();
