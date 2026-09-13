import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 1 · Catálogos de proveedores, almacenes y materias primas (RN-A1-06). Baja lógica con `activo`.

export async function listarProveedores({ soloActivos = false } = {}) {
  let q = supabase.from('proveedores').select('*').order('nombre');
  if (soloActivos) q = q.eq('activo', true);
  return q.then(datos);
}

export async function guardarProveedor(proveedor) {
  const fila = limpiar({
    nombre: proveedor.nombre?.trim(),
    rfc: proveedor.rfc?.trim().toUpperCase() || null,
    pais: proveedor.pais?.trim(),
    contacto: proveedor.contacto?.trim() || null,
    activo: proveedor.activo,
  });
  const q = proveedor.id_proveedor
    ? supabase.from('proveedores').update(fila).eq('id_proveedor', proveedor.id_proveedor)
    : supabase.from('proveedores').insert(fila);
  return q.then(datos);
}

export async function listarAlmacenes({ tipo, soloActivos = false } = {}) {
  let q = supabase.from('almacenes').select('*').order('nombre');
  if (tipo) q = q.eq('tipo', tipo);
  if (soloActivos) q = q.eq('activo', true);
  return q.then(datos);
}

export async function guardarAlmacen(almacen) {
  const fila = limpiar({
    nombre: almacen.nombre?.trim(),
    tipo: almacen.tipo,
    ubicacion: almacen.ubicacion?.trim() || null,
    activo: almacen.activo,
  });
  const q = almacen.id_almacen
    ? supabase.from('almacenes').update(fila).eq('id_almacen', almacen.id_almacen)
    : supabase.from('almacenes').insert(fila);
  return q.then(datos);
}

export async function listarMateriasPrimas() {
  return supabase
    .from('materias_primas')
    .select(
      'id_materia, sku, nombre, unidad_medida, costo_unitario, stock, id_almacen, almacenes(nombre), proveedores(nombre)'
    )
    .order('nombre')
    .then(datos);
}

// La materia prima nace con stock 0; lo suben las entradas (RN-A1-09).
export async function crearMateriaPrima(m) {
  return supabase
    .from('materias_primas')
    .insert(
      limpiar({
        sku: m.sku?.trim().toUpperCase(),
        nombre: m.nombre?.trim(),
        unidad_medida: m.unidad_medida,
        id_almacen: Number(m.id_almacen),
        id_proveedor: m.id_proveedor ? Number(m.id_proveedor) : undefined,
      })
    )
    .then(datos);
}

export async function registrarEntradaMateria(e) {
  return supabase
    .from('entradas_materia_prima')
    .insert(
      limpiar({
        id_materia: Number(e.id_materia),
        cantidad: Number(e.cantidad),
        costo_unitario: Number(e.costo_unitario),
        id_proveedor: e.id_proveedor ? Number(e.id_proveedor) : undefined,
        documento_ref: e.documento_ref?.trim(),
      })
    )
    .then(datos);
}

export async function listarProductos() {
  return supabase
    .from('productos')
    .select('id_producto, nombre, sku, tipo, activo, stock, precio_venta_sugerido')
    .eq('activo', true)
    .order('nombre')
    .then(datos);
}
