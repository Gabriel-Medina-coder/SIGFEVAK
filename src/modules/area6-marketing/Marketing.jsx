import { useEffect, useMemo, useState } from 'react';
import {
  KpiCard,
  Panel,
  Table,
  Mono,
  Tag,
  StatusBadge,
  Pestanas,
  Modal,
  FilaKpi,
  RejillaForm,
  Acciones,
  Texto,
  GraficaBarras,
  Campo,
  Entrada,
  AreaTexto,
  Selector,
  Boton,
  Mensaje,
  Cargando,
  mensajeDeError,
  useTopbar,
} from '@/components';
import { useAuth } from '@/lib/auth';
import { puedeEscribir } from '@/lib/permisos';
import { useDatos } from '@/lib/useDatos';
import { miles, pesos, porcentaje, fechaCorta, hoyIso } from '@/lib/formato';
import { exportarCsv } from '@/lib/exportar';
import {
  mensajeMarketing,
  listarResumenCampanas,
  obtenerCampana,
  guardarCampana,
  cambiarEstatusCampana,
  listarDesempenoDirecto,
  listarVentasAtribuidas,
  listarClientesCampana,
  agregarClienteCampana,
  actualizarContacto,
  listarProductosCampana,
  agregarProductoCampana,
  quitarProductoCampana,
} from '@/services/area6/campanas';
import { listarCostos, registrarCosto, listarCostosPorCanal } from '@/services/area6/costos';
import { listarMetricas, registrarMetrica } from '@/services/area6/metricas';
import { listarInvestigaciones, registrarInvestigacion } from '@/services/area6/investigaciones';
import {
  listarCanales,
  guardarCanal,
  listarProveedoresMarketing,
  guardarProveedorMarketing,
} from '@/services/area6/catalogos';
import {
  listarClientesActivos,
  listarProductos,
  listarBajaRotacion,
  listarProduccionProyectada,
  listarBajoStockMinimo,
} from '@/services/area6/referencias';

const COLOR_CAMPANA = {
  PLANEADA: 'muted',
  ACTIVA: 'up',
  PAUSADA: 'accent',
  FINALIZADA: 'muted',
  CANCELADA: 'down',
};
const COLOR_CONTACTO = {
  OBJETIVO: 'muted',
  CONTACTADO: 'accent',
  RESPONDIO: 'accent',
  CONVERTIDO: 'up',
  NO_INTERESADO: 'down',
};
const COLOR_INVESTIGACION = {
  PLANEADA: 'muted',
  EN_CURSO: 'accent',
  FINALIZADA: 'up',
  CANCELADA: 'down',
};
const TIPOS_INVESTIGACION = [
  'ENCUESTA',
  'FOCUS_GROUP',
  'ANALISIS_MERCADO',
  'BENCHMARKING_COMPETENCIA',
  'ESTUDIO_SATISFACCION',
  'OTRO',
];

const texto = (v) =>
  String(v ?? '')
    .toLowerCase()
    .replaceAll('_', ' ');
function error(err, contexto) {
  return mensajeMarketing(err, contexto) ?? mensajeDeError(err);
}

export default function Marketing() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'marketing');
  const esAdmin = usuario?.rol === 'ADMINISTRADOR';
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('tablero');
  const [modal, setModal] = useState(null);
  const campanas = useDatos(listarResumenCampanas);

  const pestanas = [
    { id: 'tablero', etiqueta: 'Tablero' },
    { id: 'campanas', etiqueta: 'Campañas' },
    { id: 'costos', etiqueta: 'Costos' },
    { id: 'investigacion', etiqueta: 'Investigación de mercado' },
    ...(esAdmin ? [{ id: 'catalogos', etiqueta: 'Canales y proveedores' }] : []),
  ];

  useEffect(() => {
    set({
      acciones: (
        <>
          <Boton onClick={() => exportarCsv('campanas', campanas.datos ?? [])}>Exportar</Boton>
          {escribe && (
            <Boton variante="primario" onClick={() => setModal({ tipo: 'nueva' })}>
              + Nueva campaña
            </Boton>
          )}
        </>
      ),
    });
    return () => set({});
  }, [set, escribe, campanas.datos]);

  if (campanas.cargando && !campanas.datos) return <Cargando />;
  if (campanas.error) return <Mensaje>{error(campanas.error)}</Mensaje>;

  return (
    <>
      <IndicadoresBreves campanas={campanas.datos} />

      <Pestanas opciones={pestanas} activa={pestana} onCambiar={setPestana} />

      {pestana === 'tablero' && (
        <>
          <Tablero campanas={campanas.datos} />
          <Recientes
            campanas={campanas.datos}
            onAbrir={(id) => setModal({ tipo: 'detalle', id })}
          />
        </>
      )}
      {pestana === 'campanas' && (
        <Campanas campanas={campanas.datos} onAbrir={(id) => setModal({ tipo: 'detalle', id })} />
      )}
      {pestana === 'costos' && <Costos campanas={campanas.datos} />}
      {pestana === 'investigacion' && (
        <Investigaciones campanas={campanas.datos} escribe={escribe} usuario={usuario} />
      )}
      {pestana === 'catalogos' && esAdmin && <Catalogos />}

      <Modal
        abierto={modal?.tipo === 'nueva'}
        titulo="Nueva campaña"
        onCerrar={() => setModal(null)}
      >
        {modal?.tipo === 'nueva' && (
          <FormCampana
            usuario={usuario}
            onListo={(nueva) => {
              campanas.recargar();
              setModal(nueva?.id_campana ? { tipo: 'detalle', id: nueva.id_campana } : null);
            }}
            onCancelar={() => setModal(null)}
          />
        )}
      </Modal>
      <Modal
        abierto={modal?.tipo === 'detalle'}
        titulo="Detalle de campaña"
        onCerrar={() => setModal(null)}
        ancho="max-w-4xl"
      >
        {modal?.tipo === 'detalle' && (
          <DetalleCampana
            id={modal.id}
            escribe={escribe}
            usuario={usuario}
            onCambio={campanas.recargar}
          />
        )}
      </Modal>
    </>
  );
}

function IndicadoresBreves({ campanas }) {
  const activas = campanas.filter((c) => c.estatus === 'ACTIVA').length;
  const gasto = campanas.reduce((a, c) => a + Number(c.gasto_total), 0);
  return (
    <FilaKpi columnas={3}>
      <KpiCard
        label="Campañas activas"
        value={miles(activas)}
        delta={`${campanas.length} en total`}
        up
      />
      <KpiCard
        label="Gasto ejercido"
        value={pesos(gasto)}
        delta={`${campanas.filter((c) => c.estatus === 'FINALIZADA').length} finalizadas`}
        up
      />
      <KpiCard
        label="Conversiones"
        value={miles(campanas.reduce((a, c) => a + Number(c.conversiones), 0))}
        delta={`${miles(campanas.reduce((a, c) => a + Number(c.leads_generados), 0))} leads`}
        up
      />
    </FilaKpi>
  );
}

// RN-A6-12: el ROI estimado sale de las métricas; sin ingreso atribuido capturado no hay ROI que mostrar
// (en las DIRECTO el ROI real se ve en su detalle, desde las facturas pagadas)
function roiEstimado(c) {
  return c.roi === null || Number(c.ingreso_atribuido ?? 0) === 0 ? null : Number(c.roi);
}

function Tablero({ campanas }) {
  const [rango, setRango] = useState({ desde: '', hasta: '' });
  const canales = useDatos(listarCostosPorCanal);
  const abasto = useDatos(() =>
    Promise.all([listarProduccionProyectada(), listarBajoStockMinimo()])
  );
  const [produccion, bajoStock] = abasto.datos ?? [[], []];
  const filtradas = campanas.filter(
    (c) =>
      (!rango.desde || c.fecha_inicio >= rango.desde) &&
      (!rango.hasta || c.fecha_inicio <= rango.hasta)
  );
  const suma = (campo) => filtradas.reduce((a, c) => a + Number(c[campo] ?? 0), 0);
  const presupuesto = suma('presupuesto_asignado');
  const gasto = suma('gasto_total');
  const conRoi = filtradas.filter((c) => roiEstimado(c) !== null);
  const roiPromedio = conRoi.length
    ? conRoi.reduce((a, c) => a + roiEstimado(c), 0) / conRoi.length
    : null;

  return (
    <>
      <div className="flex flex-wrap gap-4 items-end">
        <div className="w-44">
          <Campo etiqueta="Inicio desde">
            <Entrada
              type="date"
              value={rango.desde}
              onChange={(e) => setRango({ ...rango, desde: e.target.value })}
            />
          </Campo>
        </div>
        <div className="w-44">
          <Campo etiqueta="Inicio hasta">
            <Entrada
              type="date"
              value={rango.hasta}
              onChange={(e) => setRango({ ...rango, hasta: e.target.value })}
            />
          </Campo>
        </div>
      </div>
      <FilaKpi columnas={3}>
        <KpiCard
          label="Presupuesto del periodo"
          value={pesos(presupuesto)}
          delta={`${filtradas.length} campañas`}
          up
        />
        <KpiCard
          label="Gasto ejercido"
          value={pesos(gasto)}
          delta={pesos(presupuesto - gasto)}
          up
          sub="restante"
        />
        <KpiCard
          label="% ejercido"
          value={porcentaje(presupuesto ? (gasto / presupuesto) * 100 : 0)}
          delta={gasto > presupuesto ? 'excedido' : 'dentro del presupuesto'}
          up={gasto <= presupuesto}
        />
        <KpiCard
          label="Leads generados"
          value={miles(suma('leads_generados'))}
          delta="métricas capturadas"
          up
        />
        <KpiCard
          label="Conversiones"
          value={miles(suma('conversiones'))}
          delta={pesos(suma('ingreso_atribuido'))}
          up
          sub="ingreso atribuido"
        />
        <KpiCard
          label="ROI promedio"
          value={roiPromedio === null ? '—' : `${roiPromedio.toFixed(2)}x`}
          delta={`${conRoi.length} con métricas`}
          up={roiPromedio === null || roiPromedio >= 0}
        />
      </FilaKpi>
      <Panel title="Gasto por canal">
        {canales.cargando ? (
          <Cargando />
        ) : (
          <>
            <div className="text-[11px] text-text-dim mb-4">Pesos MXN acumulados</div>
            <GraficaBarras
              data={(canales.datos ?? [])
                .filter((c) => Number(c.gasto_total) > 0)
                .sort((a, b) => Number(a.gasto_total) - Number(b.gasto_total))
                .map((c) => ({
                  label: c.canal.split(' ')[0],
                  value: Number(c.gasto_total),
                  titulo: `${c.canal}: ${pesos(c.gasto_total)}`,
                }))}
            />
          </>
        )}
      </Panel>
      <div className="grid grid-cols-2 gap-4 max-[960px]:grid-cols-1">
        <Panel title="Producción en camino (Entradas)">
          <Table
            headers={['Orden', 'Producto', 'Unidades', 'Estado']}
            vacio="Sin órdenes planeadas ni en proceso"
            rows={produccion.map((o) => [
              <Mono>{o.folio}</Mono>,
              <Texto bold>{o.producto}</Texto>,
              <Mono>{miles(o.cantidad_planeada)}</Mono>,
              <Tag color="accent">{o.estado.toLowerCase().replace('_', ' ')}</Tag>,
            ])}
          />
        </Panel>
        <Panel title="No promocionar todavía: bajo stock mínimo">
          <Table
            headers={['Producto', 'Stock', 'Mínimo', 'Faltan']}
            vacio="Todo el catálogo está sobre su mínimo"
            rows={bajoStock.map((p) => [
              <Texto bold>{p.nombre}</Texto>,
              <Mono color="down">{miles(p.stock)}</Mono>,
              <Mono color="dim">{miles(p.stock_minimo)}</Mono>,
              <Mono bold>{miles(p.faltante)}</Mono>,
            ])}
          />
        </Panel>
      </div>
    </>
  );
}

function Recientes({ campanas, onAbrir }) {
  return (
    <Panel title="Campañas recientes">
      <Table
        headers={[
          'Campaña',
          'Tipo',
          'Inicio',
          'Presupuesto',
          'Gasto',
          'Conversiones',
          'ROI',
          'Estatus',
        ]}
        onRowClick={(i) => onAbrir(campanas[i].id_campana)}
        rows={campanas
          .slice(0, 8)
          .map((c) => [
            <Texto bold>{c.nombre}</Texto>,
            <Tag color={c.tipo_marketing === 'EXTERNO' ? 'accent' : 'muted'}>
              {texto(c.tipo_marketing)}
            </Tag>,
            <Mono color="dim">{fechaCorta(c.fecha_inicio)}</Mono>,
            <Mono>{pesos(c.presupuesto_asignado)}</Mono>,
            <Mono color="up">{pesos(c.gasto_total)}</Mono>,
            <Mono bold>{miles(c.conversiones)}</Mono>,
            <Mono color={roiEstimado(c) === null ? 'dim' : roiEstimado(c) >= 0 ? 'up' : 'down'}>
              {roiEstimado(c) === null ? '—' : `${roiEstimado(c).toFixed(2)}x`}
            </Mono>,
            <StatusBadge status={c.estatus} map={COLOR_CAMPANA} />,
          ])}
      />
    </Panel>
  );
}

function Campanas({ campanas, onAbrir }) {
  const [filtro, setFiltro] = useState({ tipo: '', estatus: '', canal: '', desde: '', hasta: '' });
  const extra = useDatos(() => Promise.all([listarCanales(), listarCostos()]));
  const [canales, costos] = extra.datos ?? [[], []];
  const canalesPorCampana = useMemo(() => {
    const m = {};
    for (const c of costos) (m[c.id_campana] ??= new Set()).add(String(c.id_canal));
    return m;
  }, [costos]);
  const filtradas = campanas.filter(
    (c) =>
      (!filtro.tipo || c.tipo_marketing === filtro.tipo) &&
      (!filtro.estatus || c.estatus === filtro.estatus) &&
      (!filtro.canal || canalesPorCampana[c.id_campana]?.has(filtro.canal)) &&
      (!filtro.desde || c.fecha_inicio >= filtro.desde) &&
      (!filtro.hasta || c.fecha_inicio <= filtro.hasta)
  );
  const cambiar = (n) => (e) => setFiltro({ ...filtro, [n]: e.target.value });

  return (
    <Panel title="Campañas">
      <div className="-mt-1 mb-6">
        <RejillaForm columnas={3}>
          <Campo etiqueta="Tipo">
            <Selector
              placeholder="Todos"
              opciones={[
                { valor: 'EXTERNO', etiqueta: 'Externo' },
                { valor: 'DIRECTO', etiqueta: 'Directo' },
              ]}
              value={filtro.tipo}
              onChange={cambiar('tipo')}
            />
          </Campo>
          <Campo etiqueta="Estatus">
            <Selector
              placeholder="Todos"
              opciones={Object.keys(COLOR_CAMPANA).map((e) => ({ valor: e, etiqueta: texto(e) }))}
              value={filtro.estatus}
              onChange={cambiar('estatus')}
            />
          </Campo>
          <Campo etiqueta="Canal">
            <Selector
              placeholder="Todos"
              opciones={canales.map((c) => ({ valor: String(c.id_canal), etiqueta: c.nombre }))}
              value={filtro.canal}
              onChange={cambiar('canal')}
            />
          </Campo>
          <Campo etiqueta="Inicio desde">
            <Entrada type="date" value={filtro.desde} onChange={cambiar('desde')} />
          </Campo>
          <Campo etiqueta="Inicio hasta">
            <Entrada type="date" value={filtro.hasta} onChange={cambiar('hasta')} />
          </Campo>
        </RejillaForm>
      </div>
      <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
        <Table
          headers={[
            'Campaña',
            'Tipo',
            'Vigencia',
            'Presupuesto',
            'Gasto',
            'Restante',
            '% ejercido',
            'Leads',
            'ROI',
            'Estatus',
          ]}
          onRowClick={(i) => onAbrir(filtradas[i].id_campana)}
          vacio="Ninguna campaña con esos filtros"
          rows={filtradas.map((c) => [
            <Texto bold>{c.nombre}</Texto>,
            <Tag color={c.tipo_marketing === 'EXTERNO' ? 'accent' : 'muted'}>
              {texto(c.tipo_marketing)}
            </Tag>,
            <Mono color="dim">
              {fechaCorta(c.fecha_inicio)} · {c.fecha_fin ? fechaCorta(c.fecha_fin) : 'abierta'}
            </Mono>,
            <Mono>{pesos(c.presupuesto_asignado)}</Mono>,
            <Mono color="up">{pesos(c.gasto_total)}</Mono>,
            <Mono color={Number(c.presupuesto_restante) < 0 ? 'down' : 'dim'}>
              {pesos(c.presupuesto_restante)}
            </Mono>,
            <Mono>{porcentaje(c.pct_ejercido)}</Mono>,
            <Mono>{miles(c.leads_generados)}</Mono>,
            <Mono
              bold
              color={roiEstimado(c) === null ? 'dim' : roiEstimado(c) >= 0 ? 'up' : 'down'}
            >
              {roiEstimado(c) === null ? '—' : `${roiEstimado(c).toFixed(2)}x`}
            </Mono>,
            <StatusBadge status={c.estatus} map={COLOR_CAMPANA} />,
          ])}
        />
      </div>
    </Panel>
  );
}

function FormCampana({ inicial, usuario, onListo, onCancelar }) {
  const [f, setF] = useState(
    inicial ?? { tipo_marketing: '', fecha_inicio: hoyIso(), presupuesto_asignado: '' }
  );
  const [aviso, setAviso] = useState('');
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (!f.nombre?.trim() || !f.tipo_marketing || !f.fecha_inicio)
      return setAviso('Nombre, tipo y fecha de inicio son obligatorios (RN-A6-01).');
    if (!(Number(f.presupuesto_asignado) >= 0) || f.presupuesto_asignado === '')
      return setAviso('Indica el presupuesto asignado.');
    if (f.fecha_fin && f.fecha_fin < f.fecha_inicio)
      return setAviso('La fecha de fin no puede ser anterior a la de inicio (RN-A6-10).');
    try {
      const r = await guardarCampana(f, usuario?.id_usuario);
      onListo(r);
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <Campo etiqueta="Nombre">
        <Entrada {...campo('nombre')} />
      </Campo>
      <RejillaForm>
        <Campo etiqueta="Tipo">
          <Selector
            disabled={!!inicial?.id_campana}
            opciones={[
              { valor: 'EXTERNO', etiqueta: 'Externo · mercado general' },
              { valor: 'DIRECTO', etiqueta: 'Directo · clientes identificados' },
            ]}
            {...campo('tipo_marketing')}
          />
        </Campo>
        <Campo etiqueta="Presupuesto asignado">
          <Entrada type="number" min="0" step="0.01" {...campo('presupuesto_asignado')} />
        </Campo>
        <Campo etiqueta="Inicio">
          <Entrada type="date" {...campo('fecha_inicio')} />
        </Campo>
        <Campo etiqueta="Fin">
          <Entrada type="date" {...campo('fecha_fin')} />
        </Campo>
      </RejillaForm>
      <Campo etiqueta="Objetivo">
        <AreaTexto {...campo('objetivo')} />
      </Campo>
      {aviso && <Mensaje>{aviso}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onCancelar}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit">
          Guardar
        </Boton>
      </Acciones>
    </form>
  );
}

function DetalleCampana({ id, escribe, usuario, onCambio }) {
  const campana = useDatos(() => Promise.all([obtenerCampana(id), listarResumenCampanas()]), [id]);
  const [pestana, setPestana] = useState('general');
  const [aviso, setAviso] = useState(null);

  if (campana.cargando && !campana.datos) return <Cargando />;
  if (campana.error) return <Mensaje>{error(campana.error)}</Mensaje>;
  const [c, resumenes] = campana.datos;
  const resumen = resumenes.find((r) => r.id_campana === id) ?? {};
  const directo = c.tipo_marketing === 'DIRECTO';
  const cerrada = ['FINALIZADA', 'CANCELADA'].includes(c.estatus);
  const recargar = () => {
    campana.recargar();
    onCambio();
  };

  async function estatus(nuevo) {
    if (
      nuevo === 'CANCELADA' &&
      !window.confirm('¿Cancelar la campaña? No se borra; deja de aceptar costos y métricas.')
    )
      return;
    try {
      await cambiarEstatusCampana(id, nuevo);
      setAviso({ tipo: 'ok', texto: `Campaña ${texto(nuevo)}.` });
      recargar();
    } catch (err) {
      setAviso({ tipo: 'error', texto: error(err) });
    }
  }

  const pestanas = [
    { id: 'general', etiqueta: 'General' },
    { id: 'costos', etiqueta: 'Costos' },
    { id: 'metricas', etiqueta: 'Métricas' },
    ...(directo ? [{ id: 'clientes', etiqueta: 'Clientes objetivo' }] : []),
    { id: 'productos', etiqueta: 'Productos promovidos' },
  ];

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3">
        <span className="text-[14px] font-semibold">{c.nombre}</span>
        <Tag color={directo ? 'muted' : 'accent'}>{texto(c.tipo_marketing)}</Tag>
        <StatusBadge status={c.estatus} map={COLOR_CAMPANA} />
      </div>
      <RejillaForm columnas={3}>
        <Dato
          etiqueta="Presupuesto"
          valor={<Mono>{pesos(c.presupuesto_asignado, { centavos: true })}</Mono>}
        />
        <Dato
          etiqueta="Gasto / restante"
          valor={
            <Mono>
              {pesos(resumen.gasto_total, { centavos: true })} ·{' '}
              {pesos(resumen.presupuesto_restante, { centavos: true })}
            </Mono>
          }
        />
        <Dato
          etiqueta="ROI estimado por métricas"
          valor={
            <Mono bold>
              {resumen.roi === null ||
              resumen.roi === undefined ||
              Number(resumen.ingreso_atribuido) === 0
                ? 'sin métricas'
                : `${Number(resumen.roi).toFixed(4)}x`}
            </Mono>
          }
        />
      </RejillaForm>

      <Pestanas opciones={pestanas} activa={pestana} onCambiar={setPestana} />

      {pestana === 'general' && (
        <GeneralCampana
          campana={c}
          directo={directo}
          cerrada={cerrada}
          escribe={escribe}
          usuario={usuario}
          onEstatus={estatus}
          onCambio={recargar}
        />
      )}
      {pestana === 'costos' && (
        <CostosCampana
          campana={c}
          resumen={resumen}
          escribe={escribe && !cerrada}
          onCambio={recargar}
        />
      )}
      {pestana === 'metricas' && (
        <MetricasCampana campana={c} escribe={escribe && !cerrada} onCambio={recargar} />
      )}
      {pestana === 'clientes' && directo && (
        <ClientesCampana campana={c} escribe={escribe && !cerrada} onCambio={recargar} />
      )}
      {pestana === 'productos' && <ProductosCampana campana={c} escribe={escribe && !cerrada} />}
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}

function Dato({ etiqueta, valor }) {
  return (
    <div>
      <div className="text-[10.5px] uppercase tracking-[0.04em] text-text-dim mb-1">{etiqueta}</div>
      <div className="text-[13px]">{valor}</div>
    </div>
  );
}

function GeneralCampana({ campana, directo, cerrada, escribe, usuario, onEstatus, onCambio }) {
  const directos = useDatos(
    () =>
      directo
        ? Promise.all([listarDesempenoDirecto(), listarVentasAtribuidas()])
        : Promise.resolve([[], []]),
    [campana.id_campana, directo]
  );
  const [editando, setEditando] = useState(false);
  const [desempeno, ventas] = directos.datos ?? [[], []];
  const d = desempeno.find((x) => x.id_campana === campana.id_campana);
  const v = ventas.find((x) => x.id_campana === campana.id_campana);

  if (editando) {
    return (
      <FormCampana
        inicial={campana}
        usuario={usuario}
        onListo={() => {
          setEditando(false);
          onCambio();
        }}
        onCancelar={() => setEditando(false)}
      />
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Dato
          etiqueta="Vigencia"
          valor={
            <Mono>
              {fechaCorta(campana.fecha_inicio)} ·{' '}
              {campana.fecha_fin ? fechaCorta(campana.fecha_fin) : 'abierta'}
            </Mono>
          }
        />
        <Dato etiqueta="Objetivo" valor={<Texto dim>{campana.objetivo ?? '—'}</Texto>} />
        <Dato etiqueta="Moneda" valor={<Mono>{campana.moneda}</Mono>} />
      </RejillaForm>
      {directo && d && (
        <Panel title="Desempeño del marketing directo">
          <RejillaForm columnas={3}>
            <Dato
              etiqueta="Objetivo / contactados"
              valor={
                <Mono>
                  {d.total_objetivo} · {d.total_contactados}
                </Mono>
              }
            />
            <Dato
              etiqueta="Convertidos"
              valor={
                <Mono bold color="up">
                  {d.total_convertidos} ({porcentaje(d.tasa_conversion_pct)})
                </Mono>
              }
            />
            <Dato
              etiqueta="Facturas atribuidas"
              valor={<Mono>{v?.facturas_atribuidas ?? 0}</Mono>}
            />
            <Dato
              etiqueta="Ventas atribuidas sin IVA"
              valor={<Mono bold>{pesos(v?.ventas_atribuidas_sin_iva, { centavos: true })}</Mono>}
            />
            <Dato
              etiqueta="Gasto"
              valor={<Mono>{pesos(v?.gasto_total, { centavos: true })}</Mono>}
            />
            <Dato
              etiqueta="ROI real"
              valor={
                <Mono bold color="up">
                  {v?.roi_real === null || v?.roi_real === undefined
                    ? '—'
                    : `${Number(v.roi_real).toFixed(4)}x`}
                </Mono>
              }
            />
          </RejillaForm>
        </Panel>
      )}
      {escribe && !cerrada && (
        <div className="flex flex-wrap gap-2">
          <Boton onClick={() => setEditando(true)}>Editar datos</Boton>
          {campana.estatus !== 'ACTIVA' && (
            <Boton variante="primario" onClick={() => onEstatus('ACTIVA')}>
              Activar
            </Boton>
          )}
          {campana.estatus === 'ACTIVA' && (
            <Boton onClick={() => onEstatus('PAUSADA')}>Pausar</Boton>
          )}
          {['ACTIVA', 'PAUSADA'].includes(campana.estatus) && (
            <Boton onClick={() => onEstatus('FINALIZADA')}>Finalizar</Boton>
          )}
          <Boton variante="peligro" onClick={() => onEstatus('CANCELADA')}>
            Cancelar campaña
          </Boton>
        </div>
      )}
      {cerrada && (
        <Mensaje tipo="info">
          La campaña está {texto(campana.estatus)}; ya no acepta costos ni métricas (RN-A6-13).
        </Mensaje>
      )}
    </div>
  );
}

function CostosCampana({ campana, resumen, escribe, onCambio }) {
  const costos = useDatos(
    () => listarCostos({ id_campana: campana.id_campana }),
    [campana.id_campana]
  );
  const catalogos = useDatos(() =>
    Promise.all([
      listarCanales({ soloActivos: true }),
      listarProveedoresMarketing({ soloActivos: true }),
    ])
  );
  const [f, setF] = useState({ fecha_gasto: hoyIso(), estado_pago: 'PENDIENTE' });
  const [aviso, setAviso] = useState(null);
  const [canales, proveedores] = catalogos.datos ?? [[], []];
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (!f.id_canal || !f.concepto?.trim() || !(Number(f.monto) > 0))
      return setAviso({ tipo: 'error', texto: 'Canal, concepto y monto son obligatorios.' });
    try {
      await registrarCosto({ ...f, id_campana: campana.id_campana });
      setAviso({ tipo: 'ok', texto: 'Costo registrado.' });
      setF({ fecha_gasto: hoyIso(), estado_pago: 'PENDIENTE' });
      costos.recargar();
      onCambio();
    } catch (err) {
      // Conserva lo capturado para que el usuario corrija (docs/area6-marketing/TAREAS.md tarea 18)
      setAviso({ tipo: 'error', texto: error(err, { monto: f.monto }) });
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="text-[12.5px] text-text-dim">
        Total <Mono bold>{pesos(resumen.gasto_total, { centavos: true })}</Mono> de{' '}
        <Mono>{pesos(campana.presupuesto_asignado, { centavos: true })}</Mono> (
        {porcentaje(resumen.pct_ejercido)})
      </div>
      <div className="px-[22px] py-5">
        {costos.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['Fecha', 'Concepto', 'Canal', 'Proveedor', 'Monto', 'Pago']}
            vacio="Sin costos"
            rows={(costos.datos ?? []).map((c) => [
              <Mono color="dim">{fechaCorta(c.fecha_gasto)}</Mono>,
              <Texto bold>{c.concepto}</Texto>,
              <Texto dim>{c.canales_marketing?.nombre}</Texto>,
              <Texto dim>{c.proveedores_marketing?.razon_social ?? 'interno'}</Texto>,
              <Mono bold>{pesos(c.monto, { centavos: true })}</Mono>,
              <StatusBadge
                status={c.estado_pago}
                map={{ PAGADO: 'up', PENDIENTE: 'down', PARCIAL: 'accent', CANCELADO: 'muted' }}
              />,
            ])}
          />
        )}
      </div>
      {escribe && (
        <form onSubmit={guardar} className="flex flex-col gap-3 border-t border-border pt-4">
          <RejillaForm columnas={3}>
            <Campo etiqueta="Concepto">
              <Entrada {...campo('concepto')} />
            </Campo>
            <Campo etiqueta="Canal">
              <Selector
                opciones={canales.map((c) => ({ valor: c.id_canal, etiqueta: c.nombre }))}
                {...campo('id_canal')}
              />
            </Campo>
            <Campo etiqueta="Proveedor">
              <Selector
                placeholder="Gasto interno"
                opciones={proveedores.map((p) => ({
                  valor: p.id_proveedor_marketing,
                  etiqueta: p.razon_social,
                }))}
                {...campo('id_proveedor_marketing')}
              />
            </Campo>
            <Campo etiqueta="Monto">
              <Entrada type="number" min="0.01" step="0.01" {...campo('monto')} />
            </Campo>
            <Campo etiqueta="Fecha">
              <Entrada type="date" {...campo('fecha_gasto')} />
            </Campo>
            <Campo etiqueta="Pago">
              <Selector
                placeholder="Pendiente"
                opciones={[
                  { valor: 'PAGADO', etiqueta: 'Pagado' },
                  { valor: 'PARCIAL', etiqueta: 'Parcial' },
                ]}
                value={f.estado_pago === 'PENDIENTE' ? '' : f.estado_pago}
                onChange={(e) => setF({ ...f, estado_pago: e.target.value || 'PENDIENTE' })}
              />
            </Campo>
          </RejillaForm>
          <Acciones>
            <Boton variante="primario" type="submit">
              Registrar costo
            </Boton>
          </Acciones>
        </form>
      )}
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}

function MetricasCampana({ campana, escribe, onCambio }) {
  const metricas = useDatos(() => listarMetricas(campana.id_campana), [campana.id_campana]);
  const canales = useDatos(() => listarCanales({ soloActivos: true }));
  const [f, setF] = useState({ periodo_inicio: hoyIso(), periodo_fin: hoyIso() });
  const [aviso, setAviso] = useState(null);
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (f.periodo_fin < f.periodo_inicio)
      return setAviso({
        tipo: 'error',
        texto: 'El fin del periodo no puede ser anterior al inicio.',
      });
    try {
      await registrarMetrica({ ...f, id_campana: campana.id_campana });
      setAviso({ tipo: 'ok', texto: 'Métrica registrada.' });
      setF({ periodo_inicio: hoyIso(), periodo_fin: hoyIso() });
      metricas.recargar();
      onCambio();
    } catch (err) {
      setAviso({ tipo: 'error', texto: error(err) });
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="px-[22px] py-5">
        {metricas.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={[
              'Periodo',
              'Canal',
              'Impresiones',
              'Alcance',
              'Clics',
              'Leads',
              'Conversiones',
              'Ingreso atribuido',
              'Fuente',
            ]}
            vacio="Sin métricas"
            rows={(metricas.datos ?? []).map((m) => [
              <Mono color="dim">
                {fechaCorta(m.periodo_inicio)} · {fechaCorta(m.periodo_fin)}
              </Mono>,
              <Texto dim>{m.canales_marketing?.nombre ?? 'toda la campaña'}</Texto>,
              <Mono>{miles(m.impresiones)}</Mono>,
              <Mono>{miles(m.alcance)}</Mono>,
              <Mono>{miles(m.clics)}</Mono>,
              <Mono>{miles(m.leads_generados)}</Mono>,
              <Mono bold>{miles(m.conversiones)}</Mono>,
              <Mono color="up">{pesos(m.ingreso_atribuido)}</Mono>,
              <Texto dim>{m.fuente_dato ?? '—'}</Texto>,
            ])}
          />
        )}
      </div>
      {escribe && (
        <form onSubmit={guardar} className="flex flex-col gap-3 border-t border-border pt-4">
          <RejillaForm columnas={3}>
            <Campo etiqueta="Desde">
              <Entrada type="date" {...campo('periodo_inicio')} />
            </Campo>
            <Campo etiqueta="Hasta">
              <Entrada type="date" {...campo('periodo_fin')} />
            </Campo>
            <Campo etiqueta="Canal">
              <Selector
                placeholder="Toda la campaña"
                opciones={(canales.datos ?? []).map((c) => ({
                  valor: c.id_canal,
                  etiqueta: c.nombre,
                }))}
                {...campo('id_canal')}
              />
            </Campo>
            <Campo etiqueta="Impresiones">
              <Entrada type="number" min="0" {...campo('impresiones')} />
            </Campo>
            <Campo etiqueta="Alcance">
              <Entrada type="number" min="0" {...campo('alcance')} />
            </Campo>
            <Campo etiqueta="Clics">
              <Entrada type="number" min="0" {...campo('clics')} />
            </Campo>
            <Campo etiqueta="Leads">
              <Entrada type="number" min="0" {...campo('leads_generados')} />
            </Campo>
            <Campo etiqueta="Conversiones">
              <Entrada type="number" min="0" {...campo('conversiones')} />
            </Campo>
            <Campo etiqueta="Ingreso atribuido">
              <Entrada type="number" min="0" step="0.01" {...campo('ingreso_atribuido')} />
            </Campo>
          </RejillaForm>
          <Campo etiqueta="Fuente del dato">
            <Entrada placeholder="Meta Ads, Google Analytics, Manual" {...campo('fuente_dato')} />
          </Campo>
          <Acciones>
            <Boton variante="primario" type="submit">
              Registrar métrica
            </Boton>
          </Acciones>
        </form>
      )}
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}

function ClientesCampana({ campana, escribe, onCambio }) {
  const clientes = useDatos(() => listarClientesCampana(campana.id_campana), [campana.id_campana]);
  const refs = useDatos(() =>
    Promise.all([listarClientesActivos(), listarCanales({ soloActivos: true })])
  );
  const [nuevo, setNuevo] = useState({ id_cliente: '', id_canal: '' });
  const [aviso, setAviso] = useState(null);
  const [activos, canales] = refs.datos ?? [[], []];
  const yaEstan = new Set((clientes.datos ?? []).map((c) => c.id_cliente));

  async function ejecutar(fn, textoOk) {
    try {
      await fn();
      setAviso({ tipo: 'ok', texto: textoOk });
      clientes.recargar();
      onCambio();
    } catch (err) {
      setAviso({ tipo: 'error', texto: error(err) });
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="px-[22px] py-5">
        {clientes.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={[
              'Folio',
              'Comercializador',
              'Estado',
              'Canal',
              'Contacto',
              'Estado de contacto',
            ]}
            vacio="Sin clientes objetivo; una campaña directa necesita al menos uno para activarse"
            rows={(clientes.datos ?? []).map((c) => [
              <Mono color="dim">{c.clientes?.numero_comercializador}</Mono>,
              <Texto bold>{c.clientes?.nombre_empresa}</Texto>,
              <Texto dim>{c.clientes?.estado ?? '—'}</Texto>,
              <Texto dim>{c.canales_marketing?.nombre ?? '—'}</Texto>,
              <Mono color="dim">{c.fecha_contacto ? fechaCorta(c.fecha_contacto) : '—'}</Mono>,
              escribe ? (
                <Selector
                  placeholder="objetivo"
                  className="min-w-[150px]"
                  opciones={['CONTACTADO', 'RESPONDIO', 'CONVERTIDO', 'NO_INTERESADO'].map((e) => ({
                    valor: e,
                    etiqueta: texto(e),
                  }))}
                  value={c.estado_contacto === 'OBJETIVO' ? '' : c.estado_contacto}
                  onChange={(e) =>
                    ejecutar(
                      () =>
                        actualizarContacto(c.id_campana, c.id_cliente, {
                          estado_contacto: e.target.value || 'OBJETIVO',
                          fecha_contacto: c.fecha_contacto ?? hoyIso(),
                        }),
                      'Estado de contacto actualizado.'
                    )
                  }
                />
              ) : (
                <StatusBadge status={c.estado_contacto} map={COLOR_CONTACTO} />
              ),
            ])}
          />
        )}
      </div>
      {escribe && (
        <form
          className="flex flex-col gap-3 border-t border-border pt-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (!nuevo.id_cliente) return;
            ejecutar(
              () => agregarClienteCampana({ ...nuevo, id_campana: campana.id_campana }),
              'Cliente objetivo agregado.'
            );
            setNuevo({ id_cliente: '', id_canal: '' });
          }}
        >
          <RejillaForm>
            <Campo etiqueta="Comercializador activo">
              <Selector
                opciones={activos
                  .filter((a) => !yaEstan.has(a.id_cliente))
                  .map((a) => ({ valor: a.id_cliente, etiqueta: a.nombre_empresa }))}
                value={nuevo.id_cliente}
                onChange={(e) => setNuevo({ ...nuevo, id_cliente: e.target.value })}
              />
            </Campo>
            <Campo etiqueta="Canal de contacto">
              <Selector
                opciones={canales.map((c) => ({ valor: c.id_canal, etiqueta: c.nombre }))}
                value={nuevo.id_canal}
                onChange={(e) => setNuevo({ ...nuevo, id_canal: e.target.value })}
              />
            </Campo>
          </RejillaForm>
          <Acciones>
            <Boton variante="primario" type="submit">
              Agregar cliente
            </Boton>
          </Acciones>
        </form>
      )}
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}

function ProductosCampana({ campana, escribe }) {
  const productos = useDatos(
    () => listarProductosCampana(campana.id_campana),
    [campana.id_campana]
  );
  const refs = useDatos(() => Promise.all([listarProductos(), listarBajaRotacion()]));
  const [nuevo, setNuevo] = useState('');
  const [aviso, setAviso] = useState(null);
  const [catalogo, bajaRotacion] = refs.datos ?? [[], []];
  const yaEstan = new Set((productos.datos ?? []).map((p) => p.id_producto));
  const candidatos = new Set(bajaRotacion.map((b) => b.id_producto));

  async function ejecutar(fn) {
    try {
      await fn();
      setAviso(null);
      productos.recargar();
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="px-[22px] py-5">
        <Table
          headers={['SKU', 'Producto', 'Tipo', '']}
          vacio="Sin productos promovidos"
          rows={(productos.datos ?? []).map((p) => [
            <Mono color="dim">{p.productos?.sku ?? '—'}</Mono>,
            <Texto bold>{p.productos?.nombre}</Texto>,
            <Tag color={p.productos?.tipo === 'ELECTRONICO' ? 'accent' : 'muted'}>
              {texto(p.productos?.tipo)}
            </Tag>,
            escribe ? (
              <Boton
                onClick={() =>
                  ejecutar(() => quitarProductoCampana(campana.id_campana, p.id_producto))
                }
              >
                Quitar
              </Boton>
            ) : null,
          ])}
        />
      </div>
      {escribe && (
        <form
          className="flex items-end gap-3 border-t border-border pt-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (!nuevo) return;
            ejecutar(() => agregarProductoCampana(campana.id_campana, nuevo));
            setNuevo('');
          }}
        >
          <div className="flex-1">
            <Campo etiqueta="Producto" ayuda="Los marcados con baja rotación son candidatos">
              <Selector
                opciones={catalogo
                  .filter((p) => !yaEstan.has(p.id_producto))
                  .map((p) => ({
                    valor: p.id_producto,
                    etiqueta: `${p.nombre}${candidatos.has(p.id_producto) ? ' · baja rotación' : ''}`,
                  }))}
                value={nuevo}
                onChange={(e) => setNuevo(e.target.value)}
              />
            </Campo>
          </div>
          <Boton variante="primario" type="submit">
            Agregar
          </Boton>
        </form>
      )}
      {aviso && <Mensaje>{aviso}</Mensaje>}
    </div>
  );
}

function Costos({ campanas }) {
  const datos = useDatos(() =>
    Promise.all([listarCostos(), listarCanales(), listarProveedoresMarketing()])
  );
  const [filtro, setFiltro] = useState({ proveedor: '', canal: '', campana: '' });
  if (datos.cargando) return <Cargando />;
  if (datos.error) return <Mensaje>{error(datos.error)}</Mensaje>;
  const [costos, canales, proveedores] = datos.datos;
  const filtrados = costos.filter(
    (c) =>
      (!filtro.proveedor || String(c.id_proveedor_marketing) === filtro.proveedor) &&
      (!filtro.canal || String(c.id_canal) === filtro.canal) &&
      (!filtro.campana || String(c.id_campana) === filtro.campana)
  );
  const porMes = Object.entries(
    filtrados.reduce((a, c) => {
      const mes = String(c.fecha_gasto).slice(0, 7);
      a[mes] = (a[mes] ?? 0) + Number(c.monto);
      return a;
    }, {})
  ).sort(([a], [b]) => b.localeCompare(a));
  const cambiar = (n) => (e) => setFiltro({ ...filtro, [n]: e.target.value });

  return (
    <div className="grid grid-cols-[1fr_260px] max-[960px]:grid-cols-1 gap-3.5">
      <Panel title="Costos de marketing">
        <div className="-mt-1 mb-6">
          <RejillaForm columnas={3}>
            <Campo etiqueta="Proveedor">
              <Selector
                placeholder="Todos"
                opciones={proveedores.map((p) => ({
                  valor: String(p.id_proveedor_marketing),
                  etiqueta: p.razon_social,
                }))}
                value={filtro.proveedor}
                onChange={cambiar('proveedor')}
              />
            </Campo>
            <Campo etiqueta="Canal">
              <Selector
                placeholder="Todos"
                opciones={canales.map((c) => ({ valor: String(c.id_canal), etiqueta: c.nombre }))}
                value={filtro.canal}
                onChange={cambiar('canal')}
              />
            </Campo>
            <Campo etiqueta="Campaña">
              <Selector
                placeholder="Todas"
                opciones={campanas.map((c) => ({
                  valor: String(c.id_campana),
                  etiqueta: c.nombre,
                }))}
                value={filtro.campana}
                onChange={cambiar('campana')}
              />
            </Campo>
          </RejillaForm>
        </div>
        <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
          <Table
            headers={['Fecha', 'Campaña', 'Concepto', 'Canal', 'Proveedor', 'Monto', 'Pago']}
            vacio="Sin costos con esos filtros"
            rows={filtrados.map((c) => [
              <Mono color="dim">{fechaCorta(c.fecha_gasto)}</Mono>,
              <Texto bold>{c.campanas?.nombre}</Texto>,
              <Texto>{c.concepto}</Texto>,
              <Texto dim>{c.canales_marketing?.nombre}</Texto>,
              <Texto dim>{c.proveedores_marketing?.razon_social ?? 'interno'}</Texto>,
              <Mono bold>{pesos(c.monto, { centavos: true })}</Mono>,
              <StatusBadge
                status={c.estado_pago}
                map={{ PAGADO: 'up', PENDIENTE: 'down', PARCIAL: 'accent', CANCELADO: 'muted' }}
              />,
            ])}
          />
        </div>
      </Panel>
      <Panel title="Total por mes">
        {porMes.length === 0 && <div className="text-[12px] text-text-dim">Sin costos.</div>}
        {porMes.map(([mes, total]) => (
          <div
            key={mes}
            className="flex justify-between py-2.5 border-b border-border last:border-b-0"
          >
            <Mono color="dim">{mes}</Mono>
            <Mono bold>{pesos(total, { centavos: true })}</Mono>
          </div>
        ))}
        <div className="flex justify-between pt-3">
          <span className="text-[11.5px] text-text-dim">Total</span>
          <Mono bold color="up">
            {pesos(
              filtrados.reduce((a, c) => a + Number(c.monto), 0),
              { centavos: true }
            )}
          </Mono>
        </div>
      </Panel>
    </div>
  );
}

function Investigaciones({ campanas, escribe, usuario }) {
  const lista = useDatos(listarInvestigaciones);
  const [sel, setSel] = useState(null);
  const [nueva, setNueva] = useState(false);
  if (lista.cargando && !lista.datos) return <Cargando />;
  if (lista.error) return <Mensaje>{error(lista.error)}</Mensaje>;
  const i = lista.datos.find((x) => x.id_investigacion === sel);

  return (
    <>
      <Panel
        title="Investigación de mercado"
        acciones={
          escribe && (
            <Boton variante="primario" onClick={() => setNueva(true)}>
              + Nueva investigación
            </Boton>
          )
        }
      >
        <Table
          headers={['Título', 'Tipo', 'Campaña', 'Muestra', 'Costo', 'Inicio', 'Estado']}
          onRowClick={(n) => setSel(lista.datos[n].id_investigacion)}
          vacio="Sin investigaciones"
          rows={lista.datos.map((x) => [
            <Texto bold>{x.titulo}</Texto>,
            <Tag color="accent">{texto(x.tipo)}</Tag>,
            <Texto dim>{x.campanas?.nombre ?? 'independiente'}</Texto>,
            <Mono>{x.tamano_muestra ? miles(x.tamano_muestra) : '—'}</Mono>,
            <Mono>{pesos(x.costo)}</Mono>,
            <Mono color="dim">{x.fecha_inicio ? fechaCorta(x.fecha_inicio) : '—'}</Mono>,
            <StatusBadge status={x.estado} map={COLOR_INVESTIGACION} />,
          ])}
        />
      </Panel>
      <Modal abierto={!!i} titulo={i?.titulo ?? ''} onCerrar={() => setSel(null)} ancho="max-w-2xl">
        {i && (
          <div className="flex flex-col gap-4">
            <div className="flex gap-2">
              <Tag color="accent">{texto(i.tipo)}</Tag>
              <StatusBadge status={i.estado} map={COLOR_INVESTIGACION} />
            </div>
            <RejillaForm columnas={3}>
              <Dato etiqueta="Campaña" valor={i.campanas?.nombre ?? 'Independiente'} />
              <Dato
                etiqueta="Proveedor"
                valor={i.proveedores_marketing?.razon_social ?? 'Interna'}
              />
              <Dato etiqueta="Muestra" valor={<Mono>{i.tamano_muestra ?? '—'}</Mono>} />
            </RejillaForm>
            <Dato etiqueta="Objetivo" valor={<Texto dim>{i.objetivo ?? '—'}</Texto>} />
            <Dato etiqueta="Metodología" valor={<Texto dim>{i.metodologia ?? '—'}</Texto>} />
            <Dato
              etiqueta="Hallazgos"
              valor={<Texto>{i.resumen_hallazgos ?? 'Pendientes'}</Texto>}
            />
            {i.url_reporte && (
              <a
                href={i.url_reporte}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[12.5px] text-accent"
              >
                Abrir reporte
              </a>
            )}
          </div>
        )}
      </Modal>
      <Modal
        abierto={nueva}
        titulo="Nueva investigación"
        onCerrar={() => setNueva(false)}
        ancho="max-w-2xl"
      >
        {nueva && (
          <FormInvestigacion
            campanas={campanas}
            usuario={usuario}
            onListo={() => {
              setNueva(false);
              lista.recargar();
            }}
          />
        )}
      </Modal>
    </>
  );
}

function FormInvestigacion({ campanas, usuario, onListo }) {
  const proveedores = useDatos(() => listarProveedoresMarketing({ soloActivos: true }));
  const [f, setF] = useState({ estado: 'PLANEADA' });
  const [aviso, setAviso] = useState('');
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (!f.titulo?.trim() || !f.tipo) return setAviso('Título y tipo son obligatorios.');
    try {
      await registrarInvestigacion(f, usuario?.id_usuario);
      onListo();
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <Campo etiqueta="Título">
        <Entrada {...campo('titulo')} />
      </Campo>
      <RejillaForm columnas={3}>
        <Campo etiqueta="Tipo">
          <Selector
            opciones={TIPOS_INVESTIGACION.map((t) => ({ valor: t, etiqueta: texto(t) }))}
            {...campo('tipo')}
          />
        </Campo>
        <Campo etiqueta="Campaña">
          <Selector
            placeholder="Independiente"
            opciones={campanas.map((c) => ({ valor: c.id_campana, etiqueta: c.nombre }))}
            {...campo('id_campana')}
          />
        </Campo>
        <Campo etiqueta="Proveedor">
          <Selector
            placeholder="Interna"
            opciones={(proveedores.datos ?? []).map((p) => ({
              valor: p.id_proveedor_marketing,
              etiqueta: p.razon_social,
            }))}
            {...campo('id_proveedor_marketing')}
          />
        </Campo>
        <Campo etiqueta="Muestra">
          <Entrada type="number" min="0" {...campo('tamano_muestra')} />
        </Campo>
        <Campo etiqueta="Costo">
          <Entrada type="number" min="0" step="0.01" {...campo('costo')} />
        </Campo>
        <Campo etiqueta="Estado">
          <Selector
            placeholder="Planeada"
            opciones={[
              { valor: 'EN_CURSO', etiqueta: 'En curso' },
              { valor: 'FINALIZADA', etiqueta: 'Finalizada' },
            ]}
            value={f.estado === 'PLANEADA' ? '' : f.estado}
            onChange={(e) => setF({ ...f, estado: e.target.value || 'PLANEADA' })}
          />
        </Campo>
        <Campo etiqueta="Inicio">
          <Entrada type="date" {...campo('fecha_inicio')} />
        </Campo>
        <Campo etiqueta="Fin">
          <Entrada type="date" {...campo('fecha_fin')} />
        </Campo>
        <Campo etiqueta="Enlace al reporte">
          <Entrada {...campo('url_reporte')} />
        </Campo>
      </RejillaForm>
      <Campo etiqueta="Objetivo">
        <AreaTexto {...campo('objetivo')} />
      </Campo>
      <Campo etiqueta="Metodología">
        <AreaTexto {...campo('metodologia')} />
      </Campo>
      <Campo etiqueta="Hallazgos">
        <AreaTexto {...campo('resumen_hallazgos')} />
      </Campo>
      {aviso && <Mensaje>{aviso}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onListo}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit">
          Guardar
        </Boton>
      </Acciones>
    </form>
  );
}

function Catalogos() {
  const datos = useDatos(() => Promise.all([listarCanales(), listarProveedoresMarketing()]));
  const [editando, setEditando] = useState(null);
  if (datos.cargando) return <Cargando />;
  if (datos.error) return <Mensaje>{error(datos.error)}</Mensaje>;
  const [canales, proveedores] = datos.datos;
  const alternar = async (tipo, fila) => {
    if (tipo === 'canal') await guardarCanal({ ...fila, activo: !fila.activo });
    else await guardarProveedorMarketing({ ...fila, activo: !fila.activo });
    datos.recargar();
  };

  return (
    <>
      <div className="grid grid-cols-2 max-[960px]:grid-cols-1 gap-3.5">
        <Panel
          title="Canales"
          acciones={
            <Boton
              variante="primario"
              onClick={() => setEditando({ tipo: 'canal', fila: { categoria: 'DIGITAL' } })}
            >
              + Canal
            </Boton>
          }
        >
          <Table
            headers={['Canal', 'Categoría', 'Estado', '']}
            rows={canales.map((c) => [
              <Texto bold>{c.nombre}</Texto>,
              <Tag color="muted">{texto(c.categoria)}</Tag>,
              <Tag color={c.activo ? 'up' : 'muted'}>{c.activo ? 'activo' : 'inactivo'}</Tag>,
              <span className="flex gap-2">
                <Boton onClick={() => setEditando({ tipo: 'canal', fila: c })}>Editar</Boton>
                <Boton onClick={() => alternar('canal', c)}>
                  {c.activo ? 'Dar de baja' : 'Reactivar'}
                </Boton>
              </span>,
            ])}
          />
        </Panel>
        <Panel
          title="Proveedores de marketing"
          acciones={
            <Boton
              variante="primario"
              onClick={() => setEditando({ tipo: 'proveedor', fila: { tipo_servicio: 'AGENCIA' } })}
            >
              + Proveedor
            </Boton>
          }
        >
          <Table
            headers={['Proveedor', 'Servicio', 'Contacto', 'Estado', '']}
            rows={proveedores.map((p) => [
              <Texto bold>{p.razon_social}</Texto>,
              <Tag color="accent">{texto(p.tipo_servicio)}</Tag>,
              <Texto dim>{p.contacto_email ?? p.contacto_nombre ?? '—'}</Texto>,
              <Tag color={p.activo ? 'up' : 'muted'}>{p.activo ? 'activo' : 'inactivo'}</Tag>,
              <span className="flex gap-2">
                <Boton onClick={() => setEditando({ tipo: 'proveedor', fila: p })}>Editar</Boton>
                <Boton onClick={() => alternar('proveedor', p)}>
                  {p.activo ? 'Dar de baja' : 'Reactivar'}
                </Boton>
              </span>,
            ])}
          />
        </Panel>
      </div>
      <Modal
        abierto={!!editando}
        titulo={editando?.tipo === 'canal' ? 'Canal' : 'Proveedor de marketing'}
        onCerrar={() => setEditando(null)}
      >
        {editando && (
          <FormCatalogo
            editando={editando}
            onListo={() => {
              setEditando(null);
              datos.recargar();
            }}
          />
        )}
      </Modal>
    </>
  );
}

function FormCatalogo({ editando, onListo }) {
  const [f, setF] = useState(editando.fila);
  const [aviso, setAviso] = useState('');
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });
  const canal = editando.tipo === 'canal';

  async function guardar(e) {
    e.preventDefault();
    if (canal ? !f.nombre?.trim() : !f.razon_social?.trim())
      return setAviso('El nombre es obligatorio.');
    try {
      if (canal) await guardarCanal(f);
      else await guardarProveedorMarketing(f);
      onListo();
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      {canal ? (
        <RejillaForm>
          <Campo etiqueta="Nombre">
            <Entrada {...campo('nombre')} />
          </Campo>
          <Campo etiqueta="Categoría">
            <Selector
              opciones={['TRADICIONAL', 'DIGITAL', 'DIRECTO', 'EVENTOS'].map((c) => ({
                valor: c,
                etiqueta: texto(c),
              }))}
              {...campo('categoria')}
            />
          </Campo>
          <Campo etiqueta="Descripción">
            <Entrada {...campo('descripcion')} />
          </Campo>
        </RejillaForm>
      ) : (
        <RejillaForm>
          <Campo etiqueta="Razón social">
            <Entrada {...campo('razon_social')} />
          </Campo>
          <Campo etiqueta="Servicio">
            <Selector
              opciones={[
                'AGENCIA',
                'MEDIO',
                'FREELANCER',
                'PLATAFORMA_DIGITAL',
                'ESTUDIO_MERCADO',
                'OTRO',
              ].map((c) => ({ valor: c, etiqueta: texto(c) }))}
              {...campo('tipo_servicio')}
            />
          </Campo>
          <Campo etiqueta="RFC">
            <Entrada {...campo('rfc')} />
          </Campo>
          <Campo etiqueta="Contacto">
            <Entrada {...campo('contacto_nombre')} />
          </Campo>
          <Campo etiqueta="Correo">
            <Entrada type="email" {...campo('contacto_email')} />
          </Campo>
          <Campo etiqueta="Teléfono">
            <Entrada {...campo('contacto_telefono')} />
          </Campo>
        </RejillaForm>
      )}
      {aviso && <Mensaje>{aviso}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onListo}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit">
          Guardar
        </Boton>
      </Acciones>
    </form>
  );
}
