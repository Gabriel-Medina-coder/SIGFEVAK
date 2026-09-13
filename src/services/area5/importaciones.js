import { supabase } from '@/lib/supabaseClient';
import { datos, uno, limpiar } from '@/lib/consulta';
import { hoyIso } from '@/lib/formato';

// Área 5 · Importaciones y licencias. IGI, DTA e IVA de importación los calcula la base con parametros_fiscales
// (RN-A5-12, RN-A5-13); el frontend nunca los calcula.

export async function listarImportaciones() {
  return supabase
    .from('importaciones')
    .select(
      '*, obligaciones(id_obligacion, estado, fecha_vencimiento), productos_importados(id_producto_importado, nombre, marca, modelo, cantidad, valor_unitario, valor_total, fraccion_arancelaria, nico, tasa_igi, igi_producto)'
    )
    .order('fecha_importacion', { ascending: false })
    .then(datos);
}

export async function listarEntradasImportacion() {
  return supabase
    .from('v_entradas_importacion')
    .select(
      'id_entrada, fecha, sku, nombre, proveedor, pais_origen, documento_importacion_ref, valor_mercancia_mxn'
    )
    .then(datos);
}

export async function listarImpuestosPorProducto() {
  return supabase.from('v_impuestos_importacion_producto').select('*').then(datos);
}

// RN-A5-20: solo la tasa vigente hoy de cada fracción; las de años anteriores quedan para el histórico
export async function listarFraccionesConTasa() {
  const hoy = hoyIso();
  return supabase
    .from('parametros_fiscales')
    .select('fraccion, valor, fuente')
    .eq('clave', 'TASA_IGI')
    .lte('vigencia_inicio', hoy)
    .or(`vigencia_fin.is.null,vigencia_fin.gte.${hoy}`)
    .order('fraccion')
    .then(datos);
}

export async function listarProductosCatalogo() {
  return supabase
    .from('productos')
    .select('id_producto, nombre, sku')
    .eq('activo', true)
    .order('nombre')
    .then(datos);
}

// RN-A5-08: cada importación nace con su obligación de tipo PEDIMENTO
export async function registrarImportacion(imp, productos, id_usuario) {
  const tipo = await supabase
    .from('tipos_obligacion')
    .select('id_tipo_obligacion')
    .eq('clave', 'PEDIMENTO')
    .single()
    .then(uno);
  const obligacion = await supabase
    .from('obligaciones')
    .insert({
      id_tipo_obligacion: tipo.id_tipo_obligacion,
      fecha_vencimiento: imp.fecha_importacion,
      id_responsable: id_usuario,
    })
    .select('id_obligacion')
    .single()
    .then(uno);
  const importacion = await supabase
    .from('importaciones')
    .insert(
      limpiar({
        id_obligacion: obligacion.id_obligacion,
        id_entrada: imp.id_entrada ? Number(imp.id_entrada) : undefined,
        numero_pedimento: imp.numero_pedimento.trim(),
        aduana: imp.aduana.trim(),
        agente_aduanal: imp.agente_aduanal?.trim(),
        pais_origen: imp.pais_origen.trim(),
        pais_procedencia: imp.pais_procedencia.trim(),
        fecha_importacion: imp.fecha_importacion,
        valor_aduanero: Number(imp.valor_aduanero),
        numero_e2: imp.numero_e2?.trim(),
        padron_importador: imp.padron_importador?.trim(),
        encargo_conferido: imp.encargo_conferido?.trim(),
      })
    )
    .select('id_importacion')
    .single()
    .then(uno);
  await supabase
    .from('productos_importados')
    .insert(
      productos.map((p) =>
        limpiar({
          id_importacion: importacion.id_importacion,
          id_producto: p.id_producto ? Number(p.id_producto) : undefined,
          nombre: p.nombre.trim(),
          marca: p.marca?.trim(),
          modelo: p.modelo?.trim(),
          cantidad: Number(p.cantidad),
          valor_unitario: Number(p.valor_unitario),
          fraccion_arancelaria: p.fraccion_arancelaria || undefined,
          nico: p.nico?.trim(),
        })
      )
    )
    .then(datos);
  return importacion;
}

export async function listarLicencias() {
  return supabase.from('licencias_permisos').select('*').order('fecha_vencimiento').then(datos);
}

export async function registrarLicencia(l) {
  return supabase
    .from('licencias_permisos')
    .insert(
      limpiar({
        tipo_licencia: l.tipo_licencia,
        autoridad_emisora: l.autoridad_emisora.trim(),
        municipio: l.municipio?.trim(),
        numero_licencia: l.numero_licencia?.trim(),
        fecha_emision: l.fecha_emision,
        fecha_vencimiento: l.fecha_vencimiento,
        costo: l.costo === '' || l.costo === undefined ? undefined : Number(l.costo),
        estado: l.estado,
      })
    )
    .then(datos);
}
