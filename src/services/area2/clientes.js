import { supabase } from '@/lib/supabaseClient';
import { datos, limpiar } from '@/lib/consulta';

// Área 2 · Comercializadores. El folio COM-000001 lo pone el trigger (RN-A2-11); nunca hay DELETE (RN-A2-10).

export const RFC_VALIDO = /^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$/; // RN-A2-05

export async function listarClientesResumen() {
  return supabase.from('v_clientes_resumen').select('*').then(datos);
}

export async function listarClientesActivos() {
  return supabase.from('v_clientes_activos').select('*').then(datos);
}

export async function guardarCliente(c) {
  const fila = limpiar({
    nombre_empresa: c.nombre_empresa?.trim(),
    rfc: c.rfc?.trim().toUpperCase() || null,
    estado: c.estado?.trim() || null,
    dias_credito:
      c.dias_credito === '' || c.dias_credito === undefined ? undefined : Number(c.dias_credito),
  });
  const q = c.id_cliente
    ? supabase.from('clientes').update(fila).eq('id_cliente', c.id_cliente)
    : supabase.from('clientes').insert(fila);
  return q.then(datos);
}

// RN-A2-10: baja lógica; conserva sus facturas y desaparece de selectores y de v_clientes_activos
export async function cambiarActivoCliente(id_cliente, activo) {
  return supabase.from('clientes').update({ activo }).eq('id_cliente', id_cliente).then(datos);
}
