import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';

// Área 6 · Campañas. Gasto, restante, % ejercido y ROI salen de las vistas; nunca se escriben (RN-A6-11, RN-A6-12).
// actualizado_en lo pone el trigger (RN-A6-09).

export function mensajeMarketing(error, contexto = {}) {
  const t = error?.message ?? '';
  const gasto = t.match(
    /RN-A6-03: el gasto total ([\d.]+) excede el presupuesto asignado ([\d.]+)/
  );
  if (gasto) {
    const restante = Number(gasto[2]) - (Number(gasto[1]) - Number(contexto.monto ?? 0));
    const texto = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(
      restante
    );
    return `El gasto excede el presupuesto de la campaña (restante: ${texto})`;
  }
  if (/RN-A6-02/.test(t)) return 'Solo las campañas directas tienen clientes objetivo';
  if (/RN-A6-15/.test(t))
    return 'Una campaña directa necesita al menos un cliente objetivo para activarse';
  if (/RN-A6-13/.test(t))
    return 'La campaña está finalizada o cancelada y no acepta registros nuevos';
  if (/ck_campana_fechas/.test(t)) return 'La fecha de fin no puede ser anterior a la de inicio';
  return null;
}

export async function listarResumenCampanas() {
  return supabase
    .from('v_campana_resumen')
    .select('*')
    .order('fecha_inicio', { ascending: false })
    .then(datos);
}

export async function obtenerCampana(id_campana) {
  return supabase.from('campanas').select('*').eq('id_campana', id_campana).single().then(uno);
}

export async function guardarCampana(c, id_usuario) {
  const fila = limpiar({
    nombre: c.nombre?.trim(),
    tipo_marketing: c.tipo_marketing,
    objetivo: c.objetivo?.trim() || null,
    descripcion: c.descripcion?.trim() || null,
    fecha_inicio: c.fecha_inicio,
    fecha_fin: c.fecha_fin || null,
    presupuesto_asignado: Number(c.presupuesto_asignado),
  });
  if (c.id_campana)
    return supabase.from('campanas').update(fila).eq('id_campana', c.id_campana).then(datos);
  return supabase
    .from('campanas')
    .insert({ ...fila, id_responsable: id_usuario, creado_por: id_usuario })
    .select('id_campana')
    .single()
    .then(uno);
}

// RN-A6-04: no se borra; se cancela. RN-A6-15: activar una DIRECTO exige clientes objetivo.
export async function cambiarEstatusCampana(id_campana, estatus) {
  return supabase.from('campanas').update({ estatus }).eq('id_campana', id_campana).then(datos);
}

export async function listarDesempenoDirecto() {
  return supabase.from('v_directo_desempeno').select('*').then(datos);
}

export async function listarVentasAtribuidas() {
  return supabase.from('v_ventas_atribuidas_campana').select('*').then(datos);
}

export async function listarClientesCampana(id_campana) {
  return supabase
    .from('campana_clientes')
    .select(
      'id_campana, id_cliente, id_canal, fecha_contacto, estado_contacto, notas, clientes(nombre_empresa, numero_comercializador, estado), canales_marketing(nombre)'
    )
    .eq('id_campana', id_campana)
    .then(datos);
}

export async function agregarClienteCampana(r) {
  return supabase
    .from('campana_clientes')
    .insert(
      limpiar({
        id_campana: r.id_campana,
        id_cliente: Number(r.id_cliente),
        id_canal: r.id_canal ? Number(r.id_canal) : undefined,
      })
    )
    .then(datos);
}

export async function actualizarContacto(id_campana, id_cliente, cambios) {
  return supabase
    .from('campana_clientes')
    .update(
      limpiar({
        estado_contacto: cambios.estado_contacto,
        fecha_contacto: cambios.fecha_contacto,
        notas: cambios.notas,
      })
    )
    .eq('id_campana', id_campana)
    .eq('id_cliente', id_cliente)
    .then(datos);
}

export async function listarProductosCampana(id_campana) {
  return supabase
    .from('campana_productos')
    .select('id_producto, productos(nombre, sku, tipo)')
    .eq('id_campana', id_campana)
    .then(datos);
}

export async function agregarProductoCampana(id_campana, id_producto) {
  return supabase
    .from('campana_productos')
    .insert({ id_campana, id_producto: Number(id_producto) })
    .then(datos);
}

export async function quitarProductoCampana(id_campana, id_producto) {
  return supabase
    .from('campana_productos')
    .delete()
    .eq('id_campana', id_campana)
    .eq('id_producto', id_producto)
    .then(datos);
}
