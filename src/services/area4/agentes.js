import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 4 · Agentes, catálogos y metas. El salario mínimo por zona lo valida la base (RN-A4-01) y los tramos
// traslapados también (RN-A4-04).

export async function listarAgentes() {
  return supabase
    .from('agentes_ventas')
    .select(
      '*, zonas(id_zona, nombre, zona_salarial, entidad), esquemas_compensacion(id_esquema, nombre)'
    )
    .order('nombre')
    .then(datos);
}

export async function guardarAgente(a) {
  const salario =
    a.salario_diario === '' || a.salario_diario === undefined
      ? undefined
      : Number(a.salario_diario);
  const fila = limpiar({
    nombre: a.nombre?.trim(),
    rfc: a.rfc?.trim().toUpperCase() || null,
    curp: a.curp?.trim().toUpperCase() || null,
    nss: a.nss?.trim() || null,
    fecha_ingreso: a.fecha_ingreso || null,
    id_zona: a.id_zona ? Number(a.id_zona) : null,
    id_esquema: a.id_esquema ? Number(a.id_esquema) : null,
    salario_diario: salario,
    // sueldo_base del modelo base se mantiene como salario_diario × 30.4 (sección 5 del contexto)
    sueldo_base: salario !== undefined ? Math.round(salario * 30.4 * 100) / 100 : undefined,
    entidad_federativa: a.entidad_federativa?.trim() || null,
    clabe: a.clabe?.trim() || null,
    estatus: a.estatus,
  });
  const q = a.id_agente
    ? supabase.from('agentes_ventas').update(fila).eq('id_agente', a.id_agente)
    : supabase.from('agentes_ventas').insert(fila);
  return q.then(datos);
}

export async function listarZonas() {
  return supabase.from('zonas').select('*').order('nombre').then(datos);
}

export async function crearZona(z) {
  return supabase
    .from('zonas')
    .insert(
      limpiar({
        nombre: z.nombre?.trim(),
        region: z.region?.trim(),
        zona_salarial: z.zona_salarial,
        entidad: z.entidad?.trim(),
      })
    )
    .then(datos);
}

export async function listarEsquemas() {
  return supabase
    .from('esquemas_compensacion')
    .select('*, tramos_comision(id_tramo, pct_min, pct_max, tasa)')
    .order('vigencia_inicio', { ascending: false })
    .then(datos);
}

export async function crearTramo(t) {
  return supabase
    .from('tramos_comision')
    .insert({
      id_esquema: Number(t.id_esquema),
      pct_min: Number(t.pct_min),
      pct_max: t.pct_max === '' || t.pct_max === undefined ? null : Number(t.pct_max),
      tasa: Number(t.tasa_pct) / 100,
    })
    .then(datos);
}

export async function listarCumplimiento(periodo) {
  let q = supabase.from('v_cumplimiento_meta').select('*');
  if (periodo) q = q.eq('periodo', periodo);
  return q.then(datos);
}

export async function listarMetas(periodo) {
  let q = supabase.from('metas').select('id_meta, id_agente, periodo, monto_meta, sin_retardos');
  if (periodo) q = q.eq('periodo', periodo);
  return q.then(datos);
}

export async function guardarMeta(m) {
  return supabase
    .from('metas')
    .upsert(
      {
        id_agente: Number(m.id_agente),
        periodo: m.periodo,
        monto_meta: Number(m.monto_meta),
        sin_retardos: m.sin_retardos !== false,
      },
      { onConflict: 'id_agente,periodo' }
    )
    .then(datos);
}
