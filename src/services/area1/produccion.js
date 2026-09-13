import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';

// Área 1 · Manufactura (vía B). Estados, consumo, calidad y cierre los validan los triggers (RN-A1-09 a RN-A1-17).

export async function listarOrdenes() {
  const [vista, base] = await Promise.all([
    supabase.from('v_ordenes_produccion').select('*').then(datos),
    supabase.from('ordenes_produccion').select('id_orden, id_producto_destino').then(datos),
  ]);
  const producto = Object.fromEntries(base.map((o) => [o.id_orden, o.id_producto_destino]));
  return vista
    .map((o) => ({ ...o, id_producto_destino: producto[o.id_orden] }))
    .sort((a, b) => b.id_orden - a.id_orden);
}

export async function listarCapitalEnProceso() {
  return supabase.from('v_capital_en_proceso').select('*').then(datos);
}

// Productos que ya tienen lista de materiales (RN-A1-10) con su BOM
export async function listarProductosConBom() {
  const filas = await supabase
    .from('bom')
    .select(
      'id_producto_destino, cantidad_por_unidad, materias_primas(id_materia, nombre, sku, unidad_medida, costo_unitario, stock), productos(id_producto, nombre, sku)'
    )
    .then(datos);
  const porProducto = {};
  for (const f of filas) {
    porProducto[f.id_producto_destino] ??= { ...f.productos, bom: [] };
    porProducto[f.id_producto_destino].bom.push({
      ...f.materias_primas,
      cantidad_por_unidad: Number(f.cantidad_por_unidad),
    });
  }
  return Object.values(porProducto);
}

export async function obtenerConsumos(id_orden) {
  return supabase
    .from('consumo_produccion')
    .select(
      'id_consumo, cantidad_real, merma, motivo_merma, fecha, turno, materias_primas(nombre, unidad_medida)'
    )
    .eq('id_orden', id_orden)
    .order('id_consumo')
    .then(datos);
}

async function siguienteFolio() {
  const anio = new Date().getFullYear();
  const ultimos = await supabase
    .from('ordenes_produccion')
    .select('folio')
    .like('folio', `OP-${anio}-%`)
    .order('folio', { ascending: false })
    .limit(1)
    .then(datos);
  const n = ultimos.length ? Number(ultimos[0].folio.split('-')[2]) + 1 : 1;
  return `OP-${anio}-${String(n).padStart(4, '0')}`;
}

export async function crearOrden(o) {
  return supabase
    .from('ordenes_produccion')
    .insert({
      folio: await siguienteFolio(),
      id_producto_destino: Number(o.id_producto_destino),
      cantidad_planeada: Number(o.cantidad_planeada),
      fecha_inicio_programada: o.fecha_inicio_programada,
      fecha_fin_programada: o.fecha_fin_programada,
      responsable: o.responsable.trim(),
    })
    .select('id_orden, folio')
    .single()
    .then(uno);
}

// RN-A1-11: el trigger rechaza cualquier transición fuera de orden
export async function cambiarEstadoOrden(id_orden, estado, extra = {}) {
  return supabase
    .from('ordenes_produccion')
    .update(
      limpiar({
        estado,
        costo_mano_obra:
          extra.costo_mano_obra !== undefined ? Number(extra.costo_mano_obra) : undefined,
        costos_indirectos:
          extra.costos_indirectos !== undefined ? Number(extra.costos_indirectos) : undefined,
      })
    )
    .eq('id_orden', id_orden)
    .then(datos);
}

export async function capturarConsumo(c) {
  return supabase
    .from('consumo_produccion')
    .insert(
      limpiar({
        id_orden: c.id_orden,
        id_materia: Number(c.id_materia),
        cantidad_real: Number(c.cantidad_real),
        merma: Number(c.merma) || 0,
        motivo_merma: c.motivo_merma?.trim(),
        turno: c.turno?.trim(),
      })
    )
    .then(datos);
}

// RN-A1-15, RN-A1-16: el resultado APROBADO o RECHAZADO lo pone el trigger
export async function registrarCalidad(q) {
  return supabase
    .from('control_calidad')
    .insert(
      limpiar({
        id_orden: q.id_orden,
        aprobadas: Number(q.aprobadas),
        rechazadas: Number(q.rechazadas) || 0,
        motivo_rechazo: q.motivo_rechazo?.trim(),
        responsable: q.responsable.trim(),
        resultado: 'APROBADO',
      })
    )
    .then(datos);
}
