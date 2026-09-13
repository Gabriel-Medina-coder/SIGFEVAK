import { supabase } from '@/lib/supabaseClient';

// Resumen general de la coordinación: lee solo vistas de contrato de las seis áreas (docs/FLUJO_APP.md paso 14).

function lanzar({ data, error }) {
  if (error) throw error;
  return data ?? [];
}

export async function obtenerResumenGeneral() {
  const [
    inventario,
    entradasPeriodo,
    clientes,
    fiscal,
    calendario,
    nomina,
    ultimaRetencion,
    campanas,
    facturacion,
    pendientes,
  ] = await Promise.all([
    supabase
      .from('v_inventario_actual')
      .select('stock, volumen, capital_inversion, valor_inventario')
      .then(lanzar),
    supabase
      .from('v_entradas_area1')
      .select('periodo, tipo, volumen_comercializacion, capital_inversion')
      .then(lanzar),
    supabase.from('v_clientes_activos').select('id_cliente').then(lanzar),
    supabase
      .from('v_resumen_fiscal')
      .select('*')
      .maybeSingle()
      .then(({ data, error }) => {
        if (error) throw error;
        return data ?? {};
      }),
    supabase
      .from('v_calendario_fiscal')
      .select(
        'id_obligacion, clave, obligacion, periodo, fecha_vencimiento, dias_restantes, monto_estimado, monto_final, estado'
      )
      .order('fecha_vencimiento')
      .limit(4)
      .then(lanzar),
    supabase
      .from('v_nomina_totales')
      .select('id_periodo, id_agente, nombre, percepciones, deducciones, neto')
      .then(lanzar),
    // Último periodo autorizado por fecha (el id no sigue el calendario cuando se capturan periodos atrasados)
    supabase
      .from('v_retenciones_area5')
      .select('id_periodo, fecha_fin')
      .order('fecha_fin', { ascending: false })
      .limit(1)
      .then(lanzar),
    supabase
      .from('v_campana_resumen')
      .select('nombre, estatus, gasto_total, presupuesto_asignado, roi')
      .then(lanzar),
    supabase
      .from('v_iva_trasladado_periodo')
      .select('periodo, numero_facturas, subtotal, iva_trasladado, total')
      .then(lanzar),
    supabase.from('v_facturas_pendientes').select('valor_total, dias_vencidos').then(lanzar),
  ]);

  const suma = (lista, campo) => lista.reduce((acc, r) => acc + Number(r[campo] ?? 0), 0);
  const ultimoPeriodo = ultimaRetencion[0]?.id_periodo;
  const nominaUltima = nomina.filter((n) => n.id_periodo === ultimoPeriodo);

  const volumenPorPeriodo = Object.values(
    entradasPeriodo.reduce((acc, r) => {
      acc[r.periodo] ??= { periodo: r.periodo, volumen: 0, capital: 0 };
      acc[r.periodo].volumen += Number(r.volumen_comercializacion ?? 0);
      acc[r.periodo].capital += Number(r.capital_inversion ?? 0);
      return acc;
    }, {})
  ).sort((a, b) => a.periodo.localeCompare(b.periodo));

  return {
    capitalInversion: suma(inventario, 'capital_inversion'),
    valorInventario: suma(inventario, 'valor_inventario'),
    unidadesEnAlmacen: suma(inventario, 'stock'),
    volumenComercializado: suma(inventario, 'volumen'),
    clientesActivos: clientes.length,
    fiscal,
    calendario,
    nominaTotal: suma(nominaUltima, 'neto'),
    nominaPercepciones: suma(nominaUltima, 'percepciones'),
    agentesEnNomina: nominaUltima.length,
    campanasActivas: campanas.filter((c) => c.estatus === 'ACTIVA').length,
    inversionMarketing: suma(campanas, 'gasto_total'),
    facturacion: facturacion.sort((a, b) => a.periodo.localeCompare(b.periodo)),
    carteraPendiente: suma(pendientes, 'valor_total'),
    carteraVencida: suma(
      pendientes.filter((p) => Number(p.dias_vencidos) > 0),
      'valor_total'
    ),
    volumenPorPeriodo,
  };
}
