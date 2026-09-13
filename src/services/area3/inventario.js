import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';

// Área 3 · Inventario. Ningún servicio envía stock, volumen, capital_inversion ni valor_entrada (RN-A3-06):
// los mueven los triggers de entrada, salida y ajuste.

export async function obtenerInventario() {
  const [inventario, skus] = await Promise.all([
    supabase.from('v_inventario_actual').select('*').then(datos),
    supabase.from('productos').select('id_producto, sku, stock_minimo').then(datos),
  ]);
  const porId = Object.fromEntries(skus.map((s) => [s.id_producto, s]));
  return inventario.map((p) => ({
    ...p,
    sku: porId[p.id_producto]?.sku ?? null,
    stock_minimo: porId[p.id_producto]?.stock_minimo ?? 0,
  }));
}

export async function crearProducto({ tipo, nombre, sku, stock_minimo }) {
  return supabase
    .from('productos')
    .insert(limpiar({ tipo, nombre: nombre.trim(), sku: sku?.trim() || undefined, stock_minimo }))
    .select('id_producto')
    .single()
    .then(uno);
}

export async function editarProducto(id_producto, { nombre, tipo, sku, stock_minimo, activo }) {
  return supabase
    .from('productos')
    .update(
      limpiar({ nombre: nombre?.trim(), tipo, sku: sku?.trim() || null, stock_minimo, activo })
    )
    .eq('id_producto', id_producto)
    .then(datos);
}

export async function obtenerKardex({ idProducto, desde, hasta } = {}) {
  let q = supabase.from('v_kardex').select('*');
  if (idProducto) q = q.eq('id_producto', idProducto);
  if (desde) q = q.gte('fecha', desde);
  if (hasta) q = q.lte('fecha', hasta);
  return q.order('fecha', { ascending: true }).then(datos);
}

export async function obtenerRotacion() {
  return supabase.from('v_rotacion').select('*').then(datos);
}

export async function obtenerDiscrepancias() {
  return supabase
    .from('v_discrepancias')
    .select('*')
    .order('fecha', { ascending: false })
    .then(datos);
}

// RN-A3-07: stock_sistema lo congela el trigger; si el conteo coincide no se registra ajuste.
export async function registrarAjuste({
  id_producto,
  conteo_fisico,
  motivo,
  responsable,
  stockSistema,
}) {
  if (Number(conteo_fisico) === Number(stockSistema)) return { sinDiferencia: true };
  await supabase
    .from('ajustes_inventario')
    .insert(limpiar({ id_producto, conteo_fisico: Number(conteo_fisico), motivo, responsable }))
    .then(datos);
  return { sinDiferencia: false };
}

// Entrada simple desde el área 3 (RN-A3-04). La captura completa con proveedor y almacén está en el módulo del área 1.
export async function registrarEntrada({
  id_producto,
  cantidad,
  costo_unitario,
  proveedor,
  documento_ref,
}) {
  return supabase
    .from('entradas_producto')
    .insert(
      limpiar({
        id_producto,
        cantidad: Number(cantidad),
        costo_unitario: Number(costo_unitario),
        proveedor,
        documento_ref,
      })
    )
    .then(datos);
}
