import { supabase } from '@/lib/supabaseClient';
import { datos } from '@/lib/consulta';

// Área 6 · Lecturas de otras áreas. Solo lectura de clientes y productos y de sus vistas de contrato.

export async function listarClientesActivos() {
  return supabase.from('v_clientes_activos').select('*').then(datos);
}

export async function listarProductos() {
  return supabase
    .from('productos')
    .select('id_producto, nombre, sku, tipo')
    .eq('activo', true)
    .order('nombre')
    .then(datos);
}

export async function listarBajaRotacion() {
  return supabase.from('v_productos_baja_rotacion_campana').select('*').then(datos);
}

export async function listarDesempenoAgentes() {
  return supabase.from('v_desempeno_agente_zona').select('*').then(datos);
}
