import { useEffect, useMemo, useState } from 'react';
import { z } from 'zod';
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
  listarClientesResumen,
  listarClientesActivos,
  guardarCliente,
  cambiarActivoCliente,
  RFC_VALIDO,
} from '@/services/area2/clientes';
import {
  listarFacturas,
  obtenerFactura,
  listarAgentes,
  listarProductosVenta,
  crearFactura,
  agregarRenglon,
  eliminarRenglon,
  cambiarEstadoPago,
  listarPendientes,
  listarVentasPorAgente,
} from '@/services/area2/facturas';

const PESTANAS = [
  { id: 'facturas', etiqueta: 'Facturas' },
  { id: 'pendientes', etiqueta: 'Pendientes de cobro' },
  { id: 'clientes', etiqueta: 'Comercializadores' },
  { id: 'agentes', etiqueta: 'Ventas por agente' },
];

// Semántica de la referencia: pagada verde, pendiente ámbar, vencida rojo, cancelada neutro
const COLOR_PAGO = {
  PAGADO: 'up',
  PENDIENTE: 'accent',
  PARCIAL: 'accent',
  CANCELADO: 'muted',
  VENCIDA: 'down',
};
const ETIQUETA_PAGO = {
  PAGADO: 'pagada',
  PENDIENTE: 'pendiente',
  PARCIAL: 'parcial',
  CANCELADO: 'cancelada',
  VENCIDA: 'vencida',
};

function estadoVisible(f) {
  if (['PENDIENTE', 'PARCIAL'].includes(f.estado_pago) && f.fecha_vencimiento < hoyIso())
    return 'VENCIDA';
  return f.estado_pago;
}

export default function Contable() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'contable');
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('facturas');
  const [modal, setModal] = useState(null);
  const facturas = useDatos(listarFacturas);
  const clientes = useDatos(listarClientesResumen);

  useEffect(() => {
    set({
      acciones: (
        <>
          <Boton
            onClick={() => exportarCsv('facturas', (facturas.datos ?? []).map(aplanarFactura))}
          >
            Exportar
          </Boton>
          {escribe && (
            <Boton variante="primario" onClick={() => setModal({ tipo: 'nueva' })}>
              + Nueva factura
            </Boton>
          )}
        </>
      ),
    });
    return () => set({});
  }, [set, escribe, facturas.datos]);

  if ((facturas.cargando && !facturas.datos) || (clientes.cargando && !clientes.datos))
    return <Cargando />;
  if (facturas.error || clientes.error)
    return <Mensaje>{mensajeDeError(facturas.error ?? clientes.error)}</Mensaje>;

  const recargarTodo = () => {
    facturas.recargar();
    clientes.recargar();
  };
  const noCanceladas = facturas.datos.filter((f) => f.estado_pago !== 'CANCELADO');
  const delMes = noCanceladas.filter((f) => String(f.fecha).startsWith(periodoActual()));
  const activos = clientes.datos.filter((c) => c.activo).length;
  const pendiente = clientes.datos.reduce((a, c) => a + Number(c.monto_pendiente), 0);
  const vencido = clientes.datos.reduce((a, c) => a + Number(c.monto_vencido), 0);
  const conVencido = clientes.datos.filter((c) => Number(c.monto_vencido) > 0).length;

  return (
    <>
      <FilaKpi>
        <KpiCard
          label="Comercializadores activos"
          value={miles(activos)}
          delta={`${clientes.datos.length - activos} de baja`}
          up
        />
        <KpiCard
          label="Facturación del mes"
          value={pesos(delMes.reduce((a, f) => a + Number(f.valor_total), 0))}
          delta={`${delMes.length} facturas`}
          up
          sub="con IVA"
        />
        <KpiCard
          label="Pendiente de cobro"
          value={pesos(pendiente)}
          delta={`${facturas.datos.filter((f) => ['PENDIENTE', 'PARCIAL'].includes(f.estado_pago)).length} facturas`}
          up={false}
        />
        <KpiCard
          label="Cartera vencida"
          value={pesos(vencido)}
          delta={`${conVencido} ${conVencido === 1 ? 'cliente' : 'clientes'}`}
          up={vencido === 0}
        />
      </FilaKpi>

      <Pestanas opciones={PESTANAS} activa={pestana} onCambiar={setPestana} />

      {pestana === 'facturas' && (
        <div className="grid grid-cols-[1fr_300px] max-[960px]:grid-cols-1 gap-3.5">
          <Panel title="Registro de facturas">
            <Table
              headers={['Folio', 'Comercializador', 'Agente', 'Fecha', 'Vence', 'Total', 'Estatus']}
              onRowClick={(i) => setModal({ tipo: 'detalle', id: facturas.datos[i].id_factura })}
              rows={facturas.datos.map((f) => [
                <Mono bold>{f.folio}</Mono>,
                <Texto bold>{f.clientes?.nombre_empresa}</Texto>,
                <Texto dim>{f.agentes_ventas?.nombre}</Texto>,
                <Mono color="dim">{fechaCorta(f.fecha)}</Mono>,
                <Mono color="dim">{fechaCorta(f.fecha_vencimiento)}</Mono>,
                <Mono bold>{pesos(f.valor_total, { centavos: true })}</Mono>,
                <StatusBadge
                  status={estadoVisible(f)}
                  map={COLOR_PAGO}
                  etiquetas={ETIQUETA_PAGO}
                />,
              ])}
            />
          </Panel>
          <Panel title="Top 5 comercializadores">
            {clientes.datos.slice(0, 5).map((c) => (
              <div
                key={c.id_cliente}
                className="flex justify-between items-center gap-3 py-2.5 border-b border-border last:border-b-0"
              >
                <div className="min-w-0">
                  <div className="text-[12.5px] font-medium truncate">{c.nombre_empresa}</div>
                  <div className="text-[11px] text-text-dim mt-0.5">
                    {c.numero_comercializador} · {c.numero_facturas} facturas
                  </div>
                </div>
                <Mono bold color="up">
                  {pesos(c.monto_total_facturado)}
                </Mono>
              </div>
            ))}
          </Panel>
        </div>
      )}
      {pestana === 'pendientes' && (
        <Pendientes clientes={clientes.datos} onAbrir={(id) => setModal({ tipo: 'detalle', id })} />
      )}
      {pestana === 'clientes' && (
        <Clientes clientes={clientes.datos} escribe={escribe} onCambio={recargarTodo} />
      )}
      {pestana === 'agentes' && <VentasAgente />}

      <Modal
        abierto={modal?.tipo === 'nueva'}
        titulo="Nueva factura"
        onCerrar={() => setModal(null)}
      >
        {modal?.tipo === 'nueva' && (
          <FormCabecera
            onCreada={(f) => {
              recargarTodo();
              setModal({ tipo: 'detalle', id: f.id_factura, recienCreada: f });
            }}
            onCancelar={() => setModal(null)}
          />
        )}
      </Modal>
      <Modal
        abierto={modal?.tipo === 'detalle'}
        titulo="Detalle de factura"
        onCerrar={() => setModal(null)}
        ancho="max-w-3xl"
      >
        {modal?.tipo === 'detalle' && (
          <DetalleFactura
            id={modal.id}
            recienCreada={modal.recienCreada}
            escribe={escribe}
            onCambio={recargarTodo}
          />
        )}
      </Modal>
    </>
  );
}

function aplanarFactura(f) {
  return {
    folio: f.folio,
    comercializador: f.clientes?.nombre_empresa,
    agente: f.agentes_ventas?.nombre,
    fecha: f.fecha,
    fecha_vencimiento: f.fecha_vencimiento,
    fecha_cobro: f.fecha_cobro,
    subtotal: f.subtotal,
    iva: f.iva,
    total: f.valor_total,
    estado: f.estado_pago,
  };
}

function FormCabecera({ onCreada, onCancelar }) {
  const catalogos = useDatos(() => Promise.all([listarClientesActivos(), listarAgentes()]));
  const [f, setF] = useState({ fecha: hoyIso() });
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);
  if (catalogos.cargando) return <Cargando />;
  if (catalogos.error) return <Mensaje>{mensajeDeError(catalogos.error)}</Mensaje>;
  const [clientes, agentes] = catalogos.datos;

  async function guardar(e) {
    e.preventDefault();
    if (!f.id_cliente || !f.id_agente)
      return setError('La factura necesita comercializador y agente (RN-A2-01).');
    setEnviando(true);
    setError('');
    try {
      onCreada(await crearFactura(f));
    } catch (err) {
      setError(mensajeDeError(err));
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4">
      <Campo etiqueta="Comercializador" ayuda="Solo comercializadores activos">
        <Selector
          opciones={clientes.map((c) => ({
            valor: c.id_cliente,
            etiqueta: `${c.numero_comercializador} · ${c.nombre_empresa}`,
          }))}
          value={f.id_cliente ?? ''}
          onChange={(e) => setF({ ...f, id_cliente: e.target.value })}
        />
      </Campo>
      <Campo etiqueta="Agente de ventas">
        <Selector
          opciones={agentes
            .filter((a) => a.estatus !== 'BAJA')
            .map((a) => ({ valor: a.id_agente, etiqueta: a.nombre }))}
          value={f.id_agente ?? ''}
          onChange={(e) => setF({ ...f, id_agente: e.target.value })}
        />
      </Campo>
      <RejillaForm>
        <Campo etiqueta="Fecha">
          <Entrada
            type="date"
            value={f.fecha}
            onChange={(e) => setF({ ...f, fecha: e.target.value })}
          />
        </Campo>
        <Campo etiqueta="Vencimiento" ayuda="Vacío: fecha más días de crédito">
          <Entrada
            type="date"
            value={f.fecha_vencimiento ?? ''}
            onChange={(e) => setF({ ...f, fecha_vencimiento: e.target.value })}
          />
        </Campo>
      </RejillaForm>
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onCancelar}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Creando…' : 'Crear y agregar renglones'}
        </Boton>
      </Acciones>
    </form>
  );
}

function DetalleFactura({ id, recienCreada, escribe, onCambio }) {
  const factura = useDatos(() => obtenerFactura(id), [id]);
  const productos = useDatos(listarProductosVenta);
  const [renglon, setRenglon] = useState({ id_producto: '', cantidad: '', precio_unitario: '' });
  const [aviso, setAviso] = useState(
    recienCreada
      ? {
          tipo: 'ok',
          texto: `Factura ${recienCreada.folio} creada; vence el ${fechaCorta(recienCreada.fecha_vencimiento)}. Agrega sus renglones.`,
        }
      : null
  );
  const [enviando, setEnviando] = useState(false);
  const producto = useMemo(
    () => productos.datos?.find((p) => String(p.id_producto) === String(renglon.id_producto)),
    [productos.datos, renglon.id_producto]
  );

  if (factura.cargando && !factura.datos) return <Cargando />;
  if (factura.error) return <Mensaje>{mensajeDeError(factura.error)}</Mensaje>;
  const f = factura.datos;
  const cerrada = ['PAGADO', 'CANCELADO'].includes(f.estado_pago);

  async function ejecutar(fn, textoOk, limpiarRenglon = false) {
    setEnviando(true);
    setAviso(null);
    try {
      await fn();
      setAviso(textoOk ? { tipo: 'ok', texto: textoOk } : null);
      if (limpiarRenglon) setRenglon({ id_producto: '', cantidad: '', precio_unitario: '' });
      await factura.recargar();
      productos.recargar();
      onCambio();
    } catch (err) {
      // El formulario conserva lo capturado para que el usuario corrija (RN-A3-01)
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    } finally {
      setEnviando(false);
    }
  }

  function elegirProducto(idProducto) {
    const p = productos.datos?.find((x) => String(x.id_producto) === idProducto);
    setRenglon((r) => ({
      ...r,
      id_producto: idProducto,
      precio_unitario: p?.precio_venta_sugerido ?? r.precio_unitario,
    }));
  }

  function agregar(e) {
    e.preventDefault();
    if (!renglon.id_producto) return setAviso({ tipo: 'error', texto: 'Elige un producto.' });
    if (!(Number(renglon.cantidad) > 0))
      return setAviso({ tipo: 'error', texto: 'La cantidad debe ser mayor a cero.' });
    if (!(Number(renglon.precio_unitario) > 0))
      return setAviso({ tipo: 'error', texto: 'Indica el precio unitario.' });
    ejecutar(
      () => agregarRenglon({ id_factura: f.id_factura, ...renglon }),
      'Renglón agregado; totales recalculados por la base.',
      true
    );
  }

  function cambiarEstado(estado) {
    if (estado === 'PAGADO' && Number(f.valor_total) === 0) {
      return setAviso({
        tipo: 'error',
        texto: 'Una factura sin renglones no puede marcarse como pagada (RN-A2-04).',
      });
    }
    if (
      estado === 'CANCELADO' &&
      !window.confirm(`¿Cancelar la factura ${f.folio}? No se borra ni se reintegra el stock.`)
    )
      return;
    ejecutar(
      () => cambiarEstadoPago(f.id_factura, estado),
      `Factura marcada como ${ETIQUETA_PAGO[estado]}.`
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <RejillaForm columnas={3}>
        <Dato etiqueta="Folio" valor={<Mono bold>{f.folio}</Mono>} />
        <Dato
          etiqueta="Comercializador"
          valor={`${f.clientes?.numero_comercializador} · ${f.clientes?.nombre_empresa}`}
        />
        <Dato etiqueta="Agente" valor={f.agentes_ventas?.nombre} />
        <Dato
          etiqueta="Fecha / vence"
          valor={
            <Mono>
              {fechaCorta(f.fecha)} · {fechaCorta(f.fecha_vencimiento)}
            </Mono>
          }
        />
        <Dato
          etiqueta="Cobro"
          valor={
            <Mono color={f.fecha_cobro ? 'up' : 'dim'}>
              {f.fecha_cobro ? fechaCorta(f.fecha_cobro) : '—'}
            </Mono>
          }
        />
        <Dato
          etiqueta="Estatus"
          valor={
            <StatusBadge status={estadoVisible(f)} map={COLOR_PAGO} etiquetas={ETIQUETA_PAGO} />
          }
        />
      </RejillaForm>

      <div className="px-[22px] py-5">
        <Table
          headers={['Producto', 'Cantidad', 'Precio', 'Importe', '']}
          vacio="La factura aún no tiene renglones"
          rows={(f.detalle_factura ?? [])
            .sort((a, b) => a.id_detalle - b.id_detalle)
            .map((d) => [
              <Texto bold>{d.productos?.nombre}</Texto>,
              <Mono>{miles(d.cantidad)}</Mono>,
              <Mono>{pesos(d.precio_unitario, { centavos: true })}</Mono>,
              <Mono bold>{pesos(d.importe, { centavos: true })}</Mono>,
              escribe && !cerrada ? (
                <Boton
                  disabled={enviando}
                  onClick={() =>
                    ejecutar(() => eliminarRenglon(d.id_detalle), 'Renglón eliminado.')
                  }
                >
                  Quitar
                </Boton>
              ) : null,
            ])}
        />
      </div>

      <div className="flex justify-end gap-8 border-t border-border pt-3">
        <Dato etiqueta="Subtotal" valor={<Mono>{pesos(f.subtotal, { centavos: true })}</Mono>} />
        <Dato etiqueta="IVA" valor={<Mono>{pesos(f.iva, { centavos: true })}</Mono>} />
        <Dato
          etiqueta="Total"
          valor={
            <Mono bold color="up">
              {pesos(f.valor_total, { centavos: true })}
            </Mono>
          }
        />
      </div>

      {escribe && !cerrada && (
        <form onSubmit={agregar} className="flex flex-col gap-3 border-t border-border pt-4">
          <RejillaForm columnas={3}>
            <Campo etiqueta="Producto">
              <Selector
                opciones={(productos.datos ?? []).map((p) => ({
                  valor: p.id_producto,
                  etiqueta: `${p.nombre} · stock ${miles(p.stock)}`,
                }))}
                value={renglon.id_producto}
                onChange={(e) => elegirProducto(e.target.value)}
              />
            </Campo>
            <Campo
              etiqueta="Cantidad"
              ayuda={producto ? `Disponible: ${miles(producto.stock)}` : undefined}
            >
              <Entrada
                type="number"
                min="1"
                value={renglon.cantidad}
                onChange={(e) => setRenglon({ ...renglon, cantidad: e.target.value })}
              />
            </Campo>
            <Campo etiqueta="Precio unitario" ayuda="Precargado del precio sugerido">
              <Entrada
                type="number"
                min="0"
                step="0.01"
                value={renglon.precio_unitario}
                onChange={(e) => setRenglon({ ...renglon, precio_unitario: e.target.value })}
              />
            </Campo>
          </RejillaForm>
          <div className="flex items-center justify-between gap-3">
            <span className="text-[12px] text-text-dim">
              Importe estimado:{' '}
              <Mono>
                {pesos((Number(renglon.cantidad) || 0) * (Number(renglon.precio_unitario) || 0), {
                  centavos: true,
                })}
              </Mono>
            </span>
            <Boton variante="primario" type="submit" disabled={enviando}>
              {enviando ? 'Guardando…' : 'Agregar renglón'}
            </Boton>
          </div>
        </form>
      )}

      {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}

      {escribe && !cerrada && (
        <div className="flex flex-wrap gap-2 border-t border-border pt-4">
          {f.estado_pago !== 'PARCIAL' && (
            <Boton disabled={enviando} onClick={() => cambiarEstado('PARCIAL')}>
              Registrar pago parcial
            </Boton>
          )}
          <Boton variante="primario" disabled={enviando} onClick={() => cambiarEstado('PAGADO')}>
            Marcar como pagada
          </Boton>
          <Boton variante="peligro" disabled={enviando} onClick={() => cambiarEstado('CANCELADO')}>
            Cancelar factura
          </Boton>
        </div>
      )}
      {cerrada && (
        <Mensaje tipo="info">
          La factura está {ETIQUETA_PAGO[f.estado_pago]}; sus renglones ya no se modifican
          (RN-A2-12).
        </Mensaje>
      )}
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

function Pendientes({ clientes, onAbrir }) {
  const [filtro, setFiltro] = useState({ cliente: '', desde: '', hasta: '' });
  const lista = useDatos(
    () => listarPendientes(filtro),
    [filtro.cliente, filtro.desde, filtro.hasta]
  );
  return (
    <Panel title="Facturas con cobro pendiente">
      <div className="-mt-1 mb-6">
        <RejillaForm columnas={3}>
          <Campo etiqueta="Comercializador">
            <Selector
              placeholder="Todos"
              opciones={clientes.map((c) => ({
                valor: c.numero_comercializador,
                etiqueta: c.nombre_empresa,
              }))}
              value={filtro.cliente}
              onChange={(e) => setFiltro({ ...filtro, cliente: e.target.value })}
            />
          </Campo>
          <Campo etiqueta="Desde">
            <Entrada
              type="date"
              value={filtro.desde}
              onChange={(e) => setFiltro({ ...filtro, desde: e.target.value })}
            />
          </Campo>
          <Campo etiqueta="Hasta">
            <Entrada
              type="date"
              value={filtro.hasta}
              onChange={(e) => setFiltro({ ...filtro, hasta: e.target.value })}
            />
          </Campo>
        </RejillaForm>
      </div>
      {lista.error && <Mensaje>{mensajeDeError(lista.error)}</Mensaje>}
      {lista.cargando ? (
        <Cargando />
      ) : (
        <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
          <Table
            headers={[
              'Folio',
              'Comercializador',
              'Agente',
              'Fecha',
              'Vence',
              'Días vencidos',
              'Total',
              'Estatus',
            ]}
            vacio="No hay facturas pendientes con ese filtro"
            onRowClick={(i) => onAbrir(lista.datos[i].id_factura)}
            rows={(lista.datos ?? []).map((p) => [
              <Mono bold>{p.folio}</Mono>,
              <Texto bold>{p.nombre_empresa}</Texto>,
              <Texto dim>{p.agente}</Texto>,
              <Mono color="dim">{fechaCorta(p.fecha)}</Mono>,
              <Mono color="dim">{fechaCorta(p.fecha_vencimiento)}</Mono>,
              <Mono bold color={p.dias_vencidos > 0 ? 'down' : 'dim'}>
                {p.dias_vencidos}
              </Mono>,
              <Mono bold>{pesos(p.valor_total, { centavos: true })}</Mono>,
              <StatusBadge
                status={p.dias_vencidos > 0 ? 'VENCIDA' : p.estado_pago}
                map={COLOR_PAGO}
                etiquetas={ETIQUETA_PAGO}
              />,
            ])}
          />
        </div>
      )}
    </Panel>
  );
}

const esquemaCliente = z.object({
  nombre_empresa: z.string().trim().min(3, 'Escribe la razón social.'),
  rfc: z
    .string()
    .trim()
    .toUpperCase()
    .regex(RFC_VALIDO, 'RFC con formato inválido (12 o 13 caracteres).')
    .or(z.literal('')),
  estado: z.string().trim().optional(),
  dias_credito: z.coerce.number().int('Días enteros.').min(0, 'No puede ser negativo.'),
});

function Clientes({ clientes, escribe, onCambio }) {
  const [busqueda, setBusqueda] = useState('');
  const [editando, setEditando] = useState(null);
  const [aviso, setAviso] = useState(null);
  const filtrados = clientes.filter((c) =>
    `${c.nombre_empresa} ${c.rfc ?? ''} ${c.numero_comercializador}`
      .toLowerCase()
      .includes(busqueda.toLowerCase())
  );

  async function alternar(c) {
    if (
      c.activo &&
      !window.confirm(
        `¿Dar de baja a ${c.nombre_empresa}? Conserva sus facturas y ya no podrá recibir nuevas.`
      )
    )
      return;
    try {
      await cambiarActivoCliente(c.id_cliente, !c.activo);
      setAviso(null);
      onCambio();
    } catch (err) {
      setAviso(mensajeDeError(err));
    }
  }

  return (
    <>
      <Panel
        title="Comercializadores"
        acciones={
          escribe && (
            <Boton variante="primario" onClick={() => setEditando({ dias_credito: 30 })}>
              + Nuevo comercializador
            </Boton>
          )
        }
      >
        <div className="-mt-1 mb-6 max-w-sm">
          <Entrada
            placeholder="Buscar por nombre, RFC o folio"
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
          />
        </div>
        {aviso && (
          <div className="mb-4">
            <Mensaje>{aviso}</Mensaje>
          </div>
        )}
        <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
          <Table
            headers={[
              'Folio',
              'Comercializador',
              'RFC',
              'Estado',
              'Crédito',
              'Facturado',
              'Pendiente',
              'Vencido',
              'Estatus',
              '',
            ]}
            rows={filtrados.map((c) => [
              <Mono>{c.numero_comercializador}</Mono>,
              <Texto bold>{c.nombre_empresa}</Texto>,
              <Mono color="dim">{c.rfc ?? '—'}</Mono>,
              <Texto dim>{c.estado ?? '—'}</Texto>,
              <Mono color="dim">{c.dias_credito} días</Mono>,
              <Mono>{pesos(c.monto_total_facturado)}</Mono>,
              <Mono color={Number(c.monto_pendiente) > 0 ? 'accent' : 'dim'}>
                {pesos(c.monto_pendiente)}
              </Mono>,
              <Mono bold color={Number(c.monto_vencido) > 0 ? 'down' : 'dim'}>
                {pesos(c.monto_vencido)}
              </Mono>,
              <Tag color={c.activo ? 'up' : 'muted'}>{c.activo ? 'activo' : 'inactivo'}</Tag>,
              escribe ? (
                <span className="flex gap-2">
                  <Boton onClick={() => setEditando(c)}>Editar</Boton>
                  <Boton onClick={() => alternar(c)}>
                    {c.activo ? 'Dar de baja' : 'Reactivar'}
                  </Boton>
                </span>
              ) : null,
            ])}
          />
        </div>
      </Panel>
      <Modal
        abierto={!!editando}
        titulo={editando?.id_cliente ? 'Editar comercializador' : 'Nuevo comercializador'}
        onCerrar={() => setEditando(null)}
      >
        {editando && (
          <FormCliente
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

function FormCliente({ inicial, onListo }) {
  const [f, setF] = useState({
    nombre_empresa: inicial.nombre_empresa ?? '',
    rfc: inicial.rfc ?? '',
    estado: inicial.estado ?? '',
    dias_credito: inicial.dias_credito ?? 30,
  });
  const [errores, setErrores] = useState({});
  const [error, setError] = useState('');

  async function guardar(e) {
    e.preventDefault();
    const r = esquemaCliente.safeParse(f);
    if (!r.success)
      return setErrores(Object.fromEntries(r.error.issues.map((i) => [i.path[0], i.message])));
    setErrores({});
    setError('');
    try {
      await guardarCliente({ ...r.data, id_cliente: inicial.id_cliente });
      onListo();
    } catch (err) {
      setError(mensajeDeError(err));
    }
  }

  return (
    <form onSubmit={guardar} className="flex flex-col gap-4" noValidate>
      <Campo etiqueta="Razón social" error={errores.nombre_empresa}>
        <Entrada
          value={f.nombre_empresa}
          onChange={(e) => setF({ ...f, nombre_empresa: e.target.value })}
        />
      </Campo>
      <RejillaForm columnas={3}>
        <Campo etiqueta="RFC" error={errores.rfc}>
          <Entrada
            value={f.rfc}
            onChange={(e) => setF({ ...f, rfc: e.target.value.toUpperCase() })}
          />
        </Campo>
        <Campo etiqueta="Estado">
          <Entrada
            value={f.estado}
            onChange={(e) => setF({ ...f, estado: e.target.value })}
            placeholder="Jalisco"
          />
        </Campo>
        <Campo etiqueta="Días de crédito" error={errores.dias_credito}>
          <Entrada
            type="number"
            min="0"
            value={f.dias_credito}
            onChange={(e) => setF({ ...f, dias_credito: e.target.value })}
          />
        </Campo>
      </RejillaForm>
      {!inicial.id_cliente && (
        <Mensaje tipo="info">El folio COM-000000 lo asigna el sistema al guardar.</Mensaje>
      )}
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

function VentasAgente() {
  const ventas = useDatos(listarVentasPorAgente);
  if (ventas.cargando) return <Cargando />;
  if (ventas.error) return <Mensaje>{mensajeDeError(ventas.error)}</Mensaje>;
  return (
    <Panel
      title="Ventas por agente"
      acciones={
        <Boton onClick={() => exportarCsv('ventas-por-agente', ventas.datos)}>Exportar CSV</Boton>
      }
    >
      <Table
        headers={['Agente', 'Facturas', 'Vendido con IVA', 'Cobrado sin IVA']}
        rows={ventas.datos.map((v) => [
          <Texto bold>{v.nombre}</Texto>,
          <Mono>{miles(v.numero_facturas)}</Mono>,
          <Mono bold>{pesos(v.monto_vendido, { centavos: true })}</Mono>,
          <Mono color="up">{pesos(v.monto_cobrado_sin_iva, { centavos: true })}</Mono>,
        ])}
      />
    </Panel>
  );
}
