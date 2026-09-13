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

// Contrato con el área 1: volumen proyectado de manufactura (órdenes planeadas y en proceso) para no promocionar sin stock
export async function listarProduccionProyectada() {
  return supabase
    .from('v_ordenes_produccion')
    .select('folio, producto, estado, cantidad_planeada, fecha_fin_programada')
    .in('estado', ['PLANEADA', 'EN_PROCESO', 'EN_CALIDAD'])
    .order('fecha_fin_programada')
    .then(datos);
}

// Productos bajo su stock mínimo según el área 1: no conviene promocionarlos hasta reabastecer
export async function listarBajoStockMinimo() {
  return supabase
    .from('v_reabastecimiento')
    .select('sku, nombre, stock, stock_minimo, faltante')
    .then(datos);
}
