import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 6 · Costos de marketing. El trigger rechaza lo que exceda el presupuesto (RN-A6-03).

export async function listarCostos({ id_campana } = {}) {
  let q = supabase
    .from('costos_marketing')
    .select(
      'id_costo, id_campana, id_canal, id_proveedor_marketing, concepto, monto, fecha_gasto, estado_pago, campanas(nombre), canales_marketing(nombre), proveedores_marketing(razon_social)'
    )
    .order('fecha_gasto', { ascending: false });
  if (id_campana) q = q.eq('id_campana', id_campana);
  return q.then(datos);
}

export async function registrarCosto(c) {
  return supabase
    .from('costos_marketing')
    .insert(
      limpiar({
        id_campana: Number(c.id_campana),
        id_canal: Number(c.id_canal),
        id_proveedor_marketing: c.id_proveedor_marketing
          ? Number(c.id_proveedor_marketing)
          : undefined,
        concepto: c.concepto.trim(),
        monto: Number(c.monto),
        fecha_gasto: c.fecha_gasto,
        estado_pago: c.estado_pago,
      })
    )
    .then(datos);
}

export async function listarCostosPorCanal() {
  return supabase.from('v_costos_por_canal').select('*').then(datos);
}
