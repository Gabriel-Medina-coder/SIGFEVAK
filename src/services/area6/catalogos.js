import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 6 · Catálogos de canales y proveedores de marketing. Baja lógica, nunca DELETE (RN-A6-06).

export async function listarCanales({ soloActivos = false } = {}) {
  let q = supabase.from('canales_marketing').select('*').order('nombre');
  if (soloActivos) q = q.eq('activo', true);
  return q.then(datos);
}

export async function guardarCanal(c) {
  const fila = limpiar({
    nombre: c.nombre?.trim(),
    categoria: c.categoria,
    descripcion: c.descripcion?.trim() || null,
    activo: c.activo,
  });
  const q = c.id_canal
    ? supabase.from('canales_marketing').update(fila).eq('id_canal', c.id_canal)
    : supabase.from('canales_marketing').insert(fila);
  return q.then(datos);
}

export async function listarProveedoresMarketing({ soloActivos = false } = {}) {
  let q = supabase.from('proveedores_marketing').select('*').order('razon_social');
  if (soloActivos) q = q.eq('activo', true);
  return q.then(datos);
}

export async function guardarProveedorMarketing(p) {
  const fila = limpiar({
    razon_social: p.razon_social?.trim(),
    rfc: p.rfc?.trim().toUpperCase() || null,
    tipo_servicio: p.tipo_servicio,
    contacto_nombre: p.contacto_nombre?.trim() || null,
    contacto_email: p.contacto_email?.trim() || null,
    contacto_telefono: p.contacto_telefono?.trim() || null,
    activo: p.activo,
  });
  const q = p.id_proveedor_marketing
    ? supabase
        .from('proveedores_marketing')
        .update(fila)
        .eq('id_proveedor_marketing', p.id_proveedor_marketing)
    : supabase.from('proveedores_marketing').insert(fila);
  return q.then(datos);
}
