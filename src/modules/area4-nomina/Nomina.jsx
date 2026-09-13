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
import {
  miles,
  pesos,
  porcentaje,
  fechaCorta,
  periodoCorto,
  periodoActual,
  hoyIso,
} from '@/lib/formato';
import { exportarCsv } from '@/lib/exportar';
import {
  ROLES_PASO,
  listarPeriodos,
  abrirPeriodoMensual,
  calcularPeriodo,
  revisarPeriodo,
  rechazarPeriodo,
  autorizarPeriodo,
  pagarPeriodo,
  cerrarPeriodo,
  obtenerTotales,
  obtenerRecibo,
  obtenerDesempeno,
  obtenerRetenciones,
} from '@/services/area4/nomina';
import {
  listarAgentes,
  guardarAgente,
  listarZonas,
  crearZona,
  listarEsquemas,
  crearTramo,
  listarCumplimiento,
  guardarMeta,
} from '@/services/area4/agentes';

const PESTANAS = [
  { id: 'periodos', etiqueta: 'Periodos' },
  { id: 'recibos', etiqueta: 'Recibos y dispersión' },
  { id: 'reportes', etiqueta: 'Reportes' },
  { id: 'agentes', etiqueta: 'Agentes' },
  { id: 'metas', etiqueta: 'Metas' },
  { id: 'catalogos', etiqueta: 'Zonas y esquemas' },
];

const COLOR_PERIODO = {
  ABIERTO: 'muted',
  CALCULADO: 'accent',
  REVISADO: 'accent',
  AUTORIZADO: 'up',
  PAGADO: 'up',
  CERRADO: 'muted',
};
const COLOR_AGENTE = { ACTIVO: 'up', SUSPENDIDO: 'accent', BAJA: 'down' };

const periodoDe = (p) => String(p.fecha_inicio).slice(0, 7);

export default function Nomina() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'nomina');
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('periodos');
  const periodos = useDatos(listarPeriodos);
  const ultimo = periodos.datos?.[0];
  const totales = useDatos(
    () => (ultimo ? obtenerTotales(ultimo.id_periodo) : Promise.resolve([])),
    [ultimo?.id_periodo, ultimo?.estatus]
  );
  const agentes = useDatos(listarAgentes);

  useEffect(() => {
    set({
      acciones: (
        <Boton
          onClick={() =>
            exportarCsv(`nomina-${ultimo ? periodoDe(ultimo) : ''}`, totales.datos ?? [])
          }
        >
          Exportar
        </Boton>
      ),
    });
    return () => set({});
  }, [set, totales.datos, ultimo]);

  if ((periodos.cargando && !periodos.datos) || (agentes.cargando && !agentes.datos))
    return <Cargando />;
  if (periodos.error || agentes.error)
    return <Mensaje>{mensajeDeError(periodos.error ?? agentes.error)}</Mensaje>;

  const filas = totales.datos ?? [];
  const neto = filas.reduce((a, t) => a + Number(t.neto), 0);
  const percepciones = filas.reduce((a, t) => a + Number(t.percepciones), 0);
  const activos = agentes.datos.filter((a) => a.estatus === 'ACTIVO');
  const zonas = new Set(activos.map((a) => a.zonas?.nombre).filter(Boolean)).size;
  const recargar = () => {
    periodos.recargar();
    totales.recargar();
  };

  return (
    <>
      <FilaKpi>
        <KpiCard
          label={`Nómina ${ultimo ? periodoCorto(periodoDe(ultimo)) : ''}`}
          value={pesos(neto)}
          delta={pesos(percepciones)}
          up
          sub="percepciones"
        />
        <KpiCard
          label="Agentes activos"
          value={miles(activos.length)}
          delta={`${zonas} zonas`}
          up
        />
        <KpiCard
          label="Percepción promedio"
          value={pesos(filas.length ? percepciones / filas.length : 0)}
          delta={`${filas.length} recibos`}
          up
        />
        <KpiCard
          label="Estado del periodo"
          value={ultimo ? ultimo.estatus.toLowerCase() : 'sin periodo'}
          delta={
            ultimo?.fecha_pago
              ? `pagado ${fechaCorta(ultimo.fecha_pago)}`
              : ultimo
                ? `cierra ${fechaCorta(ultimo.fecha_fin)}`
                : '—'
          }
          up={['AUTORIZADO', 'PAGADO', 'CERRADO'].includes(ultimo?.estatus)}
        />
      </FilaKpi>

      <Pestanas opciones={PESTANAS} activa={pestana} onCambiar={setPestana} />

      {pestana === 'periodos' && (
        <Periodos
          periodos={periodos.datos}
          usuario={usuario}
          escribe={escribe}
          onCambio={recargar}
        />
      )}
      {pestana === 'recibos' && <Recibos periodos={periodos.datos} agentes={agentes.datos} />}
      {pestana === 'reportes' && <Reportes periodos={periodos.datos} />}
      {pestana === 'agentes' && (
        <Agentes
          agentes={agentes.datos}
          escribe={escribe && usuario?.rol === 'ADMINISTRADOR'}
          onCambio={agentes.recargar}
        />
      )}
      {pestana === 'metas' && <Metas agentes={activos} escribe={escribe} />}
      {pestana === 'catalogos' && <Catalogos escribe={usuario?.rol === 'ADMINISTRADOR'} />}
    </>
  );
}

function Periodos({ periodos, usuario, escribe, onCambio }) {
  const [sel, setSel] = useState(null);
  const [nuevo, setNuevo] = useState(false);
  const seleccionado = periodos.find((p) => p.id_periodo === sel);
  return (
    <>
      <Panel
        title="Periodos de nómina"
        acciones={
          escribe &&
          ROLES_PASO.calcular.includes(usuario?.rol) && (
            <Boton variante="primario" onClick={() => setNuevo(true)}>
              + Abrir periodo
            </Boton>
          )
        }
      >
        <Table
          headers={[
            'Periodo',
            'Tipo',
            'Del',
            'Al',
            'Estado',
            'Calculó',
            'Revisó',
            'Autorizó',
            'Pago',
          ]}
          onRowClick={(i) => setSel(periodos[i].id_periodo)}
          vacio="No hay periodos abiertos"
          rows={periodos.map((p) => [
            <Mono bold>{periodoCorto(periodoDe(p))}</Mono>,
            <Tag color="muted">{p.tipo.toLowerCase()}</Tag>,
            <Mono color="dim">{fechaCorta(p.fecha_inicio)}</Mono>,
            <Mono color="dim">{fechaCorta(p.fecha_fin)}</Mono>,
            <StatusBadge status={p.estatus} map={COLOR_PERIODO} />,
            <Texto dim>{p.calculado_por ?? '—'}</Texto>,
            <Texto dim>{p.revisado_por ?? '—'}</Texto>,
            <Texto dim>{p.autorizado_por ?? '—'}</Texto>,
            <Mono color={p.fecha_pago ? 'up' : 'dim'}>
              {p.fecha_pago ? fechaCorta(p.fecha_pago) : '—'}
            </Mono>,
          ])}
        />
      </Panel>
      <Modal abierto={nuevo} titulo="Abrir periodo mensual" onCerrar={() => setNuevo(false)}>
        {nuevo && (
          <FormPeriodo
            onListo={() => {
              setNuevo(false);
              onCambio();
            }}
          />
        )}
      </Modal>
      <Modal
        abierto={!!seleccionado}
        titulo={`Periodo ${seleccionado ? periodoCorto(periodoDe(seleccionado)) : ''}`}
        onCerrar={() => setSel(null)}
        ancho="max-w-3xl"
      >
        {seleccionado && (
          <DetallePeriodo periodo={seleccionado} usuario={usuario} onCambio={onCambio} />
        )}
      </Modal>
    </>
  );
}

function FormPeriodo({ onListo }) {
  const [periodo, setPeriodo] = useState(periodoActual());
  const [error, setError] = useState('');
  async function guardar(e) {
    e.preventDefault();
    try {
      await abrirPeriodoMensual(periodo);
      onListo();
    } catch (err) {
      setError(
        /uq_periodo|duplicate/i.test(err.message)
          ? 'Ese periodo ya está abierto.'
          : mensajeDeError(err)
      );
    }
  }
  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <Campo
        etiqueta="Mes"
        ayuda="Comisiones y bonos se pagan una vez al mes; las quincenas son fase 2"
      >
        <Entrada type="month" value={periodo} onChange={(e) => setPeriodo(e.target.value)} />
      </Campo>
      <Mensaje tipo="info">
        Antes de calcular, cada agente activo necesita su meta del mes (RN-A4-03).
      </Mensaje>
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onListo}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit">
          Abrir periodo
        </Boton>
      </Acciones>
    </form>
  );
}

function DetallePeriodo({ periodo, usuario, onCambio }) {
  const totales = useDatos(
    () => obtenerTotales(periodo.id_periodo),
    [periodo.id_periodo, periodo.estatus]
  );
  const [aviso, setAviso] = useState(null);
  const [rechazo, setRechazo] = useState(null);
  const [enviando, setEnviando] = useState(false);
  const rol = usuario?.rol;
  const correo = usuario?.correo;
  const puede = (paso) => ROLES_PASO[paso].includes(rol);

  async function ejecutar(fn, texto) {
    setEnviando(true);
    setAviso(null);
    try {
      await fn();
      setAviso({ tipo: 'ok', texto });
      setRechazo(null);
      onCambio();
      totales.recargar();
    } catch (err) {
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    } finally {
      setEnviando(false);
    }
  }

  const mismoQueCalculo = periodo.calculado_por && periodo.calculado_por === correo;

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3">
        <StatusBadge status={periodo.estatus} map={COLOR_PERIODO} />
        <span className="text-[12px] text-text-dim">
          {fechaCorta(periodo.fecha_inicio)} al {fechaCorta(periodo.fecha_fin)}
        </span>
      </div>
      {periodo.comentario && <Mensaje tipo="info">Último rechazo: {periodo.comentario}</Mensaje>}

      <div className="px-[22px] py-5">
        {totales.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['Agente', 'Percepciones', 'Deducciones', 'Neto', 'CLABE']}
            vacio="Aún no se calcula este periodo"
            rows={(totales.datos ?? []).map((t) => [
              <Texto bold>{t.nombre}</Texto>,
              <Mono color="up">{pesos(t.percepciones, { centavos: true })}</Mono>,
              <Mono color="down">{pesos(t.deducciones, { centavos: true })}</Mono>,
              <Mono bold>{pesos(t.neto, { centavos: true })}</Mono>,
              <Mono color="dim">{t.clabe ?? '—'}</Mono>,
            ])}
          />
        )}
      </div>

      <div className="flex flex-wrap gap-2 border-t border-border pt-4">
        {periodo.estatus === 'ABIERTO' && puede('calcular') && (
          <Boton
            variante="primario"
            disabled={enviando}
            onClick={() =>
              ejecutar(
                () => calcularPeriodo(periodo.id_periodo, correo),
                'Periodo calculado: comisiones y bonos generados.'
              )
            }
          >
            Calcular
          </Boton>
        )}
        {periodo.estatus === 'CALCULADO' && puede('revisar') && (
          <>
            <Boton
              variante="primario"
              disabled={enviando}
              onClick={() =>
                ejecutar(
                  () => revisarPeriodo(periodo.id_periodo, correo),
                  'Periodo revisado; ISR, IMSS y ajustes calculados.'
                )
              }
            >
              Revisar y aprobar
            </Boton>
            <Boton variante="peligro" disabled={enviando} onClick={() => setRechazo('')}>
              Rechazar
            </Boton>
          </>
        )}
        {periodo.estatus === 'REVISADO' && puede('autorizar') && (
          <Boton
            variante="primario"
            disabled={enviando || mismoQueCalculo}
            title={mismoQueCalculo ? 'Quien calculó no puede autorizar (RN-A4-15)' : undefined}
            onClick={() =>
              ejecutar(() => autorizarPeriodo(periodo.id_periodo, correo), 'Periodo autorizado.')
            }
          >
            Autorizar
          </Boton>
        )}
        {periodo.estatus === 'AUTORIZADO' && puede('pagar') && (
          <Boton
            variante="primario"
            disabled={enviando}
            onClick={() =>
              ejecutar(
                () => pagarPeriodo(periodo.id_periodo, hoyIso()),
                'Periodo marcado como pagado.'
              )
            }
          >
            Registrar pago
          </Boton>
        )}
        {periodo.estatus === 'PAGADO' && puede('pagar') && (
          <Boton
            disabled={enviando}
            onClick={() => ejecutar(() => cerrarPeriodo(periodo.id_periodo), 'Periodo cerrado.')}
          >
            Cerrar periodo
          </Boton>
        )}
        {['AUTORIZADO', 'PAGADO', 'CERRADO'].includes(periodo.estatus) && (
          <Boton
            onClick={() =>
              exportarCsv(`dispersion-${periodoDe(periodo)}`, totales.datos ?? [], [
                { campo: 'nombre', titulo: 'Nombre' },
                { campo: 'clabe', titulo: 'CLABE' },
                { campo: 'neto', titulo: 'Neto' },
              ])
            }
          >
            Layout de dispersión CSV
          </Boton>
        )}
      </div>
      {mismoQueCalculo && periodo.estatus === 'REVISADO' && (
        <Mensaje tipo="info">
          Calculaste este periodo; otro usuario debe autorizarlo (RN-A4-15).
        </Mensaje>
      )}

      {rechazo !== null && (
        <form
          className="flex flex-col gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            if (!rechazo.trim())
              return setAviso({
                tipo: 'error',
                texto: 'El rechazo exige un comentario (RN-A4-13).',
              });
            ejecutar(
              () => rechazarPeriodo(periodo.id_periodo, correo, rechazo.trim()),
              'Periodo regresado a ABIERTO.'
            );
          }}
        >
          <Campo etiqueta="Motivo del rechazo">
            <AreaTexto value={rechazo} onChange={(e) => setRechazo(e.target.value)} />
          </Campo>
          <Acciones>
            <Boton type="button" onClick={() => setRechazo(null)}>
              Cancelar
            </Boton>
            <Boton variante="peligro" type="submit" disabled={enviando}>
              Rechazar periodo
            </Boton>
          </Acciones>
        </form>
      )}
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}

function Recibos({ periodos, agentes }) {
  const [sel, setSel] = useState({ id_periodo: periodos[0]?.id_periodo ?? '', id_agente: '' });
  const recibo = useDatos(
    () =>
      sel.id_periodo && sel.id_agente
        ? obtenerRecibo(Number(sel.id_periodo), Number(sel.id_agente))
        : Promise.resolve([]),
    [sel.id_periodo, sel.id_agente]
  );
  const filas = recibo.datos ?? [];
  const percepciones = filas.filter((r) => r.tipo_concepto === 'PERCEPCION');
  const deducciones = filas.filter((r) => r.tipo_concepto === 'DEDUCCION');
  const suma = (l) => l.reduce((a, r) => a + Number(r.monto), 0);

  return (
    <Panel title="Recibo de nómina por agente">
      <div className="-mt-1 mb-6">
        <RejillaForm columnas={3}>
          <Campo etiqueta="Periodo">
            <Selector
              opciones={periodos.map((p) => ({
                valor: p.id_periodo,
                etiqueta: `${periodoCorto(periodoDe(p))} · ${p.estatus.toLowerCase()}`,
              }))}
              value={sel.id_periodo}
              onChange={(e) => setSel({ ...sel, id_periodo: e.target.value })}
            />
          </Campo>
          <Campo etiqueta="Agente">
            <Selector
              opciones={agentes.map((a) => ({ valor: a.id_agente, etiqueta: a.nombre }))}
              value={sel.id_agente}
              onChange={(e) => setSel({ ...sel, id_agente: e.target.value })}
            />
          </Campo>
        </RejillaForm>
      </div>
      <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
        {recibo.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['Concepto', 'Tipo', 'Clave SAT', 'Monto', 'Gravado', 'Exento']}
            vacio={sel.id_agente ? 'Sin renglones para ese agente y periodo' : 'Elige un agente'}
            rows={filas.map((r) => [
              <Texto bold>{r.concepto.toLowerCase().replaceAll('_', ' ')}</Texto>,
              <Tag color={r.tipo_concepto === 'PERCEPCION' ? 'up' : 'down'}>
                {r.tipo_concepto.toLowerCase()}
              </Tag>,
              <Mono color="dim">{r.clave_sat}</Mono>,
              <Mono bold color={r.tipo_concepto === 'PERCEPCION' ? 'text' : 'down'}>
                {pesos(r.monto, { centavos: true })}
              </Mono>,
              <Mono color="dim">
                {r.tipo_concepto === 'PERCEPCION' ? pesos(r.gravado, { centavos: true }) : '—'}
              </Mono>,
              <Mono color="dim">
                {r.tipo_concepto === 'PERCEPCION' ? pesos(r.exento, { centavos: true }) : '—'}
              </Mono>,
            ])}
          />
        )}
      </div>
      {filas.length > 0 && (
        <div className="flex justify-end gap-8 border-t border-border pt-3 mt-5">
          <Resumen
            etiqueta="Percepciones"
            valor={<Mono color="up">{pesos(suma(percepciones), { centavos: true })}</Mono>}
          />
          <Resumen
            etiqueta="Deducciones"
            valor={<Mono color="down">{pesos(suma(deducciones), { centavos: true })}</Mono>}
          />
          <Resumen
            etiqueta="Neto a pagar"
            valor={
              <Mono bold>{pesos(suma(percepciones) - suma(deducciones), { centavos: true })}</Mono>
            }
          />
        </div>
      )}
      {filas.length > 0 && (
        <div className="text-[11px] text-muted mt-3">
          INFONAVIT fuera del alcance de esta versión (pregunta abierta 4).
        </div>
      )}
    </Panel>
  );
}

function Resumen({ etiqueta, valor }) {
  return (
    <div>
      <div className="text-[10.5px] uppercase tracking-[0.04em] text-text-dim mb-1">{etiqueta}</div>
      <div className="text-[13px]">{valor}</div>
    </div>
  );
}

function Reportes({ periodos }) {
  const [id, setId] = useState(periodos[0]?.id_periodo ?? '');
  const periodo = periodos.find((p) => String(p.id_periodo) === String(id));
  const datos = useDatos(
    () =>
      periodo
        ? Promise.all([
            obtenerTotales(periodo.id_periodo),
            obtenerDesempeno(periodoDe(periodo)),
            obtenerRetenciones(periodo.id_periodo),
          ])
        : Promise.resolve([[], [], []]),
    [periodo?.id_periodo]
  );
  const [totales, desempeno, retenciones] = datos.datos ?? [[], [], []];
  const porAgente = useMemo(
    () => Object.fromEntries(totales.map((t) => [t.id_agente, t])),
    [totales]
  );

  return (
    <>
      <div className="max-w-xs">
        <Campo etiqueta="Periodo">
          <Selector
            opciones={periodos.map((p) => ({
              valor: p.id_periodo,
              etiqueta: periodoCorto(periodoDe(p)),
            }))}
            value={id}
            onChange={(e) => setId(e.target.value)}
          />
        </Campo>
      </div>
      {datos.cargando ? (
        <Cargando />
      ) : datos.error ? (
        <Mensaje>{mensajeDeError(datos.error)}</Mensaje>
      ) : (
        <>
          <Panel title="Comisiones y cumplimiento por agente y zona">
            <Table
              headers={[
                'Zona',
                'Agente',
                'Meta',
                'Cobrado sin IVA',
                'Cumplimiento',
                'Percepciones',
                'Costo sobre ventas',
              ]}
              rows={desempeno.map((d) => {
                const perc = Number(porAgente[d.id_agente]?.percepciones ?? 0);
                const ventas = Number(d.ventas_cobradas);
                return [
                  <Texto dim>{d.zona ?? '—'}</Texto>,
                  <Texto bold>{d.nombre}</Texto>,
                  <Mono>{pesos(d.monto_meta)}</Mono>,
                  <Mono color="up">{pesos(ventas)}</Mono>,
                  <Mono
                    bold
                    color={
                      Number(d.pct_cumplimiento) >= 100
                        ? 'up'
                        : Number(d.pct_cumplimiento) >= 70
                          ? 'accent'
                          : 'down'
                    }
                  >
                    {porcentaje(d.pct_cumplimiento, 2)}
                  </Mono>,
                  <Mono>{pesos(perc, { centavos: true })}</Mono>,
                  <Mono color="dim">
                    {ventas > 0 ? porcentaje((perc / ventas) * 100, 2) : 'sin ventas'}
                  </Mono>,
                ];
              })}
            />
          </Panel>
          <Panel title="Retenciones y base de ISN por entidad (contrato con Regulación)">
            <Table
              headers={['Entidad', 'ISR retenido', 'IMSS obrero', 'Base ISN', 'ISN estimado']}
              vacio="Se publica cuando el periodo está AUTORIZADO, PAGADO o CERRADO"
              rows={retenciones.map((r) => [
                <Texto bold>{r.entidad_federativa ?? '—'}</Texto>,
                <Mono>{pesos(r.isr_retenido, { centavos: true })}</Mono>,
                <Mono>{pesos(r.imss_obrero, { centavos: true })}</Mono>,
                <Mono>{pesos(r.base_isn, { centavos: true })}</Mono>,
                <Mono bold color="accent">
                  {pesos(r.isn_estimado, { centavos: true })}
                </Mono>,
              ])}
            />
          </Panel>
        </>
      )}
    </>
  );
}

function Agentes({ agentes, escribe, onCambio }) {
  const [editando, setEditando] = useState(null);
  return (
    <>
      <Panel
        title="Agentes de ventas"
        acciones={
          escribe && (
            <Boton
              variante="primario"
              onClick={() => setEditando({ salario_diario: 350, estatus: 'ACTIVO' })}
            >
              + Nuevo agente
            </Boton>
          )
        }
      >
        <Table
          headers={[
            'Agente',
            'RFC',
            'Zona',
            'Esquema',
            'Salario diario',
            'Entidad',
            'Ingreso',
            'Estatus',
            '',
          ]}
          rows={agentes.map((a) => [
            <Texto bold>{a.nombre}</Texto>,
            <Mono color="dim">{a.rfc ?? '—'}</Mono>,
            <span className="flex items-center gap-2">
              <Texto dim>{a.zonas?.nombre ?? 'sin zona'}</Texto>
              {a.zonas?.zona_salarial === 'ZLFN' && <Tag color="accent">zlfn</Tag>}
            </span>,
            <Texto dim>{a.esquemas_compensacion?.nombre ?? 'tasa fija'}</Texto>,
            <Mono>{pesos(a.salario_diario, { centavos: true })}</Mono>,
            <Texto dim>{a.entidad_federativa ?? '—'}</Texto>,
            <Mono color="dim">{a.fecha_ingreso ? fechaCorta(a.fecha_ingreso) : '—'}</Mono>,
            <StatusBadge status={a.estatus} map={COLOR_AGENTE} />,
            escribe ? <Boton onClick={() => setEditando(a)}>Editar</Boton> : null,
          ])}
        />
      </Panel>
      <Modal
        abierto={!!editando}
        titulo={editando?.id_agente ? 'Editar agente' : 'Nuevo agente'}
        onCerrar={() => setEditando(null)}
        ancho="max-w-2xl"
      >
        {editando && (
          <FormAgente
            inicial={editando}
            onListo={() => {
              setEditando(null);
              onCambio();
            }}
          />
        )}
      </Modal>
    </>
  );
}

function FormAgente({ inicial, onListo }) {
  const catalogos = useDatos(() => Promise.all([listarZonas(), listarEsquemas()]));
  const [f, setF] = useState({
    ...inicial,
    id_zona: inicial.id_zona ?? '',
    id_esquema: inicial.id_esquema ?? '',
  });
  const [error, setError] = useState('');
  if (catalogos.cargando) return <Cargando />;
  const [zonas, esquemas] = catalogos.datos ?? [[], []];
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (!f.nombre?.trim()) return setError('El nombre es obligatorio.');
    if (f.estatus === 'ACTIVO' && (!f.id_zona || !f.id_esquema))
      return setError('Un agente activo necesita zona y esquema (RN-A4-02).');
    setError('');
    try {
      const zona = zonas.find((z) => String(z.id_zona) === String(f.id_zona));
      await guardarAgente({ ...f, entidad_federativa: f.entidad_federativa || zona?.entidad });
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Campo etiqueta="Nombre">
          <Entrada {...campo('nombre')} />
        </Campo>
        <Campo etiqueta="RFC">
          <Entrada {...campo('rfc')} />
        </Campo>
        <Campo etiqueta="CURP">
          <Entrada {...campo('curp')} />
        </Campo>
        <Campo etiqueta="NSS">
          <Entrada {...campo('nss')} />
        </Campo>
        <Campo etiqueta="Ingreso">
          <Entrada type="date" {...campo('fecha_ingreso')} />
        </Campo>
        <Campo etiqueta="CLABE">
          <Entrada {...campo('clabe')} />
        </Campo>
        <Campo etiqueta="Zona">
          <Selector
            opciones={zonas.map((z) => ({
              valor: z.id_zona,
              etiqueta: `${z.nombre} · ${z.zona_salarial}`,
            }))}
            {...campo('id_zona')}
          />
        </Campo>
        <Campo etiqueta="Esquema">
          <Selector
            opciones={esquemas.map((s) => ({ valor: s.id_esquema, etiqueta: s.nombre }))}
            {...campo('id_esquema')}
          />
        </Campo>
        <Campo etiqueta="Salario diario" ayuda="No menor al mínimo de su zona">
          <Entrada type="number" step="0.01" {...campo('salario_diario')} />
        </Campo>
        <Campo etiqueta="Entidad" ayuda="Define la tasa de ISN">
          <Entrada placeholder="La de la zona" {...campo('entidad_federativa')} />
        </Campo>
        <Campo etiqueta="Estatus">
          <Selector
            placeholder="Activo"
            opciones={[
              { valor: 'SUSPENDIDO', etiqueta: 'Suspendido' },
              { valor: 'BAJA', etiqueta: 'Baja' },
            ]}
            value={f.estatus === 'ACTIVO' ? '' : f.estatus}
            onChange={(e) => setF({ ...f, estatus: e.target.value || 'ACTIVO' })}
          />
        </Campo>
      </RejillaForm>
      {error && <Mensaje>{error}</Mensaje>}
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

function Metas({ agentes, escribe }) {
  const [periodo, setPeriodo] = useState(periodoActual());
  const cumplimiento = useDatos(() => listarCumplimiento(periodo), [periodo]);
  const [f, setF] = useState({ id_agente: '', monto_meta: '', sin_retardos: true });
  const [aviso, setAviso] = useState(null);
  const porAgente = Object.fromEntries((cumplimiento.datos ?? []).map((c) => [c.id_agente, c]));
  const nombre = Object.fromEntries(agentes.map((a) => [a.id_agente, a.nombre]));

  async function guardar(e) {
    e.preventDefault();
    if (!f.id_agente || !(Number(f.monto_meta) > 0))
      return setAviso({ tipo: 'error', texto: 'Elige el agente y una meta mayor a cero.' });
    try {
      await guardarMeta({ ...f, periodo });
      setAviso({ tipo: 'ok', texto: 'Meta guardada.' });
      setF({ id_agente: '', monto_meta: '', sin_retardos: true });
      cumplimiento.recargar();
    } catch (err) {
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    }
  }

  return (
    <Panel title="Metas y cumplimiento del mes">
      <div className="-mt-1 mb-6 flex flex-col gap-4">
        <div className="max-w-xs">
          <Campo etiqueta="Mes">
            <Entrada type="month" value={periodo} onChange={(e) => setPeriodo(e.target.value)} />
          </Campo>
        </div>
        {escribe && (
          <form onSubmit={guardar} className="flex flex-col gap-3">
            <RejillaForm columnas={3}>
              <Campo etiqueta="Agente">
                <Selector
                  opciones={agentes.map((a) => ({ valor: a.id_agente, etiqueta: a.nombre }))}
                  value={f.id_agente}
                  onChange={(e) => setF({ ...f, id_agente: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Meta sin IVA">
                <Entrada
                  type="number"
                  min="1"
                  value={f.monto_meta}
                  onChange={(e) => setF({ ...f, monto_meta: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Puntualidad" ayuda="Bandera manual del premio">
                <Selector
                  placeholder="Sin retardos"
                  opciones={[{ valor: 'no', etiqueta: 'Con retardos' }]}
                  value={f.sin_retardos ? '' : 'no'}
                  onChange={(e) => setF({ ...f, sin_retardos: e.target.value !== 'no' })}
                />
              </Campo>
            </RejillaForm>
            <Acciones>
              <Boton variante="primario" type="submit">
                Guardar meta
              </Boton>
            </Acciones>
          </form>
        )}
        {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
      </div>
      <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
        {cumplimiento.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['Agente', 'Meta', 'Cobrado sin IVA', 'Cumplimiento', 'Tramo esperado']}
            rows={agentes.map((a) => {
              const c = porAgente[a.id_agente];
              const pct = Number(c?.pct_cumplimiento ?? 0);
              return [
                <Texto bold>{nombre[a.id_agente]}</Texto>,
                <Mono color={c ? 'text' : 'down'}>{c ? pesos(c.monto_meta) : 'sin meta'}</Mono>,
                <Mono color="up">{c ? pesos(c.ventas_cobradas) : '—'}</Mono>,
                <Mono bold color={pct >= 100 ? 'up' : pct >= 70 ? 'accent' : 'down'}>
                  {c ? porcentaje(pct, 2) : '—'}
                </Mono>,
                <Tag color={!c ? 'muted' : pct >= 100 ? 'up' : 'accent'}>
                  {!c
                    ? 'pendiente'
                    : pct >= 120
                      ? '3.5 %'
                      : pct >= 100
                        ? '3 %'
                        : pct >= 70
                          ? '2 %'
                          : '1 %'}
                </Tag>,
              ];
            })}
          />
        )}
      </div>
    </Panel>
  );
}

function Catalogos({ escribe }) {
  const datos = useDatos(() => Promise.all([listarZonas(), listarEsquemas()]));
  const [zona, setZona] = useState({ zona_salarial: 'GENERAL' });
  const [tramo, setTramo] = useState({});
  const [aviso, setAviso] = useState(null);
  if (datos.cargando) return <Cargando />;
  if (datos.error) return <Mensaje>{mensajeDeError(datos.error)}</Mensaje>;
  const [zonas, esquemas] = datos.datos;

  async function ejecutar(fn, texto) {
    try {
      await fn();
      setAviso({ tipo: 'ok', texto });
      datos.recargar();
    } catch (err) {
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    }
  }

  return (
    <div className="grid grid-cols-2 max-[960px]:grid-cols-1 gap-3.5">
      <Panel title="Zonas">
        <Table
          headers={['Zona', 'Región', 'Zona salarial', 'Entidad']}
          rows={zonas.map((z) => [
            <Texto bold>{z.nombre}</Texto>,
            <Texto dim>{z.region ?? '—'}</Texto>,
            <Tag color={z.zona_salarial === 'ZLFN' ? 'accent' : 'muted'}>
              {z.zona_salarial.toLowerCase()}
            </Tag>,
            <Texto dim>{z.entidad ?? '—'}</Texto>,
          ])}
        />
        {escribe && (
          <form
            className="flex flex-col gap-3 border-t border-border pt-4 mt-5"
            onSubmit={(e) => {
              e.preventDefault();
              if (!zona.nombre?.trim()) return;
              ejecutar(() => crearZona(zona), 'Zona creada.');
            }}
          >
            <RejillaForm>
              <Campo etiqueta="Nombre">
                <Entrada
                  value={zona.nombre ?? ''}
                  onChange={(e) => setZona({ ...zona, nombre: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Región">
                <Entrada
                  value={zona.region ?? ''}
                  onChange={(e) => setZona({ ...zona, region: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Zona salarial">
                <Selector
                  placeholder="General"
                  opciones={[{ valor: 'ZLFN', etiqueta: 'Frontera norte' }]}
                  value={zona.zona_salarial === 'GENERAL' ? '' : 'ZLFN'}
                  onChange={(e) => setZona({ ...zona, zona_salarial: e.target.value || 'GENERAL' })}
                />
              </Campo>
              <Campo etiqueta="Entidad">
                <Entrada
                  value={zona.entidad ?? ''}
                  onChange={(e) => setZona({ ...zona, entidad: e.target.value })}
                />
              </Campo>
            </RejillaForm>
            <Acciones>
              <Boton variante="primario" type="submit">
                Agregar zona
              </Boton>
            </Acciones>
          </form>
        )}
      </Panel>
      <Panel title="Esquemas y tramos de comisión">
        {esquemas.map((s) => (
          <div key={s.id_esquema} className="mb-5 last:mb-0">
            <div className="text-[12.5px] font-medium">{s.nombre}</div>
            <div className="text-[11px] text-text-dim mb-2">
              Vigente desde {fechaCorta(s.vigencia_inicio)}
            </div>
            {[...s.tramos_comision]
              .sort((a, b) => a.pct_min - b.pct_min)
              .map((t) => (
                <div
                  key={t.id_tramo}
                  className="flex justify-between py-1.5 border-b border-border last:border-b-0"
                >
                  <Mono color="dim">
                    {Number(t.pct_min)} % a{' '}
                    {t.pct_max === null ? 'sin tope' : `${Number(t.pct_max)} %`}
                  </Mono>
                  <Mono bold color="accent">
                    {(Number(t.tasa) * 100).toFixed(2)} %
                  </Mono>
                </div>
              ))}
          </div>
        ))}
        {escribe && (
          <form
            className="flex flex-col gap-3 border-t border-border pt-4 mt-5"
            onSubmit={(e) => {
              e.preventDefault();
              ejecutar(() => crearTramo(tramo), 'Tramo agregado.');
            }}
          >
            <RejillaForm>
              <Campo etiqueta="Esquema">
                <Selector
                  opciones={esquemas.map((s) => ({ valor: s.id_esquema, etiqueta: s.nombre }))}
                  value={tramo.id_esquema ?? ''}
                  onChange={(e) => setTramo({ ...tramo, id_esquema: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Tasa %">
                <Entrada
                  type="number"
                  step="0.01"
                  value={tramo.tasa_pct ?? ''}
                  onChange={(e) => setTramo({ ...tramo, tasa_pct: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Desde %">
                <Entrada
                  type="number"
                  step="0.01"
                  value={tramo.pct_min ?? ''}
                  onChange={(e) => setTramo({ ...tramo, pct_min: e.target.value })}
                />
              </Campo>
              <Campo etiqueta="Hasta %" ayuda="Vacío: sin tope">
                <Entrada
                  type="number"
                  step="0.01"
                  value={tramo.pct_max ?? ''}
                  onChange={(e) => setTramo({ ...tramo, pct_max: e.target.value })}
                />
              </Campo>
            </RejillaForm>
            <Acciones>
              <Boton variante="primario" type="submit">
                Agregar tramo
              </Boton>
            </Acciones>
          </form>
        )}
      </Panel>
      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
    </div>
  );
}
