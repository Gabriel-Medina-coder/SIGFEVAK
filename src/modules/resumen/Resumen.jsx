import { useEffect } from 'react';
import {
  KpiCard,
  Panel,
  Mono,
  StatusBadge,
  GraficaBarras,
  Cargando,
  Mensaje,
  mensajeDeError,
  useTopbar,
} from '@/components';
import { obtenerResumenGeneral } from '@/services/coordinacion/resumen';
import { useDatos } from '@/lib/useDatos';
import { pesos, miles, fechaCorta, periodoCorto } from '@/lib/formato';
import { useAuth } from '@/lib/auth';

// Resumen general de la coordinación (docs/FLUJO_APP.md paso 14): KPI de las seis áreas leídos de sus vistas de contrato.
export default function Resumen() {
  const { usuario } = useAuth();
  const { set } = useTopbar();
  const { datos, error, cargando } = useDatos(obtenerResumenGeneral);

  useEffect(() => {
    set({ subtitulo: `SIGFEVAK · Hola, ${usuario?.nombre ?? 'usuario'}` });
    return () => set({});
  }, [set, usuario?.nombre]);

  if (cargando) return <Cargando />;
  if (error) return <Mensaje>{mensajeDeError(error)}</Mensaje>;

  const d = datos;
  const grafica = d.facturacion.slice(-6).map((f) => ({
    label: periodoCorto(f.periodo).slice(0, 3),
    value: Number(f.subtotal),
    titulo: `${periodoCorto(f.periodo)}: ${pesos(f.subtotal)} sin IVA`,
  }));

  return (
    <>
      <div className="grid grid-cols-4 max-[960px]:grid-cols-2 max-[600px]:grid-cols-1 gap-3.5">
        <KpiCard
          label="Capital de inversión"
          value={pesos(d.capitalInversion)}
          delta={pesos(d.valorInventario)}
          up
          sub="valor en almacén"
        />
        <KpiCard
          label="Volumen comercializado"
          value={`${miles(d.volumenComercializado)} uds`}
          delta={`${miles(d.unidadesEnAlmacen)} uds`}
          up
          sub="en almacén"
        />
        <KpiCard
          label="Clientes activos"
          value={miles(d.clientesActivos)}
          delta={pesos(d.carteraPendiente)}
          up={d.carteraVencida === 0}
          sub="por cobrar"
        />
        <KpiCard
          label="Obligaciones pendientes"
          value={pesos(d.fiscal.monto_pendiente)}
          delta={
            d.fiscal.proximo_vencimiento
              ? `Vence ${fechaCorta(d.fiscal.proximo_vencimiento)}`
              : 'Sin vencimientos'
          }
          up={false}
          sub={`${d.fiscal.vencidas ?? 0} vencidas`}
        />
      </div>

      <div className="grid grid-cols-[1fr_300px] max-[960px]:grid-cols-1 gap-3.5">
        <Panel title="Facturación sin IVA por mes">
          <div className="text-[11px] text-text-dim mb-4">Pesos MXN, facturas no canceladas</div>
          {grafica.length ? (
            <GraficaBarras data={grafica} />
          ) : (
            <div className="text-[12px] text-text-dim">Sin facturas</div>
          )}
        </Panel>
        <Panel title="Próximas obligaciones">
          {d.calendario.length === 0 && (
            <div className="text-[12px] text-text-dim">Nada vence en los próximos 30 días.</div>
          )}
          {d.calendario.map((o) => (
            <div
              key={o.id_obligacion}
              className="flex justify-between items-center py-2.5 border-b border-border last:border-b-0"
            >
              <div className="min-w-0">
                <div className="text-[12.5px] font-medium truncate">{o.obligacion}</div>
                <div className="text-[11px] text-text-dim mt-0.5">
                  Vence {fechaCorta(o.fecha_vencimiento)} · {o.periodo}
                </div>
              </div>
              <Mono color="down" bold>
                {o.monto_final || o.monto_estimado ? pesos(o.monto_final ?? o.monto_estimado) : '—'}
              </Mono>
            </div>
          ))}
          <div className="mt-3.5 text-[11.5px] text-text-dim text-center">
            Alertas activas:{' '}
            <Mono color="accent" bold>
              {d.fiscal.alertas_activas ?? 0}
            </Mono>
          </div>
        </Panel>
      </div>

      <div className="grid grid-cols-3 max-[960px]:grid-cols-1 gap-3.5">
        <KpiCard
          label="Nómina del periodo"
          value={pesos(d.nominaTotal)}
          delta={`${d.agentesEnNomina} agentes`}
          up
          sub="neto a pagar"
        />
        <KpiCard
          label="Inversión en marketing"
          value={pesos(d.inversionMarketing)}
          delta={`${d.campanasActivas} activas`}
          up
          sub="campañas"
        />
        <KpiCard
          label="Cartera vencida"
          value={pesos(d.carteraVencida)}
          delta={d.carteraVencida > 0 ? 'revisar cobranza' : 'al corriente'}
          up={d.carteraVencida === 0}
        />
      </div>

      <Panel title="Estado de las áreas">
        <div className="grid grid-cols-3 max-[960px]:grid-cols-1 gap-x-6">
          {[
            ['Entradas', d.volumenPorPeriodo.length > 0],
            ['Registro contable', d.facturacion.length > 0],
            ['Base de productos', d.unidadesEnAlmacen > 0],
            ['Nómina', d.agentesEnNomina > 0],
            ['Regulación', Number(d.fiscal.obligaciones_pendientes ?? 0) > 0],
            ['Marketing', d.inversionMarketing > 0],
          ].map(([area, conDatos]) => (
            <div
              key={area}
              className="flex justify-between items-center py-2.5 border-b border-border"
            >
              <span className="text-[12.5px]">{area}</span>
              <StatusBadge
                status={conDatos ? 'con datos' : 'sin datos'}
                map={{ 'con datos': 'up', 'sin datos': 'down' }}
              />
            </div>
          ))}
        </div>
      </Panel>
    </>
  );
}
