import { supabase } from '@/lib/supabaseClient';
import { datos, uno } from '@/lib/consulta';

// Área 4 · Periodos de nómina. El cálculo vive en la base (fn_calcular_periodo, fn_calcular_nomina) y la
// máquina de estados la valida fn_transicion_periodo (RN-A4-13, RN-A4-15, RN-A4-18).

// Quién hace cada paso (docs/area4-nomina/TAREAS.md tarea 18)
export const ROLES_PASO = {
  calcular: ['CONTADOR', 'ADMINISTRADOR'],
  revisar: ['GERENTE_VENTAS', 'ADMINISTRADOR'],
  autorizar: ['AUTORIZADOR', 'ADMINISTRADOR'],
  pagar: ['AUTORIZADOR', 'ADMINISTRADOR'],
};

export async function listarPeriodos() {
  return supabase
    .from('periodos_nomina')
    .select('*')
    .order('fecha_inicio', { ascending: false })
    .then(datos);
}

// Solo periodos MENSUAL en esta versión (RN-A4-17, pregunta abierta 8)
export async function abrirPeriodoMensual(periodo) {
  const [a, m] = periodo.split('-').map(Number);
  const inicio = `${periodo}-01`;
  const fin = new Date(Date.UTC(a, m, 0)).toISOString().slice(0, 10);
  return supabase
    .from('periodos_nomina')
    .insert({ tipo: 'MENSUAL', fecha_inicio: inicio, fecha_fin: fin })
    .select('id_periodo')
    .single()
    .then(uno);
}

export async function calcularPeriodo(id_periodo, correo) {
  const { error } = await supabase.rpc('fn_calcular_periodo', {
    p_id_periodo: id_periodo,
    p_usuario: correo,
  });
  if (error) throw error;
}

// Revisar deja el periodo en REVISADO y calcula ISR, IMSS y ajustes
export async function revisarPeriodo(id_periodo, correo) {
  await supabase
    .from('periodos_nomina')
    .update({ estatus: 'REVISADO', revisado_por: correo })
    .eq('id_periodo', id_periodo)
    .then(datos);
  const { error } = await supabase.rpc('fn_calcular_nomina', { p_id_periodo: id_periodo });
  if (error) throw error;
}

// Reintento del cálculo de ISR, IMSS y ajustes para un periodo ya REVISADO
export async function recalcularNomina(id_periodo) {
  const { error } = await supabase.rpc('fn_calcular_nomina', { p_id_periodo: id_periodo });
  if (error) throw error;
}

// RN-A4-13: regresar a ABIERTO exige comentario
export async function rechazarPeriodo(id_periodo, correo, comentario) {
  return supabase
    .from('periodos_nomina')
    .update({ estatus: 'ABIERTO', comentario, revisado_por: correo })
    .eq('id_periodo', id_periodo)
    .then(datos);
}

// RN-A4-15: la base rechaza si quien autoriza es quien calculó
export async function autorizarPeriodo(id_periodo, correo) {
  return supabase
    .from('periodos_nomina')
    .update({ estatus: 'AUTORIZADO', autorizado_por: correo })
    .eq('id_periodo', id_periodo)
    .then(datos);
}

export async function pagarPeriodo(id_periodo, fecha_pago) {
  return supabase
    .from('periodos_nomina')
    .update({ estatus: 'PAGADO', fecha_pago })
    .eq('id_periodo', id_periodo)
    .then(datos);
}

export async function cerrarPeriodo(id_periodo) {
  return supabase
    .from('periodos_nomina')
    .update({ estatus: 'CERRADO' })
    .eq('id_periodo', id_periodo)
    .then(datos);
}

export async function obtenerTotales(id_periodo) {
  return supabase
    .from('v_nomina_totales')
    .select('*')
    .eq('id_periodo', id_periodo)
    .order('neto', { ascending: false })
    .then(datos);
}

export async function obtenerRecibo(id_periodo, id_agente) {
  return supabase
    .from('v_recibo_nomina')
    .select('*')
    .eq('id_periodo', id_periodo)
    .eq('id_agente', id_agente)
    .then(datos);
}

export async function obtenerDesempeno(periodo) {
  let q = supabase.from('v_desempeno_agente_zona').select('*');
  if (periodo) q = q.eq('periodo', periodo);
  return q.then(datos);
}

export async function obtenerRetenciones(id_periodo) {
  return supabase.from('v_retenciones_area5').select('*').eq('id_periodo', id_periodo).then(datos);
}

// I-06: mano de obra directa por orden terminada que publica el área 1; insumo futuro de bonos de productividad,
// solo lectura y sin cambiar el cálculo actual (tarea 3 del área)
export async function obtenerManoObraProduccion(periodo) {
  let q = supabase.from('v_mano_obra_produccion').select('*');
  if (periodo) q = q.eq('periodo', periodo);
  return q.order('fecha_fin_real', { ascending: false }).then(datos);
}
