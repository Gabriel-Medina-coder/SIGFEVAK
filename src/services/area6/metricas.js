import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 6 · Métricas por periodo. ingreso_atribuido es el estimado del equipo; el real sale de facturas pagadas (RN-A6-14).

export async function listarMetricas(id_campana) {
  return supabase
    .from('metricas_marketing')
    .select('*, canales_marketing(nombre)')
    .eq('id_campana', id_campana)
    .order('periodo_inicio', { ascending: false })
    .then(datos);
}

export async function registrarMetrica(m) {
  const n = (v) => (v === '' || v === undefined ? undefined : Number(v));
  return supabase
    .from('metricas_marketing')
    .insert(
      limpiar({
        id_campana: m.id_campana,
        id_canal: m.id_canal ? Number(m.id_canal) : undefined,
        periodo_inicio: m.periodo_inicio,
        periodo_fin: m.periodo_fin,
        impresiones: n(m.impresiones),
        alcance: n(m.alcance),
        clics: n(m.clics),
        leads_generados: n(m.leads_generados),
        conversiones: n(m.conversiones),
        ingreso_atribuido: n(m.ingreso_atribuido),
        fuente_dato: m.fuente_dato?.trim(),
      })
    )
    .then(datos);
}
