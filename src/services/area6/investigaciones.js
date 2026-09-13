import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 6 · Investigación de mercado. Puede existir sin campaña (RN-A6-16).

export async function listarInvestigaciones() {
  return supabase
    .from('investigaciones_mercado')
    .select('*, campanas(nombre), proveedores_marketing(razon_social)')
    .order('fecha_inicio', { ascending: false, nullsFirst: false })
    .then(datos);
}

export async function registrarInvestigacion(i, id_usuario) {
  return supabase
    .from('investigaciones_mercado')
    .insert(
      limpiar({
        titulo: i.titulo.trim(),
        tipo: i.tipo,
        id_campana: i.id_campana ? Number(i.id_campana) : undefined,
        objetivo: i.objetivo?.trim(),
        metodologia: i.metodologia?.trim(),
        tamano_muestra: i.tamano_muestra ? Number(i.tamano_muestra) : undefined,
        id_proveedor_marketing: i.id_proveedor_marketing
          ? Number(i.id_proveedor_marketing)
          : undefined,
        costo: i.costo ? Number(i.costo) : undefined,
        fecha_inicio: i.fecha_inicio,
        fecha_fin: i.fecha_fin,
        estado: i.estado,
        resumen_hallazgos: i.resumen_hallazgos?.trim(),
        url_reporte: i.url_reporte?.trim(),
        creado_por: id_usuario,
      })
    )
    .then(datos);
}
