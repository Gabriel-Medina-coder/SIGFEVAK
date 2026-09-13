import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';
import { periodoActual } from '@/lib/formato';

// Área 2 · Facturas. Ningún servicio manda subtotal, iva, valor_total, fecha_cobro ni folio (RN-A2-02, RN-A2-08,
// RN-A2-11): los escriben los triggers. El stock lo descuenta el trigger del área 3 (RN-A2-06).

const COLUMNAS_FACTURA =
  'id_factura, folio, fecha, fecha_vencimiento, fecha_cobro, subtotal, iva, valor_total, estado_pago, uuid_cfdi, clientes(id_cliente, nombre_empresa, numero_comercializador), agentes_ventas(id_agente, nombre)';

// Todas las facturas, más recientes primero. Solo para exportar (con muchos datos, la tabla usa paginaFacturas).
export async function listarFacturas() {
  return supabase
    .from('facturas')
    .select(COLUMNAS_FACTURA)
    .order('fecha', { ascending: false })
    .order('id_factura', { ascending: false })
    .then(datos);
}

// Una página de facturas desde el servidor, para no traer miles de filas al cliente. Devuelve { filas, total }.
export async function paginaFacturas({ pagina = 0, porPagina = 25 } = {}) {
  const desde = pagina * porPagina;
  const { data, count, error } = await supabase
    .from('facturas')
    .select(COLUMNAS_FACTURA, { count: 'exact' })
    .order('fecha', { ascending: false })
    .order('id_factura', { ascending: false })
    .range(desde, desde + porPagina - 1);
  if (error) throw error;
  return { filas: data ?? [], total: count ?? 0 };
}

// Cifras del tablero sin traer todas las facturas: facturación del mes (con IVA) y cuántas están por cobrar.
export async function resumenFacturacion() {
  const [mes, pendientes] = await Promise.all([
    supabase
      .from('v_iva_trasladado_periodo')
      .select('total, numero_facturas')
      .eq('periodo', periodoActual())
      .maybeSingle()
      .then(({ data, error }) => {
        if (error) throw error;
        return data;
      }),
    supabase
      .from('v_facturas_pendientes')
      .select('id_factura', { count: 'exact', head: true })
      .then(({ count, error }) => {
        if (error) throw error;
        return count ?? 0;
      }),
  ]);
  return {
    mesTotal: Number(mes?.total ?? 0),
    mesFacturas: Number(mes?.numero_facturas ?? 0),
    pendientes,
  };
}

export async function obtenerFactura(id_factura) {
  return supabase
    .from('facturas')
    .select(
      'id_factura, folio, fecha, fecha_vencimiento, fecha_cobro, subtotal, iva, valor_total, estado_pago, uuid_cfdi, clientes(nombre_empresa, numero_comercializador, rfc, dias_credito), agentes_ventas(nombre), detalle_factura(id_detalle, cantidad, precio_unitario, importe, productos(id_producto, nombre, sku))'
    )
    .eq('id_factura', id_factura)
    .single()
    .then(uno);
}

export async function listarAgentes() {
  return supabase
    .from('agentes_ventas')
    .select('id_agente, nombre, estatus')
    .order('nombre')
    .then(datos);
}

export async function listarProductosVenta() {
  return supabase
    .from('productos')
    .select('id_producto, nombre, sku, stock, precio_venta_sugerido, valor_entrada')
    .eq('activo', true)
    .order('nombre')
    .then(datos);
}

// RN-A2-01, RN-A2-09: cabecera con cliente y agente; folio y vencimiento los asigna la base
export async function crearFactura({ id_cliente, id_agente, fecha, fecha_vencimiento }) {
  return supabase
    .from('facturas')
    .insert(
      limpiar({
        id_cliente: Number(id_cliente),
        id_agente: Number(id_agente),
        fecha,
        fecha_vencimiento,
      })
    )
    .select('id_factura, folio, fecha_vencimiento')
    .single()
    .then(uno);
}

export async function agregarRenglon({ id_factura, id_producto, cantidad, precio_unitario }) {
  return supabase
    .from('detalle_factura')
    .insert({
      id_factura,
      id_producto: Number(id_producto),
      cantidad: Number(cantidad),
      precio_unitario: Number(precio_unitario),
    })
    .then(datos);
}

export async function eliminarRenglon(id_detalle) {
  return supabase.from('detalle_factura').delete().eq('id_detalle', id_detalle).then(datos);
}

// RN-A2-04, RN-A2-07, RN-A2-08: cambiar de estado; cancelar no borra ni reintegra stock
export async function cambiarEstadoPago(id_factura, estado_pago) {
  return supabase.from('facturas').update({ estado_pago }).eq('id_factura', id_factura).then(datos);
}

export async function listarPendientes({ cliente, desde, hasta } = {}) {
  let q = supabase.from('v_facturas_pendientes').select('*');
  if (cliente) q = q.eq('numero_comercializador', cliente);
  if (desde) q = q.gte('fecha', desde);
  if (hasta) q = q.lte('fecha', hasta);
  return q.then(datos);
}

export async function listarVentasPorAgente() {
  return supabase
    .from('v_ventas_agente')
    .select('*')
    .order('monto_vendido', { ascending: false })
    .then(datos);
}
