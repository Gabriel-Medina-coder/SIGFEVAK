import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 1 · Entradas por compra directa (vía A). El servicio nunca manda stock, volumen, capital_inversion ni
// valor_entrada (RN-A1-03): los calcula el trigger del área 3 con la fórmula de I-01 (RN-A1-08).

export async function listarEntradas({ desde, hasta } = {}) {
  let q = supabase.from('v_entradas_detalle').select('*');
  if (desde) q = q.gte('fecha', desde);
  if (hasta) q = q.lte('fecha', hasta);
  return q.then(datos);
}

export async function listarDiscrepanciasRecepcion() {
  return supabase
    .from('v_discrepancias_recepcion')
    .select('*')
    .order('fecha', { ascending: false })
    .then(datos);
}

export async function listarReabastecimiento() {
  return supabase.from('v_reabastecimiento').select('*').then(datos);
}

// RN-A1-08: capital estimado en pesos, el mismo cálculo que hará el trigger
export function capitalEstimado({
  cantidad,
  costo_unitario,
  flete_unitario,
  impuestos_unitarios,
  tipo_cambio,
}) {
  const n = (v) => Number(v) || 0;
  return (
    (n(costo_unitario) + n(flete_unitario) + n(impuestos_unitarios)) *
    (n(tipo_cambio) || 1) *
    n(cantidad)
  );
}

export async function registrarEntrada(e) {
  const moneda = e.moneda || 'MXN';
  return supabase
    .from('entradas_producto')
    .insert(
      limpiar({
        id_producto: Number(e.id_producto),
        id_proveedor: e.id_proveedor ? Number(e.id_proveedor) : undefined,
        id_almacen: e.id_almacen ? Number(e.id_almacen) : undefined,
        fecha: e.fecha,
        cantidad: Number(e.cantidad),
        cantidad_esperada: e.cantidad_esperada ? Number(e.cantidad_esperada) : undefined,
        estado_mercancia: e.estado_mercancia,
        costo_unitario: Number(e.costo_unitario),
        flete_unitario: Number(e.flete_unitario) || 0,
        impuestos_unitarios: Number(e.impuestos_unitarios) || 0,
        moneda,
        tipo_cambio: moneda === 'MXN' ? 1 : Number(e.tipo_cambio),
        pais_origen: e.pais_origen?.trim(),
        numero_factura_proveedor: e.numero_factura_proveedor?.trim(),
        fecha_factura_proveedor: e.fecha_factura_proveedor,
        numero_orden_compra: e.numero_orden_compra?.trim(),
        documento_importacion_ref: e.documento_importacion_ref?.trim(),
        documento_ref: (e.numero_factura_proveedor || e.numero_orden_compra)?.trim(),
        responsable_recepcion: e.responsable_recepcion?.trim(),
        observaciones: e.observaciones?.trim(),
      })
    )
    .then(datos);
}
