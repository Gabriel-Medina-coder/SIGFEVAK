import { useEffect, useState } from 'react';
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
import { miles, pesos, porcentaje, fechaCorta, hoyIso, periodoActual } from '@/lib/formato';
import { exportarCsv } from '@/lib/exportar';
import {
  ROLES_AUTORIZA,
  mensajeFiscal,
  obtenerResumenFiscal,
  listarObligaciones,
  listarCalendario,
  listarAlertasActivas,
  atenderAlerta,
  obtenerObligacion,
  calcularObligacion,
  presentarDeclaracion,
  registrarLineaCaptura,
  autorizarObligacion,
  rechazarObligacion,
  registrarPago,
  conciliarObligacion,
  cerrarObligacion,
  ejecutarFuncionesDiarias,
  generarObligacionesPeriodo,
  listarPagosPorInstitucion,
} from '@/services/area5/obligaciones';
import {
  listarImportaciones,
  listarEntradasImportacion,
  listarImpuestosPorProducto,
  listarFraccionesConTasa,
  listarProductosCatalogo,
  registrarImportacion,
  listarLicencias,
  registrarLicencia,
} from '@/services/area5/importaciones';

const PESTANAS = [
  { id: 'obligaciones', etiqueta: 'Obligaciones' },
  { id: 'calendario', etiqueta: 'Calendario y alertas' },
  { id: 'importaciones', etiqueta: 'Importaciones' },
  { id: 'licencias', etiqueta: 'Licencias y permisos' },
  { id: 'pagos', etiqueta: 'Pagos por institución' },
];

// Semántica de la referencia: pendiente de pago en rojo, al corriente en verde, en curso en ámbar
const COLOR_OBLIGACION = {
  PENDIENTE: 'down',
  CALCULADO: 'accent',
  PRESENTADO: 'accent',
  LINEA_GENERADA: 'accent',
  AUTORIZADO: 'accent',
  PAGADO: 'up',
  CONCILIADO: 'up',
  CERRADO: 'muted',
  VENCIDO: 'down',
};
const COLOR_ALERTA = { PREVENTIVA: 'accent', ALTA: 'accent', CRITICA: 'down', VENCIDA: 'down' };
const COLOR_LICENCIA = {
  VIGENTE: 'up',
  POR_VENCER: 'accent',
  VENCIDA: 'down',
  EN_TRAMITE: 'muted',
};
const ETIQUETA_LICENCIA = {
  USO_SUELO: 'Uso de suelo',
  LICENCIA_FUNCIONAMIENTO: 'Licencia de funcionamiento',
  PROTECCION_CIVIL: 'Protección Civil',
  SIEM: 'SIEM',
  SANITARIO: 'Permiso sanitario',
  OTRA: 'Otra',
};

function error(err) {
  return mensajeFiscal(err) ?? mensajeDeError(err);
}

export default function Regulacion() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'regulacion');
  const esAdmin = usuario?.rol === 'ADMINISTRADOR';
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('obligaciones');
  const [admin, setAdmin] = useState(false);
  const resumen = useDatos(obtenerResumenFiscal);
  const obligaciones = useDatos(listarObligaciones);

  useEffect(() => {
    set({
      acciones: (
        <>
          <Boton
            onClick={() =>
              exportarCsv(
                'obligaciones',
                (obligaciones.datos ?? []).map((o) => ({
                  obligacion: o.tipos_obligacion?.nombre,
                  institucion: o.tipos_obligacion?.instituciones?.siglas,
                  periodo: o.periodo,
                  vence: o.fecha_vencimiento,
                  monto: o.monto_final ?? o.monto_estimado,
                  estado: o.estado,
                }))
              )
            }
          >
            Exportar
          </Boton>
          {esAdmin && (
            <Boton variante="primario" onClick={() => setAdmin(true)}>
              Actualizar alertas y vencidas
            </Boton>
          )}
        </>
      ),
    });
    return () => set({});
  }, [set, esAdmin, obligaciones.datos]);

  if ((resumen.cargando && !resumen.datos) || (obligaciones.cargando && !obligaciones.datos))
    return <Cargando />;
  if (resumen.error || obligaciones.error)
    return <Mensaje>{error(resumen.error ?? obligaciones.error)}</Mensaje>;

  const r = resumen.datos ?? {};
  const recargar = () => {
    resumen.recargar();
    obligaciones.recargar();
  };

  return (
    <>
      <FilaKpi>
        <KpiCard
          label="Obligaciones pendientes"
          value={pesos(r.monto_pendiente)}
          delta={`${r.obligaciones_pendientes ?? 0} conceptos`}
          up={false}
        />
        <KpiCard
          label="Próximo vencimiento"
          value={r.proximo_vencimiento ? fechaCorta(r.proximo_vencimiento).slice(0, 6) : '—'}
          delta={`${r.vencidas ?? 0} vencidas`}
          up={!r.vencidas}
        />
        <KpiCard
          label="Alertas activas"
          value={miles(r.alertas_activas)}
          delta="por atender"
          up={!r.alertas_activas}
        />
        <KpiCard label="Pagado este año" value={pesos(r.pagado_en_el_anio)} delta="a la fecha" up />
      </FilaKpi>

      <Pestanas opciones={PESTANAS} activa={pestana} onCambiar={setPestana} />

      {pestana === 'obligaciones' && (
        <Obligaciones
          lista={obligaciones.datos}
          usuario={usuario}
          escribe={escribe}
          onCambio={recargar}
        />
      )}
      {pestana === 'calendario' && <CalendarioAlertas escribe={escribe} onCambio={recargar} />}
      {pestana === 'importaciones' && (
        <Importaciones escribe={escribe} usuario={usuario} onCambio={recargar} />
      )}
      {pestana === 'licencias' && <Licencias escribe={escribe} />}
      {pestana === 'pagos' && <PagosInstitucion />}

      <Modal abierto={admin} titulo="Administración fiscal" onCerrar={() => setAdmin(false)}>
        {admin && <Administracion onCambio={recargar} />}
      </Modal>
    </>
  );
}

function Administracion({ onCambio }) {
  const [resultado, setResultado] = useState(null);
  const [periodo, setPeriodo] = useState(periodoActual());
  const [enviando, setEnviando] = useState(false);

  async function correr(fn) {
    setEnviando(true);
    try {
      setResultado({ tipo: 'ok', texto: await fn() });
      onCambio();
    } catch (err) {
      setResultado({ tipo: 'error', texto: error(err) });
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-[12.5px] text-text-dim m-0">
        Sin programación automática en este proyecto: estas funciones se ejecutan aquí una vez al
        día (pregunta abierta 5).
      </p>
      <Boton
        variante="primario"
        disabled={enviando}
        onClick={() =>
          correr(async () => {
            const r = await ejecutarFuncionesDiarias();
            return `Vencidas marcadas: ${r.vencidas}. Alertas creadas: ${r.alertas}. Licencias actualizadas: ${r.licencias}.`;
          })
        }
      >
        Marcar vencidas, generar alertas y actualizar licencias
      </Boton>
      <div className="border-t border-border pt-4 flex flex-col gap-3">
        <Campo
          etiqueta="Generar obligaciones del mes"
          ayuda="Mensuales, bimestrales (mes par) y anuales (diciembre)"
        >
          <Entrada type="month" value={periodo} onChange={(e) => setPeriodo(e.target.value)} />
        </Campo>
        <Boton
          disabled={enviando}
          onClick={() =>
            correr(
              async () => `Obligaciones creadas: ${await generarObligacionesPeriodo(periodo)}.`
            )
          }
        >
          Generar obligaciones
        </Boton>
      </div>
      {resultado && <Mensaje tipo={resultado.tipo}>{resultado.texto}</Mensaje>}
    </div>
  );
}

function Obligaciones({ lista, usuario, escribe, onCambio }) {
  const [filtro, setFiltro] = useState({ institucion: '', estado: '' });
  const [sel, setSel] = useState(null);
  const instituciones = [
    ...new Set(lista.map((o) => o.tipos_obligacion?.instituciones?.siglas).filter(Boolean)),
  ];
  const filtradas = lista.filter(
    (o) =>
      (!filtro.institucion || o.tipos_obligacion?.instituciones?.siglas === filtro.institucion) &&
      (!filtro.estado || o.estado === filtro.estado)
  );

  return (
    <>
      <Panel title="Licencias, permisos e impuestos">
        <div className="-mt-1 mb-6">
          <RejillaForm columnas={3}>
            <Campo etiqueta="Institución">
              <Selector
                placeholder="Todas"
                opciones={instituciones.map((i) => ({ valor: i, etiqueta: i }))}
                value={filtro.institucion}
                onChange={(e) => setFiltro({ ...filtro, institucion: e.target.value })}
              />
            </Campo>
            <Campo etiqueta="Estado">
              <Selector
                placeholder="Todos"
                opciones={Object.keys(COLOR_OBLIGACION).map((e) => ({
                  valor: e,
                  etiqueta: e.toLowerCase().replaceAll('_', ' '),
                }))}
                value={filtro.estado}
                onChange={(e) => setFiltro({ ...filtro, estado: e.target.value })}
              />
            </Campo>
          </RejillaForm>
        </div>
        <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
          <Table
            headers={[
              'Concepto',
              'Institución',
              'Periodo',
              'Monto',
              'Vencimiento',
              'Estatus',
              'Pago dirigido',
            ]}
            onRowClick={(i) => setSel(filtradas[i].id_obligacion)}
            vacio="Sin obligaciones con ese filtro"
            rows={filtradas.map((o) => {
              const monto = o.monto_final ?? o.monto_estimado;
              const abierta = !['PAGADO', 'CONCILIADO', 'CERRADO'].includes(o.estado);
              return [
                <Texto bold>{o.tipos_obligacion?.nombre}</Texto>,
                <Tag color="muted">{o.tipos_obligacion?.instituciones?.siglas}</Tag>,
                <Mono color="dim">{o.periodo ?? 'por operación'}</Mono>,
                <Mono bold color={abierta ? 'down' : 'text'}>
                  {monto !== null && monto !== undefined
                    ? pesos(monto, { centavos: true })
                    : 'por calcular'}
                </Mono>,
                <Mono color={o.estado === 'VENCIDO' ? 'down' : 'dim'}>
                  {fechaCorta(o.fecha_vencimiento)}
                </Mono>,
                <StatusBadge status={o.estado} map={COLOR_OBLIGACION} />,
                <Mono color={abierta ? 'accent' : 'muted'}>
                  {abierta ? (o.estado === 'AUTORIZADO' ? 'Pagar' : 'Programar') : 'Pagado'}
                </Mono>,
              ];
            })}
          />
        </div>
      </Panel>
      <Modal
        abierto={!!sel}
        titulo="Detalle de obligación"
        onCerrar={() => setSel(null)}
        ancho="max-w-3xl"
      >
        {sel && (
          <DetalleObligacion id={sel} usuario={usuario} escribe={escribe} onCambio={onCambio} />
        )}
      </Modal>
    </>
  );
}

function DetalleObligacion({ id, usuario, escribe, onCambio }) {
  const ob = useDatos(() => obtenerObligacion(id), [id]);
  const [f, setF] = useState({});
  const [aviso, setAviso] = useState(null);
  const [rechazo, setRechazo] = useState(null);
  const [enviando, setEnviando] = useState(false);

  if (ob.cargando && !ob.datos) return <Cargando />;
  if (ob.error) return <Mensaje>{error(ob.error)}</Mensaje>;
  const o = ob.datos;
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });
  const declaracion = [...(o.declaraciones ?? [])].sort(
    (a, b) => b.id_declaracion - a.id_declaracion
  )[0];
  const pagado = (o.pagos_obligacion ?? [])
    .filter((p) => p.estado_pago === 'PAGADO')
    .reduce((a, p) => a + Number(p.monto), 0);
  const esResponsable = o.id_responsable === usuario?.id_usuario;
  const puedeAutorizar = ROLES_AUTORIZA.includes(usuario?.rol) && !esResponsable;
  const monto = o.monto_final ?? o.monto_estimado;

  async function ejecutar(fn, texto) {
    setEnviando(true);
    setAviso(null);
    try {
      await fn();
      setAviso({ tipo: 'ok', texto });
      setF({});
      setRechazo(null);
      await ob.recargar();
      onCambio();
    } catch (err) {
      setAviso({ tipo: 'error', texto: error(err) });
    } finally {
      setEnviando(false);
    }
  }

  function requiere(campos, texto, fn, ok) {
    if (campos.some((c) => !String(f[c] ?? '').trim())) return setAviso({ tipo: 'error', texto });
    ejecutar(fn, ok);
  }

  return (
    <div className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Dato etiqueta="Obligación" valor={o.tipos_obligacion?.nombre} />
        <Dato etiqueta="Institución" valor={o.tipos_obligacion?.instituciones?.nombre} />
        <Dato etiqueta="Estado" valor={<StatusBadge status={o.estado} map={COLOR_OBLIGACION} />} />
        <Dato etiqueta="Periodo" valor={<Mono>{o.periodo ?? 'por operación'}</Mono>} />
        <Dato
          etiqueta="Vence"
          valor={
            <Mono color={o.estado === 'VENCIDO' ? 'down' : 'text'}>
              {fechaCorta(o.fecha_vencimiento)}
            </Mono>
          }
        />
        <Dato
          etiqueta="Monto"
          valor={
            <Mono bold>{monto !== null ? pesos(monto, { centavos: true }) : 'por calcular'}</Mono>
          }
        />
      </RejillaForm>
      {o.tipos_obligacion?.critica && (
        <Tag color="accent">crítica: autoriza AUTORIZADOR o ADMINISTRADOR</Tag>
      )}
      {o.comentario && <Mensaje tipo="info">Comentario: {o.comentario}</Mensaje>}

      {declaracion && (
        <Panel title="Orden de pago dirigido">
          <RejillaForm columnas={3}>
            <Dato
              etiqueta="Monto a pagar"
              valor={
                <Mono bold>
                  {pesos(monto ?? declaracion.importe_declarado, { centavos: true })}
                </Mono>
              }
            />
            <Dato etiqueta="Institución" valor={o.tipos_obligacion?.instituciones?.siglas} />
            <Dato
              etiqueta="Línea de captura"
              valor={<Mono>{declaracion.linea_captura ?? 'pendiente'}</Mono>}
            />
            <Dato
              etiqueta="Fecha límite"
              valor={
                <Mono>
                  {declaracion.fecha_limite_pago ? fechaCorta(declaracion.fecha_limite_pago) : '—'}
                </Mono>
              }
            />
            <Dato
              etiqueta="Folio / operación"
              valor={
                <Mono color="dim">
                  {declaracion.folio ?? '—'} · {declaracion.numero_operacion ?? '—'}
                </Mono>
              }
            />
            <Dato
              etiqueta="Pagado"
              valor={<Mono color="up">{pesos(pagado, { centavos: true })}</Mono>}
            />
          </RejillaForm>
        </Panel>
      )}

      {(o.documentos_fiscales ?? []).length > 0 && (
        <div className="text-[12px] text-text-dim">
          Documentos:{' '}
          {o.documentos_fiscales
            .map((d) => `${d.tipo_documento.toLowerCase().replaceAll('_', ' ')} (${d.nombre})`)
            .join(' · ')}
        </div>
      )}

      {escribe && (
        <div className="flex flex-col gap-3 border-t border-border pt-4">
          {o.estado === 'PENDIENTE' && (
            <form
              className="flex flex-col gap-3"
              onSubmit={(e) => {
                e.preventDefault();
                requiere(
                  ['monto'],
                  'Captura el monto determinado.',
                  () => calcularObligacion(o, f.monto, usuario.id_usuario),
                  'Obligación calculada.'
                );
              }}
            >
              <RejillaForm>
                <Campo etiqueta="Monto determinado">
                  <Entrada type="number" min="0" step="0.01" {...campo('monto')} />
                </Campo>
              </RejillaForm>
              <Acciones>
                <Boton variante="primario" type="submit" disabled={enviando}>
                  Registrar cálculo
                </Boton>
              </Acciones>
            </form>
          )}
          {o.estado === 'CALCULADO' && (
            <form
              className="flex flex-col gap-3"
              onSubmit={(e) => {
                e.preventDefault();
                requiere(
                  ['tipo_declaracion', 'fecha_presentacion', 'importe_declarado'],
                  'Tipo, fecha e importe son obligatorios.',
                  () => presentarDeclaracion(o.id_obligacion, f),
                  'Declaración presentada.'
                );
              }}
            >
              <RejillaForm columnas={3}>
                <Campo etiqueta="Tipo">
                  <Selector
                    opciones={['Provisional', 'Definitiva', 'Anual', 'Complementaria'].map((t) => ({
                      valor: t,
                      etiqueta: t,
                    }))}
                    {...campo('tipo_declaracion')}
                  />
                </Campo>
                <Campo etiqueta="Número de operación">
                  <Entrada {...campo('numero_operacion')} />
                </Campo>
                <Campo etiqueta="Folio del acuse">
                  <Entrada {...campo('folio')} />
                </Campo>
                <Campo etiqueta="Fecha de presentación">
                  <Entrada type="date" {...campo('fecha_presentacion')} />
                </Campo>
                <Campo etiqueta="Importe declarado">
                  <Entrada
                    type="number"
                    min="0"
                    step="0.01"
                    placeholder={monto ?? ''}
                    {...campo('importe_declarado')}
                  />
                </Campo>
              </RejillaForm>
              <Acciones>
                <Boton variante="primario" type="submit" disabled={enviando}>
                  Presentar declaración
                </Boton>
              </Acciones>
            </form>
          )}
          {o.estado === 'PRESENTADO' && declaracion && (
            <form
              className="flex flex-col gap-3"
              onSubmit={(e) => {
                e.preventDefault();
                requiere(
                  ['linea_captura'],
                  'Captura la línea de captura.',
                  () => registrarLineaCaptura(o.id_obligacion, declaracion.id_declaracion, f),
                  'Línea de captura registrada.'
                );
              }}
            >
              <RejillaForm>
                <Campo etiqueta="Línea de captura">
                  <Entrada {...campo('linea_captura')} />
                </Campo>
                <Campo etiqueta="Vigencia">
                  <Entrada type="date" {...campo('fecha_limite_pago')} />
                </Campo>
              </RejillaForm>
              <Acciones>
                <Boton variante="primario" type="submit" disabled={enviando}>
                  Registrar línea
                </Boton>
              </Acciones>
            </form>
          )}
          {['LINEA_GENERADA', 'AUTORIZADO'].includes(o.estado) &&
            ROLES_AUTORIZA.includes(usuario?.rol) && (
              <div className="flex flex-wrap gap-2">
                {o.estado === 'LINEA_GENERADA' && puedeAutorizar && (
                  <Boton
                    variante="primario"
                    disabled={enviando}
                    onClick={() =>
                      ejecutar(
                        () => autorizarObligacion(o.id_obligacion, usuario.id_usuario),
                        'Pago autorizado; el monto quedó congelado.'
                      )
                    }
                  >
                    Autorizar pago
                  </Boton>
                )}
                <Boton variante="peligro" disabled={enviando} onClick={() => setRechazo('')}>
                  Rechazar
                </Boton>
              </div>
            )}
          {o.estado === 'LINEA_GENERADA' && esResponsable && (
            <Mensaje tipo="info">
              Registraste esta obligación; otro usuario debe autorizarla (RN-A5-18).
            </Mensaje>
          )}
          {rechazo !== null && (
            <form
              className="flex flex-col gap-3"
              onSubmit={(e) => {
                e.preventDefault();
                if (!rechazo.trim())
                  return setAviso({ tipo: 'error', texto: 'El rechazo exige un comentario.' });
                ejecutar(
                  () => rechazarObligacion(o.id_obligacion, rechazo.trim()),
                  'Obligación regresada a CALCULADO.'
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
                <Boton variante="peligro" type="submit">
                  Rechazar
                </Boton>
              </Acciones>
            </form>
          )}
          {['AUTORIZADO', 'VENCIDO'].includes(o.estado) && (
            <form
              className="flex flex-col gap-3"
              onSubmit={(e) => {
                e.preventDefault();
                const datosPago = {
                  fecha_pago: hoyIso(),
                  metodo_pago: 'SPEI',
                  monto: monto ?? '',
                  linea_captura: declaracion?.linea_captura ?? '',
                  ...f,
                };
                if (
                  !datosPago.monto ||
                  !datosPago.referencia?.trim() ||
                  !datosPago.comprobante_nombre?.trim() ||
                  !datosPago.comprobante_referencia?.trim()
                ) {
                  return setAviso({
                    tipo: 'error',
                    texto: 'Monto, referencia y comprobante son obligatorios (RN-A5-07).',
                  });
                }
                ejecutar(
                  () => registrarPago(o, datosPago, usuario.id_usuario),
                  'Pago registrado con su comprobante.'
                );
              }}
            >
              <RejillaForm columnas={3}>
                <Campo etiqueta="Fecha de pago">
                  <Entrada
                    type="date"
                    value={f.fecha_pago ?? hoyIso()}
                    onChange={(e) => setF({ ...f, fecha_pago: e.target.value })}
                  />
                </Campo>
                <Campo etiqueta="Monto">
                  <Entrada
                    type="number"
                    min="0.01"
                    step="0.01"
                    value={f.monto ?? monto ?? ''}
                    onChange={(e) => setF({ ...f, monto: e.target.value })}
                  />
                </Campo>
                <Campo etiqueta="Método">
                  <Selector
                    placeholder="SPEI"
                    opciones={['TRANSFERENCIA', 'VENTANILLA', 'TARJETA', 'PORTAL'].map((m) => ({
                      valor: m,
                      etiqueta: m.toLowerCase(),
                    }))}
                    value={f.metodo_pago && f.metodo_pago !== 'SPEI' ? f.metodo_pago : ''}
                    onChange={(e) => setF({ ...f, metodo_pago: e.target.value || 'SPEI' })}
                  />
                </Campo>
                <Campo etiqueta="Banco">
                  <Entrada {...campo('banco')} />
                </Campo>
                <Campo etiqueta="Referencia bancaria">
                  <Entrada {...campo('referencia')} />
                </Campo>
                <Campo etiqueta="Comprobante" ayuda="Nombre del archivo">
                  <Entrada {...campo('comprobante_nombre')} />
                </Campo>
              </RejillaForm>
              <Campo
                etiqueta="Ubicación del comprobante"
                ayuda="URL o ruta; no se guarda el archivo"
              >
                <Entrada {...campo('comprobante_referencia')} />
              </Campo>
              <Acciones>
                <Boton variante="primario" type="submit" disabled={enviando}>
                  Registrar pago
                </Boton>
              </Acciones>
            </form>
          )}
          {o.estado === 'PAGADO' && ROLES_AUTORIZA.includes(usuario?.rol) && (
            <div className="flex items-center justify-between gap-3">
              <span className="text-[12px] text-text-dim">
                Pagado <Mono>{pesos(pagado, { centavos: true })}</Mono> contra monto final{' '}
                <Mono>{pesos(monto, { centavos: true })}</Mono>
              </span>
              <Boton
                variante="primario"
                disabled={enviando}
                onClick={() =>
                  ejecutar(() => conciliarObligacion(o.id_obligacion), 'Obligación conciliada.')
                }
              >
                Conciliar
              </Boton>
            </div>
          )}
          {o.estado === 'CONCILIADO' && ROLES_AUTORIZA.includes(usuario?.rol) && (
            <Acciones>
              <Boton
                variante="primario"
                disabled={enviando}
                onClick={() =>
                  ejecutar(() => cerrarObligacion(o.id_obligacion), 'Obligación cerrada.')
                }
              >
                Cerrar obligación
              </Boton>
            </Acciones>
          )}
          {o.estado === 'CERRADO' && (
            <Mensaje tipo="info">
              Cerrada el {fechaCorta(o.fecha_cierre)}. Inmutable (RN-A5-24).
            </Mensaje>
          )}
        </div>
      )}
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

function CalendarioAlertas({ escribe, onCambio }) {
  const cal = useDatos(listarCalendario);
  const alertas = useDatos(listarAlertasActivas);
  const [aviso, setAviso] = useState(null);

  async function atender(id) {
    try {
      await atenderAlerta(id);
      alertas.recargar();
      onCambio();
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <div className="grid grid-cols-[1fr_360px] max-[960px]:grid-cols-1 gap-3.5">
      <Panel title="Próximos 30 días">
        {cal.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['Vence', 'Días', 'Obligación', 'Institución', 'Periodo', 'Monto', 'Estatus']}
            vacio="Nada vence en los próximos 30 días"
            rows={(cal.datos ?? []).map((c) => [
              <Mono>{fechaCorta(c.fecha_vencimiento)}</Mono>,
              <Mono
                bold
                color={c.dias_restantes <= 3 ? 'down' : c.dias_restantes <= 7 ? 'accent' : 'dim'}
              >
                {c.dias_restantes}
              </Mono>,
              <Texto bold>{c.obligacion}</Texto>,
              <Tag color="muted">{c.institucion}</Tag>,
              <Mono color="dim">{c.periodo ?? '—'}</Mono>,
              <Mono>
                {(c.monto_final ?? c.monto_estimado)
                  ? pesos(c.monto_final ?? c.monto_estimado, { centavos: true })
                  : '—'}
              </Mono>,
              <StatusBadge status={c.estado} map={COLOR_OBLIGACION} />,
            ])}
          />
        )}
      </Panel>
      <Panel title="Alertas">
        {alertas.cargando ? (
          <Cargando />
        ) : (alertas.datos ?? []).length === 0 ? (
          <div className="text-[12px] text-text-dim">Sin alertas pendientes.</div>
        ) : (
          alertas.datos.map((a) => (
            <div
              key={a.id_alerta}
              className="py-2.5 border-b border-border last:border-b-0 flex flex-col gap-1.5"
            >
              <div className="flex items-center justify-between gap-2">
                <StatusBadge status={a.nivel} map={COLOR_ALERTA} />
                <Mono color="dim">{fechaCorta(a.fecha_alerta)}</Mono>
              </div>
              <div className="text-[12px]">{a.mensaje}</div>
              {escribe && (
                <div>
                  <Boton onClick={() => atender(a.id_alerta)}>Atender</Boton>
                </div>
              )}
            </div>
          ))
        )}
        {aviso && <Mensaje>{aviso}</Mensaje>}
      </Panel>
    </div>
  );
}

const PRODUCTO_VACIO = {
  nombre: '',
  cantidad: '',
  valor_unitario: '',
  fraccion_arancelaria: '',
  nico: '',
};

function Importaciones({ escribe, usuario, onCambio }) {
  const imps = useDatos(listarImportaciones);
  const impuestos = useDatos(listarImpuestosPorProducto);
  const [nueva, setNueva] = useState(false);
  if (imps.cargando && !imps.datos) return <Cargando />;
  if (imps.error) return <Mensaje>{error(imps.error)}</Mensaje>;

  return (
    <>
      <Panel
        title="Pedimentos de importación"
        acciones={
          escribe && (
            <Boton variante="primario" onClick={() => setNueva(true)}>
              + Nuevo pedimento
            </Boton>
          )
        }
      >
        <Table
          headers={[
            'Pedimento',
            'Fecha',
            'Aduana',
            'Origen',
            'Valor aduanero',
            'IGI',
            'DTA',
            'IVA importación',
            'Total',
            'Obligación',
          ]}
          rows={imps.datos.map((i) => [
            <Mono bold>{i.numero_pedimento}</Mono>,
            <Mono color="dim">{fechaCorta(i.fecha_importacion)}</Mono>,
            <Texto dim>{i.aduana}</Texto>,
            <Tag color="down">{i.pais_origen}</Tag>,
            <Mono>{pesos(i.valor_aduanero, { centavos: true })}</Mono>,
            <Mono>{pesos(i.igi, { centavos: true })}</Mono>,
            <Mono>{pesos(i.dta, { centavos: true })}</Mono>,
            <Mono>{pesos(i.iva_importacion, { centavos: true })}</Mono>,
            <Mono bold color="down">
              {pesos(i.total_contribuciones, { centavos: true })}
            </Mono>,
            <StatusBadge status={i.obligaciones?.estado} map={COLOR_OBLIGACION} />,
          ])}
        />
      </Panel>
      <Panel title="Impuestos por producto y por unidad (contrato con Entradas)">
        {impuestos.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={[
              'Pedimento',
              'Producto',
              'Fracción',
              'NICO',
              'Cantidad',
              'Tasa IGI',
              'IGI',
              'DTA',
              'IVA importación',
              'Impuestos por unidad',
            ]}
            rows={(impuestos.datos ?? []).map((p) => [
              <Mono color="dim">{p.numero_pedimento}</Mono>,
              <Texto bold>{p.nombre}</Texto>,
              <Mono>{p.fraccion_arancelaria ?? 'sin determinar'}</Mono>,
              <Mono color="dim">{p.nico ?? '—'}</Mono>,
              <Mono>{miles(p.cantidad)}</Mono>,
              <Mono>{porcentaje(Number(p.tasa_igi) * 100, 2)}</Mono>,
              <Mono>{pesos(p.igi_producto, { centavos: true })}</Mono>,
              <Mono>{pesos(p.dta_producto, { centavos: true })}</Mono>,
              <Mono>{pesos(p.iva_importacion_producto, { centavos: true })}</Mono>,
              <Mono bold color="accent">
                {pesos(p.impuestos_por_unidad_sin_iva, { centavos: true })}
              </Mono>,
            ])}
          />
        )}
      </Panel>
      <Modal
        abierto={nueva}
        titulo="Nuevo pedimento"
        onCerrar={() => setNueva(false)}
        ancho="max-w-3xl"
      >
        {nueva && (
          <FormImportacion
            usuario={usuario}
            onListo={() => {
              setNueva(false);
              imps.recargar();
              impuestos.recargar();
              onCambio();
            }}
            onCancelar={() => setNueva(false)}
          />
        )}
      </Modal>
    </>
  );
}

function FormImportacion({ usuario, onListo, onCancelar }) {
  const catalogos = useDatos(() =>
    Promise.all([listarEntradasImportacion(), listarFraccionesConTasa(), listarProductosCatalogo()])
  );
  const [f, setF] = useState({
    fecha_importacion: hoyIso(),
    pais_origen: '',
    pais_procedencia: '',
  });
  const [productos, setProductos] = useState([{ ...PRODUCTO_VACIO }]);
  const [aviso, setAviso] = useState('');
  const [enviando, setEnviando] = useState(false);
  if (catalogos.cargando) return <Cargando />;
  if (catalogos.error) return <Mensaje>{error(catalogos.error)}</Mensaje>;
  const [entradas, fracciones, catalogo] = catalogos.datos;
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });
  const cambiarProducto = (i, n, v) =>
    setProductos(productos.map((p, j) => (j === i ? { ...p, [n]: v } : p)));

  async function guardar(e) {
    e.preventDefault();
    const faltan = [
      'numero_pedimento',
      'aduana',
      'pais_origen',
      'pais_procedencia',
      'fecha_importacion',
      'valor_aduanero',
    ].some((c) => !String(f[c] ?? '').trim());
    if (faltan)
      return setAviso('Pedimento, aduana, países, fecha y valor aduanero son obligatorios.');
    if (
      productos.some(
        (p) => !p.nombre.trim() || !(Number(p.cantidad) > 0) || p.valor_unitario === ''
      )
    )
      return setAviso('Cada producto necesita nombre, cantidad y valor unitario.');
    setEnviando(true);
    setAviso('');
    try {
      await registrarImportacion(f, productos, usuario.id_usuario);
      onListo();
    } catch (err) {
      setAviso(error(err));
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Campo etiqueta="Número de pedimento">
          <Entrada {...campo('numero_pedimento')} />
        </Campo>
        <Campo etiqueta="Aduana">
          <Entrada {...campo('aduana')} />
        </Campo>
        <Campo etiqueta="Agente aduanal">
          <Entrada {...campo('agente_aduanal')} />
        </Campo>
        <Campo etiqueta="País de origen">
          <Entrada {...campo('pais_origen')} />
        </Campo>
        <Campo etiqueta="País de procedencia">
          <Entrada {...campo('pais_procedencia')} />
        </Campo>
        <Campo etiqueta="Fecha">
          <Entrada type="date" {...campo('fecha_importacion')} />
        </Campo>
        <Campo etiqueta="Valor aduanero MXN">
          <Entrada type="number" min="0" step="0.01" {...campo('valor_aduanero')} />
        </Campo>
        <Campo etiqueta="Manifestación E2">
          <Entrada {...campo('numero_e2')} />
        </Campo>
        <Campo etiqueta="Entrada del almacén" ayuda="Integración con Entradas">
          <Selector
            placeholder="Sin ligar"
            opciones={entradas.map((en) => ({
              valor: en.id_entrada,
              etiqueta: `${fechaCorta(en.fecha)} · ${en.nombre}`,
            }))}
            {...campo('id_entrada')}
          />
        </Campo>
      </RejillaForm>

      <div className="text-[10.5px] uppercase tracking-[0.04em] text-text-dim">
        Productos importados
      </div>
      {productos.map((p, i) => (
        <RejillaForm key={i} columnas={3}>
          <Campo etiqueta="Producto del catálogo">
            <Selector
              placeholder="Nuevo o sin ligar"
              opciones={catalogo.map((c) => ({ valor: c.id_producto, etiqueta: c.nombre }))}
              value={p.id_producto ?? ''}
              onChange={(e) => {
                const c = catalogo.find((x) => String(x.id_producto) === e.target.value);
                setProductos(
                  productos.map((q, j) =>
                    j === i
                      ? { ...q, id_producto: e.target.value, nombre: c?.nombre ?? q.nombre }
                      : q
                  )
                );
              }}
            />
          </Campo>
          <Campo etiqueta="Nombre">
            <Entrada
              value={p.nombre}
              onChange={(e) => cambiarProducto(i, 'nombre', e.target.value)}
            />
          </Campo>
          <Campo etiqueta="Fracción arancelaria" ayuda="Solo fracciones con tasa cargada">
            <Selector
              placeholder="Sin determinar"
              opciones={fracciones.map((fr) => ({
                valor: fr.fraccion,
                etiqueta: `${fr.fraccion} · ${(Number(fr.valor) * 100).toFixed(2)} %`,
              }))}
              value={p.fraccion_arancelaria}
              onChange={(e) => cambiarProducto(i, 'fraccion_arancelaria', e.target.value)}
            />
          </Campo>
          <Campo etiqueta="Cantidad">
            <Entrada
              type="number"
              min="1"
              value={p.cantidad}
              onChange={(e) => cambiarProducto(i, 'cantidad', e.target.value)}
            />
          </Campo>
          <Campo etiqueta="Valor unitario MXN">
            <Entrada
              type="number"
              min="0"
              step="0.01"
              value={p.valor_unitario}
              onChange={(e) => cambiarProducto(i, 'valor_unitario', e.target.value)}
            />
          </Campo>
          <Campo etiqueta="NICO">
            <Entrada value={p.nico} onChange={(e) => cambiarProducto(i, 'nico', e.target.value)} />
          </Campo>
        </RejillaForm>
      ))}
      <div className="flex gap-2">
        <Boton type="button" onClick={() => setProductos([...productos, { ...PRODUCTO_VACIO }])}>
          + Otro producto
        </Boton>
        {productos.length > 1 && (
          <Boton type="button" onClick={() => setProductos(productos.slice(0, -1))}>
            Quitar el último
          </Boton>
        )}
      </div>
      <Mensaje tipo="info">
        IGI, DTA e IVA de importación los calcula la base con las tasas vigentes al guardar; aquí no
        se estiman.
      </Mensaje>
      {aviso && <Mensaje>{aviso}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onCancelar}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Registrar pedimento'}
        </Boton>
      </Acciones>
    </form>
  );
}

function Licencias({ escribe }) {
  const lista = useDatos(listarLicencias);
  const [nueva, setNueva] = useState(false);
  if (lista.cargando && !lista.datos) return <Cargando />;
  if (lista.error) return <Mensaje>{error(lista.error)}</Mensaje>;
  return (
    <>
      <Panel
        title="Licencias y permisos de la empresa"
        acciones={
          escribe && (
            <Boton variante="primario" onClick={() => setNueva(true)}>
              + Nueva licencia
            </Boton>
          )
        }
      >
        <Table
          headers={[
            'Licencia',
            'Autoridad',
            'Municipio',
            'Número',
            'Emisión',
            'Vencimiento',
            'Costo',
            'Estado',
          ]}
          rows={lista.datos.map((l) => [
            <Texto bold>{ETIQUETA_LICENCIA[l.tipo_licencia] ?? l.tipo_licencia}</Texto>,
            <Texto dim>{l.autoridad_emisora}</Texto>,
            <Texto dim>{l.municipio ?? '—'}</Texto>,
            <Mono color="dim">{l.numero_licencia ?? '—'}</Mono>,
            <Mono color="dim">{l.fecha_emision ? fechaCorta(l.fecha_emision) : '—'}</Mono>,
            <Mono color={l.estado === 'VENCIDA' ? 'down' : 'text'}>
              {l.fecha_vencimiento ? fechaCorta(l.fecha_vencimiento) : '—'}
            </Mono>,
            <Mono>{l.costo ? pesos(l.costo, { centavos: true }) : '—'}</Mono>,
            <StatusBadge status={l.estado} map={COLOR_LICENCIA} />,
          ])}
        />
      </Panel>
      <Modal abierto={nueva} titulo="Nueva licencia o permiso" onCerrar={() => setNueva(false)}>
        {nueva && (
          <FormLicencia
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

function FormLicencia({ onListo }) {
  const [f, setF] = useState({ estado: 'VIGENTE' });
  const [aviso, setAviso] = useState('');
  const campo = (n) => ({
    value: f[n] ?? '',
    onChange: (e) => setF({ ...f, [n]: e.target.value }),
  });

  async function guardar(e) {
    e.preventDefault();
    if (!f.tipo_licencia || !f.autoridad_emisora?.trim())
      return setAviso('Tipo y autoridad son obligatorios.');
    if (['USO_SUELO', 'LICENCIA_FUNCIONAMIENTO'].includes(f.tipo_licencia) && !f.municipio?.trim())
      return setAviso('Uso de suelo y funcionamiento requieren municipio (RN-A5-15).');
    try {
      await registrarLicencia(f);
      onListo();
    } catch (err) {
      setAviso(error(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <RejillaForm>
        <Campo etiqueta="Tipo">
          <Selector
            opciones={Object.entries(ETIQUETA_LICENCIA).map(([valor, etiqueta]) => ({
              valor,
              etiqueta,
            }))}
            {...campo('tipo_licencia')}
          />
        </Campo>
        <Campo etiqueta="Autoridad emisora">
          <Entrada {...campo('autoridad_emisora')} />
        </Campo>
        <Campo etiqueta="Municipio">
          <Entrada placeholder="Tuxtla Gutiérrez" {...campo('municipio')} />
        </Campo>
        <Campo etiqueta="Número">
          <Entrada {...campo('numero_licencia')} />
        </Campo>
        <Campo etiqueta="Emisión">
          <Entrada type="date" {...campo('fecha_emision')} />
        </Campo>
        <Campo etiqueta="Vencimiento">
          <Entrada type="date" {...campo('fecha_vencimiento')} />
        </Campo>
        <Campo etiqueta="Costo">
          <Entrada type="number" min="0" step="0.01" {...campo('costo')} />
        </Campo>
        <Campo etiqueta="Estado">
          <Selector
            placeholder="Vigente"
            opciones={[{ valor: 'EN_TRAMITE', etiqueta: 'En trámite' }]}
            value={f.estado === 'VIGENTE' ? '' : f.estado}
            onChange={(e) => setF({ ...f, estado: e.target.value || 'VIGENTE' })}
          />
        </Campo>
      </RejillaForm>
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

function PagosInstitucion() {
  const pagos = useDatos(listarPagosPorInstitucion);
  if (pagos.cargando) return <Cargando />;
  if (pagos.error) return <Mensaje>{error(pagos.error)}</Mensaje>;
  return (
    <Panel title="Historial de pagos por institución y periodo">
      <Table
        headers={[
          'Periodo de pago',
          'Institución',
          'Ámbito',
          'Obligación',
          'Pagos',
          'Monto pagado',
        ]}
        vacio="Sin pagos registrados"
        rows={pagos.datos.map((p) => [
          <Mono>{p.periodo_pago}</Mono>,
          <Texto bold>{p.institucion}</Texto>,
          <Tag color="muted">{p.ambito.toLowerCase()}</Tag>,
          <Mono color="dim">{p.clave}</Mono>,
          <Mono>{miles(p.numero_pagos)}</Mono>,
          <Mono bold color="up">
            {pesos(p.monto_pagado, { centavos: true })}
          </Mono>,
        ])}
      />
    </Panel>
  );
}
