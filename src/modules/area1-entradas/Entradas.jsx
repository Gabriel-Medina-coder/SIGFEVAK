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
import { miles, pesos, fechaCorta, hoyIso, periodoActual } from '@/lib/formato';
import { exportarCsv } from '@/lib/exportar';
import {
  listarEntradas,
  registrarEntrada,
  capitalEstimado,
  listarDiscrepanciasRecepcion,
  listarReabastecimiento,
} from '@/services/area1/entradas';
import {
  listarProveedores,
  guardarProveedor,
  listarAlmacenes,
  guardarAlmacen,
  listarMateriasPrimas,
  crearMateriaPrima,
  registrarEntradaMateria,
  listarProductos,
} from '@/services/area1/catalogos';
import {
  listarOrdenes,
  listarProductosConBom,
  crearOrden,
  cambiarEstadoOrden,
  capturarConsumo,
  registrarCalidad,
  obtenerConsumos,
} from '@/services/area1/produccion';

const PESTANAS = [
  { id: 'entradas', etiqueta: 'Entradas' },
  { id: 'produccion', etiqueta: 'Órdenes de producción' },
  { id: 'materias', etiqueta: 'Materias primas' },
  { id: 'proveedores', etiqueta: 'Proveedores' },
  { id: 'almacenes', etiqueta: 'Almacenes' },
  { id: 'recepcion', etiqueta: 'Discrepancias y reabastecimiento' },
];

const COLOR_ORDEN = {
  PLANEADA: 'muted',
  EN_PROCESO: 'accent',
  EN_CALIDAD: 'accent',
  TERMINADA: 'up',
  CANCELADA: 'down',
};
const COLOR_MERCANCIA = { BUEN_ESTADO: 'up', DANADO: 'down', INCOMPLETO: 'accent' };

export default function Entradas() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'entradas');
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('entradas');
  const [modal, setModal] = useState(null);
  const entradas = useDatos(() => listarEntradas());

  useEffect(() => {
    set({
      acciones: (
        <>
          <Boton onClick={() => exportarCsv('entradas', entradas.datos ?? [])}>Exportar</Boton>
          {escribe && (
            <Boton variante="primario" onClick={() => setModal('entrada')}>
              + Nueva entrada
            </Boton>
          )}
        </>
      ),
    });
    return () => set({});
  }, [set, escribe, entradas.datos]);

  if (entradas.cargando && !entradas.datos) return <Cargando />;
  if (entradas.error) return <Mensaje>{mensajeDeError(entradas.error)}</Mensaje>;

  const delMes = entradas.datos.filter((e) => String(e.fecha).startsWith(periodoActual()));
  const capitalMes = delMes.reduce((a, e) => a + Number(e.capital_entrada_mxn), 0);
  const unidadesMes = delMes.reduce((a, e) => a + e.cantidad, 0);
  const importaciones = delMes.filter(
    (e) => e.moneda !== 'MXN' || (e.pais_origen && e.pais_origen !== 'México')
  ).length;

  return (
    <>
      <FilaKpi columnas={3}>
        <KpiCard
          label="Capital ingresado del mes"
          value={pesos(capitalMes)}
          delta={pesos(entradas.datos.reduce((a, e) => a + Number(e.capital_entrada_mxn), 0))}
          up
          sub="histórico"
        />
        <KpiCard
          label="Unidades ingresadas"
          value={`${miles(unidadesMes)} uds`}
          delta={`${delMes.length} registros`}
          up
          sub="este mes"
        />
        <KpiCard
          label="Registros del mes"
          value={`${delMes.length} entradas`}
          delta={`${importaciones} importación`}
          up
          sub={`${delMes.length - importaciones} nacional`}
        />
      </FilaKpi>

      <Pestanas opciones={PESTANAS} activa={pestana} onCambiar={setPestana} />

      {pestana === 'entradas' && (
        <Panel title="Entradas de productos · capital real con flete, impuestos y tipo de cambio">
          <Table
            headers={[
              'Fecha',
              'SKU',
              'Producto',
              'Proveedor',
              'Unidades',
              'Valor/ud MXN',
              'Capital',
              'IVA estimado',
              'Documento',
              'Mercancía',
            ]}
            rows={entradas.datos.map((e) => [
              <Mono color="dim">{fechaCorta(e.fecha)}</Mono>,
              <Mono>{e.sku ?? '—'}</Mono>,
              <Texto bold>{e.nombre}</Texto>,
              <Texto dim>{e.proveedor ?? '—'}</Texto>,
              <Mono>{miles(e.cantidad)}</Mono>,
              <Mono>{pesos(e.valor_unitario_mxn, { centavos: true })}</Mono>,
              <Mono color="up" bold>
                {pesos(e.capital_entrada_mxn, { centavos: true })}
              </Mono>,
              <Mono color="dim">{pesos(e.iva_estimado_mxn, { centavos: true })}</Mono>,
              <Mono color="dim">
                {e.numero_factura_proveedor ??
                  e.numero_orden_compra ??
                  (e.id_orden_produccion ? 'Producción' : '—')}
              </Mono>,
              <StatusBadge status={e.estado_mercancia} map={COLOR_MERCANCIA} />,
            ])}
          />
        </Panel>
      )}
      {pestana === 'produccion' && (
        <Produccion escribe={escribe} usuario={usuario} onCambio={entradas.recargar} />
      )}
      {pestana === 'materias' && <MateriasPrimas escribe={escribe} />}
      {pestana === 'proveedores' && <Proveedores escribe={escribe} />}
      {pestana === 'almacenes' && <Almacenes escribe={escribe} />}
      {pestana === 'recepcion' && <Recepcion />}

      <Modal
        abierto={modal === 'entrada'}
        titulo="Registrar entrada de producto"
        onCerrar={() => setModal(null)}
        ancho="max-w-3xl"
      >
        {modal === 'entrada' && (
          <FormEntrada
            usuario={usuario}
            onListo={() => {
              setModal(null);
              entradas.recargar();
            }}
            onCancelar={() => setModal(null)}
          />
        )}
      </Modal>
    </>
  );
}

function useFormulario(inicial) {
  const [f, setF] = useState(inicial);
  const campo = (nombre) => ({
    value: f[nombre] ?? '',
    onChange: (e) => setF((x) => ({ ...x, [nombre]: e.target.value })),
  });
  return [f, setF, campo];
}

function FormEntrada({ usuario, onListo, onCancelar }) {
  const catalogos = useDatos(() =>
    Promise.all([
      listarProductos(),
      listarProveedores({ soloActivos: true }),
      listarAlmacenes({ tipo: 'PRODUCTO_TERMINADO', soloActivos: true }),
    ])
  );
  const [f, , campo] = useFormulario({
    fecha: hoyIso(),
    moneda: 'MXN',
    tipo_cambio: '1',
    flete_unitario: '0',
    impuestos_unitarios: '0',
    estado_mercancia: 'BUEN_ESTADO',
    responsable_recepcion: usuario?.nombre ?? '',
  });
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);

  if (catalogos.cargando) return <Cargando />;
  if (catalogos.error) return <Mensaje>{mensajeDeError(catalogos.error)}</Mensaje>;
  const [productos, proveedores, almacenes] = catalogos.datos;
  const capital = capitalEstimado(f);

  async function guardar(e) {
    e.preventDefault();
    if (!f.id_producto || !f.id_almacen)
      return setError('Elige el producto y el almacén de destino.');
    if (!(Number(f.cantidad) > 0)) return setError('La cantidad debe ser mayor a cero.');
    if (f.costo_unitario === undefined || f.costo_unitario === '' || Number(f.costo_unitario) < 0)
      return setError('Indica el costo unitario.');
    if (f.moneda !== 'MXN' && (!(Number(f.tipo_cambio) > 0) || Number(f.tipo_cambio) === 1))
      return setError('Indica el tipo de cambio para la moneda extranjera (RN-A1-07).');
    if (!f.numero_factura_proveedor?.trim() && !f.numero_orden_compra?.trim())
      return setError('Captura la factura del proveedor o la orden de compra (RN-A1-18).');
    setEnviando(true);
    setError('');
    try {
      await registrarEntrada(f);
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    } finally {
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Campo etiqueta="Producto">
          <Selector
            opciones={productos.map((p) => ({
              valor: p.id_producto,
              etiqueta: `${p.sku ? p.sku + ' · ' : ''}${p.nombre}`,
            }))}
            {...campo('id_producto')}
          />
        </Campo>
        <Campo etiqueta="Proveedor">
          <Selector
            opciones={proveedores.map((p) => ({ valor: p.id_proveedor, etiqueta: p.nombre }))}
            {...campo('id_proveedor')}
          />
        </Campo>
        <Campo etiqueta="Almacén de destino">
          <Selector
            opciones={almacenes.map((a) => ({ valor: a.id_almacen, etiqueta: a.nombre }))}
            {...campo('id_almacen')}
          />
        </Campo>
        <Campo etiqueta="Fecha">
          <Entrada type="date" {...campo('fecha')} />
        </Campo>
        <Campo etiqueta="Cantidad recibida">
          <Entrada type="number" min="1" {...campo('cantidad')} />
        </Campo>
        <Campo etiqueta="Cantidad esperada" ayuda="Según la orden de compra">
          <Entrada type="number" min="1" {...campo('cantidad_esperada')} />
        </Campo>
        <Campo etiqueta="Costo unitario">
          <Entrada type="number" min="0" step="0.01" {...campo('costo_unitario')} />
        </Campo>
        <Campo etiqueta="Flete por unidad">
          <Entrada type="number" min="0" step="0.01" {...campo('flete_unitario')} />
        </Campo>
        <Campo etiqueta="Impuestos por unidad" ayuda="Aranceles de importación">
          <Entrada type="number" min="0" step="0.01" {...campo('impuestos_unitarios')} />
        </Campo>
        <Campo etiqueta="Moneda">
          <Selector
            placeholder="MXN"
            opciones={['USD', 'EUR', 'CNY'].map((m) => ({ valor: m, etiqueta: m }))}
            value={f.moneda === 'MXN' ? '' : f.moneda}
            onChange={(e) =>
              campo('moneda').onChange({ target: { value: e.target.value || 'MXN' } })
            }
          />
        </Campo>
        <Campo etiqueta="Tipo de cambio">
          <Entrada
            type="number"
            step="0.0001"
            disabled={f.moneda === 'MXN'}
            {...campo('tipo_cambio')}
          />
        </Campo>
        <Campo etiqueta="Estado de la mercancía">
          <Selector
            placeholder="Buen estado"
            opciones={[
              { valor: 'DANADO', etiqueta: 'Dañado' },
              { valor: 'INCOMPLETO', etiqueta: 'Incompleto' },
            ]}
            value={f.estado_mercancia === 'BUEN_ESTADO' ? '' : f.estado_mercancia}
            onChange={(e) =>
              campo('estado_mercancia').onChange({
                target: { value: e.target.value || 'BUEN_ESTADO' },
              })
            }
          />
        </Campo>
        <Campo etiqueta="Factura del proveedor">
          <Entrada {...campo('numero_factura_proveedor')} />
        </Campo>
        <Campo etiqueta="Fecha de factura">
          <Entrada type="date" {...campo('fecha_factura_proveedor')} />
        </Campo>
        <Campo etiqueta="Orden de compra">
          <Entrada {...campo('numero_orden_compra')} />
        </Campo>
        <Campo etiqueta="País de origen">
          <Entrada placeholder="México" {...campo('pais_origen')} />
        </Campo>
        <Campo etiqueta="Pedimento o guía">
          <Entrada {...campo('documento_importacion_ref')} />
        </Campo>
        <Campo etiqueta="Recibió">
          <Entrada {...campo('responsable_recepcion')} />
        </Campo>
      </RejillaForm>
      <Campo etiqueta="Observaciones">
        <AreaTexto {...campo('observaciones')} />
      </Campo>
      <Mensaje tipo="info">
        Capital estimado de la entrada:{' '}
        <Mono bold color="up">
          {pesos(capital, { centavos: true })}
        </Mono>{' '}
        · valor por unidad en pesos{' '}
        <Mono bold>
          {pesos(Number(f.cantidad) ? capital / Number(f.cantidad) : 0, { centavos: true })}
        </Mono>
        . El stock y el capital del producto los actualiza la base al guardar.
      </Mensaje>
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onCancelar}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Registrar entrada'}
        </Boton>
      </Acciones>
    </form>
  );
}

function Produccion({ escribe, usuario, onCambio }) {
  const ordenes = useDatos(listarOrdenes);
  const [modal, setModal] = useState(null);
  const cerrar = () => setModal(null);
  const recargar = () => {
    ordenes.recargar();
    onCambio();
  };

  if (ordenes.cargando && !ordenes.datos) return <Cargando />;
  if (ordenes.error) return <Mensaje>{mensajeDeError(ordenes.error)}</Mensaje>;
  const seleccionada = ordenes.datos.find((o) => o.id_orden === modal?.id);

  return (
    <>
      <Panel
        title="Órdenes de producción"
        acciones={
          escribe && (
            <Boton variante="primario" onClick={() => setModal({ tipo: 'nueva' })}>
              + Nueva orden
            </Boton>
          )
        }
      >
        <Table
          headers={[
            'Folio',
            'Producto',
            'Estado',
            'Planeada',
            'Terminada',
            'Materia real',
            'Merma',
            'Costo unitario',
            'Desviación',
            'Responsable',
          ]}
          onRowClick={(i) => setModal({ tipo: 'detalle', id: ordenes.datos[i].id_orden })}
          rows={ordenes.datos.map((o) => [
            <Mono bold>{o.folio}</Mono>,
            <Texto bold>{o.producto}</Texto>,
            <StatusBadge status={o.estado} map={COLOR_ORDEN} />,
            <Mono>{miles(o.cantidad_planeada)}</Mono>,
            <Mono color={o.cantidad_terminada ? 'up' : 'dim'}>
              {o.cantidad_terminada ? miles(o.cantidad_terminada) : '—'}
            </Mono>,
            <Mono>{pesos(o.costo_materia_real, { centavos: true })}</Mono>,
            <Mono color="dim">{miles(o.merma_total)}</Mono>,
            <Mono bold>
              {o.costo_unitario_manufactura
                ? pesos(o.costo_unitario_manufactura, { centavos: true })
                : '—'}
            </Mono>,
            o.desviacion_consumo ? (
              <Tag color="down">mayor a 20 %</Tag>
            ) : (
              <Tag color="muted">normal</Tag>
            ),
            <Texto dim>{o.responsable}</Texto>,
          ])}
        />
      </Panel>
      <Modal
        abierto={modal?.tipo === 'nueva'}
        titulo="Nueva orden de producción"
        onCerrar={cerrar}
        ancho="max-w-2xl"
      >
        {modal?.tipo === 'nueva' && (
          <FormOrden
            usuario={usuario}
            onListo={() => {
              cerrar();
              recargar();
            }}
            onCancelar={cerrar}
          />
        )}
      </Modal>
      <Modal
        abierto={modal?.tipo === 'detalle' && !!seleccionada}
        titulo={`Orden ${seleccionada?.folio ?? ''}`}
        onCerrar={cerrar}
        ancho="max-w-3xl"
      >
        {seleccionada && (
          <DetalleOrden
            orden={seleccionada}
            escribe={escribe}
            usuario={usuario}
            onCambio={recargar}
          />
        )}
      </Modal>
    </>
  );
}

function FormOrden({ usuario, onListo, onCancelar }) {
  const productos = useDatos(listarProductosConBom);
  const [f, , campo] = useFormulario({
    fecha_inicio_programada: hoyIso(),
    fecha_fin_programada: hoyIso(),
    responsable: usuario?.nombre ?? '',
  });
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);
  if (productos.cargando) return <Cargando />;
  const producto = productos.datos?.find((p) => String(p.id_producto) === String(f.id_producto));

  async function guardar(e) {
    e.preventDefault();
    if (!producto) return setError('Elige un producto con lista de materiales (RN-A1-10).');
    if (!(Number(f.cantidad_planeada) > 0))
      return setError('La cantidad planeada debe ser mayor a cero.');
    if (!f.responsable.trim()) return setError('Indica el responsable de la orden.');
    setEnviando(true);
    setError('');
    try {
      await crearOrden(f);
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    } finally {
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <RejillaForm>
        <Campo etiqueta="Producto terminado" ayuda="Solo productos con lista de materiales">
          <Selector
            opciones={(productos.datos ?? []).map((p) => ({
              valor: p.id_producto,
              etiqueta: p.nombre,
            }))}
            {...campo('id_producto')}
          />
        </Campo>
        <Campo etiqueta="Cantidad planeada">
          <Entrada type="number" min="1" {...campo('cantidad_planeada')} />
        </Campo>
        <Campo etiqueta="Inicio programado">
          <Entrada type="date" {...campo('fecha_inicio_programada')} />
        </Campo>
        <Campo etiqueta="Fin programado">
          <Entrada type="date" {...campo('fecha_fin_programada')} />
        </Campo>
        <Campo etiqueta="Responsable">
          <Entrada {...campo('responsable')} />
        </Campo>
      </RejillaForm>
      {producto && (
        <Table
          headers={['Materia prima', 'Por unidad', 'Consumo teórico', 'Stock', 'Costo teórico']}
          rows={producto.bom.map((m) => {
            const teorico = m.cantidad_por_unidad * (Number(f.cantidad_planeada) || 0);
            return [
              <Texto bold>{m.nombre}</Texto>,
              <Mono>
                {m.cantidad_por_unidad} {m.unidad_medida.toLowerCase()}
              </Mono>,
              <Mono bold>{miles(teorico)}</Mono>,
              <Mono color={Number(m.stock) < teorico ? 'down' : 'up'}>{miles(m.stock)}</Mono>,
              <Mono>{pesos(teorico * Number(m.costo_unitario), { centavos: true })}</Mono>,
            ];
          })}
        />
      )}
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onCancelar}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Creando…' : 'Crear orden'}
        </Boton>
      </Acciones>
    </form>
  );
}

function DetalleOrden({ orden, escribe, usuario, onCambio }) {
  const bom = useDatos(listarProductosConBom);
  const consumos = useDatos(() => obtenerConsumos(orden.id_orden), [orden.id_orden, orden.estado]);
  const [accion, setAccion] = useState(null);
  const [f, setF, campo] = useFormulario({});
  const [aviso, setAviso] = useState(null);
  const [enviando, setEnviando] = useState(false);
  const materias = useMemo(
    () => bom.datos?.find((p) => p.id_producto === orden.id_producto_destino)?.bom ?? [],
    [bom.datos, orden.id_producto_destino]
  );
  const final = ['TERMINADA', 'CANCELADA'].includes(orden.estado);

  async function ejecutar(fn, textoOk) {
    setEnviando(true);
    setAviso(null);
    try {
      await fn();
      setAviso({ tipo: 'ok', texto: textoOk });
      setAccion(null);
      setF({});
      onCambio();
      consumos.recargar();
    } catch (err) {
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Dato etiqueta="Producto" valor={orden.producto} />
        <Dato etiqueta="Estado" valor={<StatusBadge status={orden.estado} map={COLOR_ORDEN} />} />
        <Dato etiqueta="Responsable" valor={orden.responsable} />
        <Dato
          etiqueta="Planeada / terminada"
          valor={
            <Mono>
              {miles(orden.cantidad_planeada)} / {orden.cantidad_terminada ?? '—'}
            </Mono>
          }
        />
        <Dato
          etiqueta="Materia teórica / real"
          valor={
            <Mono>
              {pesos(orden.costo_materia_teorico)} / {pesos(orden.costo_materia_real)}
            </Mono>
          }
        />
        <Dato
          etiqueta="Costo unitario"
          valor={
            <Mono bold color="up">
              {orden.costo_unitario_manufactura
                ? pesos(orden.costo_unitario_manufactura, { centavos: true })
                : 'al cerrar'}
            </Mono>
          }
        />
      </RejillaForm>
      {orden.desviacion_consumo && (
        <Mensaje>El consumo real supera en más de 20 % al teórico (RN-A1-14).</Mensaje>
      )}
      {orden.estado === 'TERMINADA' && (
        <Mensaje tipo="ok">
          Orden cerrada: {miles(orden.cantidad_terminada)} unidades entraron al inventario con
          proveedor PRODUCCIÓN INTERNA a{' '}
          {pesos(orden.costo_unitario_manufactura, { centavos: true })} por unidad. Ya no acepta
          cambios.
        </Mensaje>
      )}

      <div>
        <div className="text-[10.5px] uppercase tracking-[0.04em] text-text-dim mb-2">
          Consumos registrados
        </div>
        <div className="px-[22px] py-5">
          {consumos.cargando ? (
            <Cargando />
          ) : (
            <Table
              headers={['Materia', 'Cantidad real', 'Merma', 'Motivo', 'Turno']}
              vacio="Sin consumos"
              rows={(consumos.datos ?? []).map((c) => [
                <Texto bold>{c.materias_primas?.nombre}</Texto>,
                <Mono>{miles(c.cantidad_real)}</Mono>,
                <Mono color={Number(c.merma) > 0 ? 'accent' : 'dim'}>{miles(c.merma)}</Mono>,
                <Texto dim>{c.motivo_merma ?? '—'}</Texto>,
                <Texto dim>{c.turno ?? '—'}</Texto>,
              ])}
            />
          )}
        </div>
      </div>

      {escribe && !final && (
        <div className="flex flex-wrap gap-2">
          {orden.estado === 'PLANEADA' && (
            <Boton
              variante="primario"
              disabled={enviando}
              onClick={() =>
                ejecutar(
                  () => cambiarEstadoOrden(orden.id_orden, 'EN_PROCESO'),
                  'La orden pasó a EN_PROCESO.'
                )
              }
            >
              Iniciar producción
            </Boton>
          )}
          {orden.estado === 'EN_PROCESO' && (
            <Boton onClick={() => setAccion('consumo')}>Capturar consumo</Boton>
          )}
          {orden.estado === 'EN_PROCESO' && (
            <Boton variante="primario" onClick={() => setAccion('calidad-paso')}>
              Pasar a calidad
            </Boton>
          )}
          {orden.estado === 'EN_CALIDAD' && !orden.aprobadas && (
            <Boton
              variante="primario"
              onClick={() => {
                setAccion('calidad');
                setF({ rechazadas: '0' });
              }}
            >
              Registrar control de calidad
            </Boton>
          )}
          {orden.estado === 'EN_CALIDAD' && orden.aprobadas > 0 && (
            <Boton
              variante="primario"
              disabled={enviando}
              onClick={() =>
                ejecutar(
                  () => cambiarEstadoOrden(orden.id_orden, 'TERMINADA'),
                  'Orden terminada y entrada generada en el inventario.'
                )
              }
            >
              Terminar y cerrar orden
            </Boton>
          )}
          <Boton
            variante="peligro"
            disabled={enviando}
            onClick={() =>
              ejecutar(
                () => cambiarEstadoOrden(orden.id_orden, 'CANCELADA'),
                'La orden quedó cancelada.'
              )
            }
          >
            Cancelar orden
          </Boton>
        </div>
      )}

      {accion === 'consumo' && (
        <form
          className="flex flex-col gap-3 border-t border-border pt-4"
          onSubmit={(e) => {
            e.preventDefault();
            ejecutar(
              () => capturarConsumo({ ...f, id_orden: orden.id_orden }),
              'Consumo registrado.'
            );
          }}
        >
          <RejillaForm columnas={3}>
            <Campo etiqueta="Materia prima">
              <Selector
                opciones={materias.map((m) => ({
                  valor: m.id_materia,
                  etiqueta: `${m.nombre} (stock ${miles(m.stock)})`,
                }))}
                {...campo('id_materia')}
              />
            </Campo>
            <Campo etiqueta="Cantidad real" ayuda="Incluye la merma">
              <Entrada type="number" min="0.001" step="0.001" {...campo('cantidad_real')} />
            </Campo>
            <Campo etiqueta="Merma">
              <Entrada type="number" min="0" step="0.001" {...campo('merma')} />
            </Campo>
            <Campo etiqueta="Motivo de merma">
              <Entrada {...campo('motivo_merma')} />
            </Campo>
            <Campo etiqueta="Turno">
              <Entrada {...campo('turno')} />
            </Campo>
          </RejillaForm>
          <Acciones>
            <Boton type="button" onClick={() => setAccion(null)}>
              Cancelar
            </Boton>
            <Boton variante="primario" type="submit" disabled={enviando}>
              Guardar consumo
            </Boton>
          </Acciones>
        </form>
      )}
      {accion === 'calidad-paso' && (
        <form
          className="flex flex-col gap-3 border-t border-border pt-4"
          onSubmit={(e) => {
            e.preventDefault();
            ejecutar(
              () => cambiarEstadoOrden(orden.id_orden, 'EN_CALIDAD', f),
              'La orden pasó a EN_CALIDAD.'
            );
          }}
        >
          <RejillaForm>
            <Campo etiqueta="Mano de obra directa">
              <Entrada type="number" min="0" step="0.01" {...campo('costo_mano_obra')} />
            </Campo>
            <Campo etiqueta="Costos indirectos">
              <Entrada type="number" min="0" step="0.01" {...campo('costos_indirectos')} />
            </Campo>
          </RejillaForm>
          <Acciones>
            <Boton type="button" onClick={() => setAccion(null)}>
              Cancelar
            </Boton>
            <Boton variante="primario" type="submit" disabled={enviando}>
              Pasar a calidad
            </Boton>
          </Acciones>
        </form>
      )}
      {accion === 'calidad' && (
        <form
          className="flex flex-col gap-3 border-t border-border pt-4"
          onSubmit={(e) => {
            e.preventDefault();
            ejecutar(
              () => registrarCalidad({ ...f, id_orden: orden.id_orden }),
              'Control de calidad registrado.'
            );
          }}
        >
          <RejillaForm columnas={3}>
            <Campo etiqueta="Aprobadas">
              <Entrada type="number" min="0" {...campo('aprobadas')} />
            </Campo>
            <Campo etiqueta="Rechazadas">
              <Entrada type="number" min="0" {...campo('rechazadas')} />
            </Campo>
            <Campo etiqueta="Inspector" ayuda={`Distinto de ${orden.responsable}`}>
              <Entrada {...campo('responsable')} placeholder={usuario?.nombre} />
            </Campo>
          </RejillaForm>
          <Campo etiqueta="Motivo de rechazo">
            <Entrada {...campo('motivo_rechazo')} />
          </Campo>
          <Acciones>
            <Boton type="button" onClick={() => setAccion(null)}>
              Cancelar
            </Boton>
            <Boton variante="primario" type="submit" disabled={enviando}>
              Guardar inspección
            </Boton>
          </Acciones>
        </form>
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

function MateriasPrimas({ escribe }) {
  const materias = useDatos(listarMateriasPrimas);
  const [modal, setModal] = useState(null);
  const recargar = () => {
    setModal(null);
    materias.recargar();
  };
  if (materias.cargando && !materias.datos) return <Cargando />;
  if (materias.error) return <Mensaje>{mensajeDeError(materias.error)}</Mensaje>;
  return (
    <>
      <Panel
        title="Materias primas en almacén de insumos"
        acciones={
          escribe && (
            <>
              <Boton onClick={() => setModal('entrada')}>Registrar compra</Boton>
              <Boton variante="primario" onClick={() => setModal('nueva')}>
                + Nueva materia
              </Boton>
            </>
          )
        }
      >
        <Table
          headers={[
            'SKU',
            'Materia prima',
            'Unidad',
            'Último costo',
            'Stock',
            'Almacén',
            'Proveedor',
          ]}
          rows={materias.datos.map((m) => [
            <Mono>{m.sku}</Mono>,
            <Texto bold>{m.nombre}</Texto>,
            <Tag color="muted">{m.unidad_medida.toLowerCase()}</Tag>,
            <Mono>{pesos(m.costo_unitario, { centavos: true })}</Mono>,
            <Mono bold color={Number(m.stock) === 0 ? 'down' : 'text'}>
              {miles(m.stock)}
            </Mono>,
            <Texto dim>{m.almacenes?.nombre}</Texto>,
            <Texto dim>{m.proveedores?.nombre ?? '—'}</Texto>,
          ])}
        />
      </Panel>
      <Modal
        abierto={!!modal}
        titulo={modal === 'nueva' ? 'Nueva materia prima' : 'Compra de materia prima'}
        onCerrar={() => setModal(null)}
      >
        {modal && (
          <FormMateria
            tipo={modal}
            materias={materias.datos}
            onListo={recargar}
            onCancelar={() => setModal(null)}
          />
        )}
      </Modal>
    </>
  );
}

function FormMateria({ tipo, materias, onListo, onCancelar }) {
  const catalogos = useDatos(() =>
    Promise.all([
      listarProveedores({ soloActivos: true }),
      listarAlmacenes({ tipo: 'INSUMOS', soloActivos: true }),
    ])
  );
  const [f, , campo] = useFormulario({ unidad_medida: 'PIEZA' });
  const [error, setError] = useState('');
  if (catalogos.cargando) return <Cargando />;
  const [proveedores, almacenes] = catalogos.datos ?? [[], []];

  async function guardar(e) {
    e.preventDefault();
    setError('');
    try {
      if (tipo === 'nueva') {
        if (!f.sku || !f.nombre || !f.id_almacen)
          return setError('SKU, nombre y almacén son obligatorios.');
        await crearMateriaPrima(f);
      } else {
        if (!f.id_materia || !(Number(f.cantidad) > 0) || f.costo_unitario === undefined)
          return setError('Materia, cantidad y costo son obligatorios.');
        await registrarEntradaMateria(f);
      }
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      {tipo === 'nueva' ? (
        <RejillaForm>
          <Campo etiqueta="SKU" ayuda="Prefijo MP-">
            <Entrada {...campo('sku')} />
          </Campo>
          <Campo etiqueta="Nombre">
            <Entrada {...campo('nombre')} />
          </Campo>
          <Campo etiqueta="Unidad">
            <Selector
              placeholder="PIEZA"
              opciones={['METRO', 'KILO', 'LITRO'].map((u) => ({ valor: u, etiqueta: u }))}
              value={f.unidad_medida === 'PIEZA' ? '' : f.unidad_medida}
              onChange={(e) =>
                campo('unidad_medida').onChange({ target: { value: e.target.value || 'PIEZA' } })
              }
            />
          </Campo>
          <Campo etiqueta="Almacén de insumos">
            <Selector
              opciones={almacenes.map((a) => ({ valor: a.id_almacen, etiqueta: a.nombre }))}
              {...campo('id_almacen')}
            />
          </Campo>
          <Campo etiqueta="Proveedor">
            <Selector
              opciones={proveedores.map((p) => ({ valor: p.id_proveedor, etiqueta: p.nombre }))}
              {...campo('id_proveedor')}
            />
          </Campo>
        </RejillaForm>
      ) : (
        <RejillaForm>
          <Campo etiqueta="Materia prima">
            <Selector
              opciones={materias.map((m) => ({ valor: m.id_materia, etiqueta: m.nombre }))}
              {...campo('id_materia')}
            />
          </Campo>
          <Campo etiqueta="Cantidad">
            <Entrada type="number" min="0.001" step="0.001" {...campo('cantidad')} />
          </Campo>
          <Campo etiqueta="Costo unitario">
            <Entrada type="number" min="0" step="0.01" {...campo('costo_unitario')} />
          </Campo>
          <Campo etiqueta="Proveedor">
            <Selector
              opciones={proveedores.map((p) => ({ valor: p.id_proveedor, etiqueta: p.nombre }))}
              {...campo('id_proveedor')}
            />
          </Campo>
          <Campo etiqueta="Documento">
            <Entrada {...campo('documento_ref')} />
          </Campo>
        </RejillaForm>
      )}
      {error && <Mensaje>{error}</Mensaje>}
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

function Proveedores({ escribe }) {
  const lista = useDatos(() => listarProveedores());
  const [editando, setEditando] = useState(null);
  if (lista.cargando && !lista.datos) return <Cargando />;
  if (lista.error) return <Mensaje>{mensajeDeError(lista.error)}</Mensaje>;
  return (
    <>
      <Panel
        title="Proveedores de mercancía"
        acciones={
          escribe && (
            <Boton
              variante="primario"
              onClick={() => setEditando({ pais: 'México', activo: true })}
            >
              + Nuevo proveedor
            </Boton>
          )
        }
      >
        <Table
          headers={['Proveedor', 'RFC', 'País', 'Contacto', 'Estado', '']}
          rows={lista.datos.map((p) => [
            <Texto bold>{p.nombre}</Texto>,
            <Mono>{p.rfc ?? '—'}</Mono>,
            <Texto dim>{p.pais}</Texto>,
            <Texto dim>{p.contacto ?? '—'}</Texto>,
            <Tag color={p.activo ? 'up' : 'muted'}>{p.activo ? 'activo' : 'inactivo'}</Tag>,
            escribe ? <Boton onClick={() => setEditando(p)}>Editar</Boton> : null,
          ])}
        />
      </Panel>
      <Modal
        abierto={!!editando}
        titulo={editando?.id_proveedor ? 'Editar proveedor' : 'Nuevo proveedor'}
        onCerrar={() => setEditando(null)}
      >
        {editando && (
          <FormCatalogo
            inicial={editando}
            guardar={guardarProveedor}
            onListo={() => {
              setEditando(null);
              lista.recargar();
            }}
            campos={[
              { nombre: 'nombre', etiqueta: 'Razón social' },
              { nombre: 'rfc', etiqueta: 'RFC', ayuda: 'Vacío para proveedores extranjeros' },
              { nombre: 'pais', etiqueta: 'País' },
              { nombre: 'contacto', etiqueta: 'Contacto' },
            ]}
          />
        )}
      </Modal>
    </>
  );
}

function Almacenes({ escribe }) {
  const lista = useDatos(() => listarAlmacenes());
  const [editando, setEditando] = useState(null);
  if (lista.cargando && !lista.datos) return <Cargando />;
  if (lista.error) return <Mensaje>{mensajeDeError(lista.error)}</Mensaje>;
  return (
    <>
      <Panel
        title="Almacenes"
        acciones={
          escribe && (
            <Boton
              variante="primario"
              onClick={() => setEditando({ tipo: 'INSUMOS', activo: true })}
            >
              + Nuevo almacén
            </Boton>
          )
        }
      >
        <Table
          headers={['Almacén', 'Tipo', 'Ubicación', 'Estado', '']}
          rows={lista.datos.map((a) => [
            <Texto bold>{a.nombre}</Texto>,
            <Tag color={a.tipo === 'INSUMOS' ? 'accent' : 'muted'}>
              {a.tipo === 'INSUMOS' ? 'insumos' : 'producto terminado'}
            </Tag>,
            <Texto dim>{a.ubicacion ?? '—'}</Texto>,
            <Tag color={a.activo ? 'up' : 'muted'}>{a.activo ? 'activo' : 'inactivo'}</Tag>,
            escribe ? <Boton onClick={() => setEditando(a)}>Editar</Boton> : null,
          ])}
        />
      </Panel>
      <Modal
        abierto={!!editando}
        titulo={editando?.id_almacen ? 'Editar almacén' : 'Nuevo almacén'}
        onCerrar={() => setEditando(null)}
      >
        {editando && (
          <FormCatalogo
            inicial={editando}
            guardar={guardarAlmacen}
            onListo={() => {
              setEditando(null);
              lista.recargar();
            }}
            campos={[
              { nombre: 'nombre', etiqueta: 'Nombre' },
              {
                nombre: 'tipo',
                etiqueta: 'Tipo',
                opciones: [
                  { valor: 'INSUMOS', etiqueta: 'Insumos' },
                  { valor: 'PRODUCTO_TERMINADO', etiqueta: 'Producto terminado' },
                ],
              },
              { nombre: 'ubicacion', etiqueta: 'Ubicación' },
            ]}
          />
        )}
      </Modal>
    </>
  );
}

// Alta, edición y baja lógica de un catálogo simple
function FormCatalogo({ inicial, campos, guardar, onListo }) {
  const [f, setF, campo] = useFormulario(inicial);
  const [error, setError] = useState('');
  async function enviar(e) {
    e.preventDefault();
    if (!f.nombre?.trim()) return setError('El nombre es obligatorio.');
    setError('');
    try {
      await guardar(f);
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    }
  }
  return (
    <form onSubmit={enviar} className="flex flex-col gap-4">
      <RejillaForm>
        {campos.map((c) => (
          <Campo key={c.nombre} etiqueta={c.etiqueta} ayuda={c.ayuda}>
            {c.opciones ? (
              <Selector opciones={c.opciones} {...campo(c.nombre)} />
            ) : (
              <Entrada {...campo(c.nombre)} />
            )}
          </Campo>
        ))}
        {inicial.id_proveedor || inicial.id_almacen ? (
          <Campo etiqueta="Estado">
            <Selector
              placeholder="Activo"
              opciones={[{ valor: 'no', etiqueta: 'Inactivo (baja lógica)' }]}
              value={f.activo ? '' : 'no'}
              onChange={(e) => setF({ ...f, activo: e.target.value !== 'no' })}
            />
          </Campo>
        ) : null}
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

function Recepcion() {
  const disc = useDatos(listarDiscrepanciasRecepcion);
  const reab = useDatos(listarReabastecimiento);
  return (
    <div className="grid grid-cols-2 max-[960px]:grid-cols-1 gap-3.5">
      <Panel title="Discrepancias de recepción">
        {disc.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={[
              'Fecha',
              'Producto',
              'Proveedor',
              'Esperada',
              'Recibida',
              'Diferencia',
              'Mercancía',
            ]}
            vacio="Sin discrepancias"
            rows={(disc.datos ?? []).map((d) => [
              <Mono color="dim">{fechaCorta(d.fecha)}</Mono>,
              <Texto bold>{d.nombre}</Texto>,
              <Texto dim>{d.proveedor ?? '—'}</Texto>,
              <Mono>{d.cantidad_esperada ? miles(d.cantidad_esperada) : '—'}</Mono>,
              <Mono>{miles(d.cantidad)}</Mono>,
              <Mono bold color={Number(d.diferencia) < 0 ? 'down' : 'up'}>
                {d.diferencia ?? '—'}
              </Mono>,
              <StatusBadge status={d.estado_mercancia} map={COLOR_MERCANCIA} />,
            ])}
          />
        )}
      </Panel>
      <Panel title="Productos bajo su stock mínimo">
        {reab.cargando ? (
          <Cargando />
        ) : (
          <Table
            headers={['SKU', 'Producto', 'Stock', 'Mínimo', 'Faltante']}
            vacio="Todo el catálogo está sobre su mínimo"
            rows={(reab.datos ?? []).map((r) => [
              <Mono>{r.sku ?? '—'}</Mono>,
              <Texto bold>{r.nombre}</Texto>,
              <Mono color="down">{miles(r.stock)}</Mono>,
              <Mono>{miles(r.stock_minimo)}</Mono>,
              <Mono bold color="accent">
                {miles(r.faltante)}
              </Mono>,
            ])}
          />
        )}
      </Panel>
    </div>
  );
}
