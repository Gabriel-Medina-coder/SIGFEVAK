import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';

// Área 5 · Obligaciones fiscales. Cada cambio de estado pasa por una acción de este archivo y la base valida el
// orden, la separación de funciones y la conciliación (RN-A5-04, RN-A5-05, RN-A5-06, RN-A5-18, RN-A5-19, RN-A5-23).

export const ROLES_AUTORIZA = ['AUTORIZADOR', 'ADMINISTRADOR'];

// Mensajes legibles para los errores del área (docs/area5-fiscal/TAREAS.md tarea 17)
export function mensajeFiscal(error) {
  const t = error?.message ?? '';
  const transicion = t.match(/RN-A5-19: transición (\w+) a (\w+) no permitida/);
  if (transicion) return `Esta obligación no puede pasar de ${transicion[1]} a ${transicion[2]}.`;
  if (/RN-A5-18|ck_separacion_funciones|ck_pago_separacion/.test(t))
    return 'Quien registró no puede autorizar.';
  if (/RN-A5-24/.test(t)) return 'La obligación está cerrada y no se puede modificar.';
  return null;
}

export async function obtenerResumenFiscal() {
  return supabase.from('v_resumen_fiscal').select('*').maybeSingle().then(uno);
}

export async function listarObligaciones() {
  return supabase
    .from('obligaciones')
    .select(
      'id_obligacion, periodo, fecha_vencimiento, monto_estimado, monto_final, estado, entidad, id_responsable, id_autorizador, fecha_cierre, tipos_obligacion(clave, nombre, critica, frecuencia, instituciones(siglas, nombre))'
    )
    .eq('activo', true)
    .order('fecha_vencimiento', { ascending: true })
    .then(datos)
    .then(ordenarPorAtencion);
}

// Primero lo que falta atender (por vencimiento, la más próxima arriba); después lo pagado y cerrado, lo más reciente arriba
const ATENDIDAS = ['PAGADO', 'CONCILIADO', 'CERRADO'];
function ordenarPorAtencion(lista) {
  const abiertas = lista.filter((o) => !ATENDIDAS.includes(o.estado));
  const atendidas = lista.filter((o) => ATENDIDAS.includes(o.estado)).reverse();
  return [...abiertas, ...atendidas];
}

export async function listarCalendario() {
  return supabase.from('v_calendario_fiscal').select('*').order('fecha_vencimiento').then(datos);
}

export async function listarAlertasActivas() {
  return supabase.from('v_alertas_activas').select('*').then(datos);
}

export async function atenderAlerta(id_alerta) {
  return supabase
    .from('alertas')
    .update({ estado_envio: 'ATENDIDA' })
    .eq('id_alerta', id_alerta)
    .then(datos);
}

export async function obtenerObligacion(id_obligacion) {
  return supabase
    .from('obligaciones')
    .select(
      '*, tipos_obligacion(clave, nombre, critica, instituciones(siglas, nombre, portal_url)), declaraciones(*), pagos_obligacion(*), documentos_fiscales(*)'
    )
    .eq('id_obligacion', id_obligacion)
    .single()
    .then(uno);
}

async function actualizar(id_obligacion, cambios) {
  return supabase
    .from('obligaciones')
    .update(cambios)
    .eq('id_obligacion', id_obligacion)
    .then(datos);
}

// PENDIENTE → CALCULADO
export async function calcularObligacion(obligacion, monto, id_usuario) {
  return actualizar(obligacion.id_obligacion, {
    estado: 'CALCULADO',
    monto_estimado: Number(monto),
    id_responsable: obligacion.id_responsable ?? id_usuario,
  });
}

// CALCULADO → PRESENTADO con su declaración (RF-06)
export async function presentarDeclaracion(id_obligacion, d) {
  await supabase
    .from('declaraciones')
    .insert(
      limpiar({
        id_obligacion,
        tipo_declaracion: d.tipo_declaracion,
        numero_operacion: d.numero_operacion?.trim(),
        folio: d.folio?.trim(),
        fecha_presentacion: d.fecha_presentacion,
        importe_declarado: Number(d.importe_declarado),
      })
    )
    .then(datos);
  return actualizar(id_obligacion, { estado: 'PRESENTADO' });
}

// PRESENTADO → LINEA_GENERADA (RF-07)
export async function registrarLineaCaptura(
  id_obligacion,
  id_declaracion,
  { linea_captura, fecha_limite_pago }
) {
  await supabase
    .from('declaraciones')
    .update({ linea_captura: linea_captura.trim(), fecha_limite_pago: fecha_limite_pago || null })
    .eq('id_declaracion', id_declaracion)
    .then(datos);
  return actualizar(id_obligacion, { estado: 'LINEA_GENERADA' });
}

// LINEA_GENERADA → AUTORIZADO; el monto final se congela en la base (RN-A5-23)
export async function autorizarObligacion(id_obligacion, id_usuario) {
  return actualizar(id_obligacion, { estado: 'AUTORIZADO', id_autorizador: id_usuario });
}

// Rechazo del autorizador: regresa a CALCULADO con comentario (RN-A5-19)
export async function rechazarObligacion(id_obligacion, comentario) {
  return actualizar(id_obligacion, { estado: 'CALCULADO', comentario });
}

// AUTORIZADO o VENCIDO → PAGADO: pago con referencia y comprobante (RN-A5-04, RN-A5-07). Sin banco (D-04).
export async function registrarPago(obligacion, p, id_usuario) {
  const autorizo =
    obligacion.id_autorizador && obligacion.id_autorizador !== id_usuario
      ? obligacion.id_autorizador
      : null;
  const pago = await supabase
    .from('pagos_obligacion')
    .insert(
      limpiar({
        id_obligacion: obligacion.id_obligacion,
        fecha_pago: p.fecha_pago,
        monto: Number(p.monto),
        banco: p.banco?.trim(),
        referencia: p.referencia.trim(),
        linea_captura: p.linea_captura?.trim(),
        metodo_pago: p.metodo_pago,
        id_registrado_por: id_usuario,
        id_autorizado_por: autorizo ?? undefined,
      })
    )
    .select('id_pago')
    .single()
    .then(uno);
  await supabase
    .from('documentos_fiscales')
    .insert({
      id_obligacion: obligacion.id_obligacion,
      id_pago: pago.id_pago,
      tipo_documento: 'COMPROBANTE_BANCARIO',
      nombre: p.comprobante_nombre.trim(),
      referencia: p.comprobante_referencia.trim(),
    })
    .then(datos);
  // Una obligación VENCIDO que se paga con recargos toma como monto final lo pagado
  const cambios =
    obligacion.estado === 'VENCIDO'
      ? { estado: 'PAGADO', monto_final: Number(p.monto) }
      : { estado: 'PAGADO' };
  return actualizar(obligacion.id_obligacion, cambios);
}

export async function conciliarObligacion(id_obligacion) {
  return actualizar(id_obligacion, { estado: 'CONCILIADO' });
}

export async function cerrarObligacion(id_obligacion) {
  return actualizar(id_obligacion, { estado: 'CERRADO' });
}

export async function agregarDocumento(id_obligacion, d) {
  return supabase
    .from('documentos_fiscales')
    .insert({
      id_obligacion,
      tipo_documento: d.tipo_documento,
      nombre: d.nombre.trim(),
      referencia: d.referencia.trim(),
    })
    .then(datos);
}

// Funciones diarias (RN-A5-16, RN-A5-21) y generación del periodo (RF-04)
export async function ejecutarFuncionesDiarias() {
  const llamar = async (fn) => {
    const { data, error } = await supabase.rpc(fn);
    if (error) throw error;
    return data;
  };
  const vencidas = await llamar('fn_marcar_vencidas');
  const alertas = await llamar('fn_generar_alertas');
  const licencias = await llamar('fn_actualizar_estado_licencias');
  return { vencidas, alertas, licencias };
}

export async function generarObligacionesPeriodo(periodo) {
  const { data, error } = await supabase.rpc('fn_generar_obligaciones_periodo', {
    p_periodo: periodo,
  });
  if (error) throw error;
  return data;
}

export async function listarPagosPorInstitucion() {
  return supabase.from('v_pagos_por_institucion').select('*').then(datos);
}
