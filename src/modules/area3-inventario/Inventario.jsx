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
import { miles, pesos, porcentaje, fechaCorta } from '@/lib/formato';
import { exportarCsv } from '@/lib/exportar';
import {
  obtenerInventario,
  crearProducto,
  editarProducto,
  obtenerKardex,
  obtenerRotacion,
  obtenerDiscrepancias,
  registrarAjuste,
  registrarEntrada,
} from '@/services/area3/inventario';

const PESTANAS = [
  { id: 'catalogo', etiqueta: 'Catálogo' },
  { id: 'kardex', etiqueta: 'Kardex' },
  { id: 'conciliacion', etiqueta: 'Conciliación' },
  { id: 'reportes', etiqueta: 'Discrepancias y rotación' },
];

// RN-A3-01: etiqueta de existencia como en la referencia (agotado, bajo stock menor a 100, disponible)
function estadoStock(stock) {
  if (stock === 0) return 'agotado';
  if (stock < 100) return 'bajo stock';
  return 'disponible';
}

export default function Inventario() {
  const { usuario } = useAuth();
  const escribe = puedeEscribir(usuario?.rol, 'inventario');
  const { set } = useTopbar();
  const [pestana, setPestana] = useState('catalogo');
  const [modal, setModal] = useState(null);
  const inv = useDatos(obtenerInventario);

  useEffect(() => {
    set({
      acciones: (
        <>
          <Boton onClick={() => exportarCsv('inventario', inv.datos ?? [])}>Exportar</Boton>
          {escribe && (
            <Boton variante="primario" onClick={() => setModal({ tipo: 'producto' })}>
              + Nuevo producto
            </Boton>
          )}
        </>
      ),
    });
    return () => set({});
  }, [set, escribe, inv.datos]);

  if (inv.cargando && !inv.datos) return <Cargando />;
  if (inv.error) return <Mensaje>{mensajeDeError(inv.error)}</Mensaje>;

  const productos = inv.datos;
  const activos = productos.filter((p) => p.activo);
  const unidades = activos.reduce((a, p) => a + p.stock, 0);
  const bajos = activos.filter((p) => p.stock < 100).length;
  const volumen = activos.reduce((a, p) => a + p.volumen, 0);
  const rotacion = volumen ? ((volumen - unidades) / volumen) * 100 : 0;

  return (
    <>
      <FilaKpi columnas={3}>
        <KpiCard
          label="SKUs registrados"
          value={`${activos.length} líneas`}
          delta={`${productos.length - activos.length} inactivos`}
          up
          sub="catálogo general"
        />
        <KpiCard
          label="Unidades en almacén"
          value={`${miles(unidades)} uds`}
          delta={`${bajos} bajo stock`}
          up={bajos === 0}
          sub={pesos(activos.reduce((a, p) => a + Number(p.valor_inventario), 0))}
        />
        <KpiCard
          label="Rotación promedio"
          value={porcentaje(rotacion, 0)}
          delta={`${miles(volumen - unidades)} uds vendidas`}
          up
          sub="histórico"
        />
      </FilaKpi>

      <Pestanas opciones={PESTANAS} activa={pestana} onCambiar={setPestana} />

      {pestana === 'catalogo' && (
        <Panel title="Base de productos · existencias y valor">
          <Table
            headers={[
              'SKU',
              'Producto',
              'Tipo',
              'Stock actual',
              'Entradas',
              'Salidas',
              'Valor entrada',
              'Estado',
              '',
            ]}
            rows={productos.map((p) => [
              <Mono color="dim">{p.sku ?? '—'}</Mono>,
              <Texto bold>{p.nombre}</Texto>,
              <Tag color={p.tipo === 'ELECTRONICO' ? 'accent' : 'muted'}>
                {p.tipo === 'ELECTRONICO' ? 'Electrónico' : 'Manufactura'}
              </Tag>,
              <Mono bold color={p.stock === 0 ? 'down' : p.stock < 100 ? 'accent' : 'text'}>
                {miles(p.stock)}
              </Mono>,
              <Mono color="up">{miles(p.volumen)}</Mono>,
              <Mono color="dim">{miles(p.unidades_vendidas_historico)}</Mono>,
              <Mono>{pesos(p.valor_entrada, { centavos: true })}</Mono>,
              p.activo ? (
                <StatusBadge
                  status={estadoStock(p.stock)}
                  map={{ disponible: 'up', 'bajo stock': 'accent', agotado: 'down' }}
                />
              ) : (
                <Tag color="muted">inactivo</Tag>
              ),
              escribe ? (
                <span className="flex gap-2">
                  <Boton onClick={() => setModal({ tipo: 'entrada', producto: p })}>Entrada</Boton>
                  <Boton onClick={() => setModal({ tipo: 'producto', producto: p })}>Editar</Boton>
                </span>
              ) : null,
            ])}
          />
        </Panel>
      )}

      {pestana === 'kardex' && <Kardex productos={productos} />}
      {pestana === 'conciliacion' && (
        <Conciliacion
          productos={activos}
          escribe={escribe}
          usuario={usuario}
          onGuardado={inv.recargar}
        />
      )}
      {pestana === 'reportes' && <Reportes />}

      <Modal
        abierto={modal?.tipo === 'producto'}
        titulo={modal?.producto ? 'Editar producto' : 'Nuevo producto'}
        onCerrar={() => setModal(null)}
      >
        {modal?.tipo === 'producto' && (
          <FormProducto
            producto={modal.producto}
            onListo={() => {
              setModal(null);
              inv.recargar();
            }}
          />
        )}
      </Modal>
      <Modal
        abierto={modal?.tipo === 'entrada'}
        titulo={`Entrada · ${modal?.producto?.nombre ?? ''}`}
        onCerrar={() => setModal(null)}
      >
        {modal?.tipo === 'entrada' && (
          <FormEntrada
            producto={modal.producto}
            onListo={() => {
              setModal(null);
              inv.recargar();
            }}
          />
        )}
      </Modal>
    </>
  );
}

function FormProducto({ producto, onListo }) {
  const [f, setF] = useState({
    tipo: producto?.tipo ?? '',
    nombre: producto?.nombre ?? '',
    sku: producto?.sku ?? '',
    stock_minimo: producto?.stock_minimo ?? 0,
    activo: producto?.activo ?? true,
  });
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function guardar(e) {
    e.preventDefault();
    if (!f.tipo || !f.nombre.trim()) return setError('El tipo y el nombre son obligatorios.');
    setEnviando(true);
    setError('');
    try {
      if (producto)
        await editarProducto(producto.id_producto, { ...f, stock_minimo: Number(f.stock_minimo) });
      else await crearProducto({ ...f, stock_minimo: Number(f.stock_minimo) });
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
        <Campo etiqueta="Tipo">
          <Selector
            value={f.tipo}
            onChange={(e) => setF({ ...f, tipo: e.target.value })}
            opciones={[
              { valor: 'ELECTRONICO', etiqueta: 'Electrónico' },
              { valor: 'MANUFACTURA', etiqueta: 'Manufactura' },
            ]}
          />
        </Campo>
        <Campo etiqueta="SKU" ayuda="Único; lo usa el área 1">
          <Entrada
            value={f.sku}
            onChange={(e) => setF({ ...f, sku: e.target.value })}
            placeholder="EL-TAB-A10"
          />
        </Campo>
      </RejillaForm>
      <Campo etiqueta="Nombre">
        <Entrada value={f.nombre} onChange={(e) => setF({ ...f, nombre: e.target.value })} />
      </Campo>
      <RejillaForm>
        <Campo etiqueta="Stock mínimo" ayuda="Alerta de reabastecimiento">
          <Entrada
            type="number"
            min="0"
            value={f.stock_minimo}
            onChange={(e) => setF({ ...f, stock_minimo: e.target.value })}
          />
        </Campo>
        {producto && (
          <Campo etiqueta="Estado">
            <Selector
              value={f.activo ? 'si' : 'no'}
              onChange={(e) => setF({ ...f, activo: e.target.value === 'si' })}
              opciones={[
                { valor: 'si', etiqueta: 'Activo' },
                { valor: 'no', etiqueta: 'Inactivo (baja lógica)' },
              ]}
            />
          </Campo>
        )}
      </RejillaForm>
      {!producto && (
        <Mensaje tipo="info">
          El producto nace con stock 0. El stock, volumen y capital los calculan las entradas.
        </Mensaje>
      )}
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onListo}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Guardar'}
        </Boton>
      </Acciones>
    </form>
  );
}

function FormEntrada({ producto, onListo }) {
  const [f, setF] = useState({
    cantidad: '',
    costo_unitario: '',
    proveedor: '',
    documento_ref: '',
  });
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function guardar(e) {
    e.preventDefault();
    if (!(Number(f.cantidad) > 0)) return setError('La cantidad debe ser mayor a cero.');
    if (!(Number(f.costo_unitario) >= 0) || f.costo_unitario === '')
      return setError('Indica el costo unitario.');
    setEnviando(true);
    setError('');
    try {
      await registrarEntrada({ id_producto: producto.id_producto, ...f });
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
        <Campo etiqueta="Cantidad">
          <Entrada
            type="number"
            min="1"
            value={f.cantidad}
            onChange={(e) => setF({ ...f, cantidad: e.target.value })}
          />
        </Campo>
        <Campo etiqueta="Costo unitario">
          <Entrada
            type="number"
            min="0"
            step="0.01"
            value={f.costo_unitario}
            onChange={(e) => setF({ ...f, costo_unitario: e.target.value })}
          />
        </Campo>
        <Campo etiqueta="Proveedor">
          <Entrada
            value={f.proveedor}
            onChange={(e) => setF({ ...f, proveedor: e.target.value })}
          />
        </Campo>
        <Campo etiqueta="Documento">
          <Entrada
            value={f.documento_ref}
            onChange={(e) => setF({ ...f, documento_ref: e.target.value })}
            placeholder="Factura u orden"
          />
        </Campo>
      </RejillaForm>
      <Mensaje tipo="info">
        Capital estimado:{' '}
        <Mono bold>
          {pesos((Number(f.cantidad) || 0) * (Number(f.costo_unitario) || 0), { centavos: true })}
        </Mono>
        . La captura con flete, impuestos y almacén está en Entradas de Producción.
      </Mensaje>
      {error && <Mensaje>{error}</Mensaje>}
      <Acciones>
        <Boton type="button" onClick={onListo}>
          Cancelar
        </Boton>
        <Boton variante="primario" type="submit" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Registrar entrada'}
        </Boton>
      </Acciones>
    </form>
  );
}

function Kardex({ productos }) {
  const [filtro, setFiltro] = useState({ idProducto: '', desde: '', hasta: '' });
  const k = useDatos(() => obtenerKardex(filtro), [filtro.idProducto, filtro.desde, filtro.hasta]);
  const opciones = useMemo(
    () => productos.map((p) => ({ valor: String(p.id_producto), etiqueta: p.nombre })),
    [productos]
  );

  return (
    <Panel title="Kardex · entradas y salidas en orden cronológico">
      <div className="-mt-1 mb-6">
        <RejillaForm columnas={3}>
          <Campo etiqueta="Producto">
            <Selector
              placeholder="Todos"
              opciones={opciones}
              value={filtro.idProducto}
              onChange={(e) => setFiltro({ ...filtro, idProducto: e.target.value })}
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
      {k.error && <Mensaje>{mensajeDeError(k.error)}</Mensaje>}
      {k.cargando ? (
        <Cargando />
      ) : (
        <div className="pt-5 border-t border-border -mx-[22px] px-[22px]">
          <Table
            headers={['Fecha', 'Producto', 'Movimiento', 'Cantidad', 'Precio', 'Referencia']}
            rows={(k.datos ?? []).map((m) => [
              <Mono color="dim">{fechaCorta(m.fecha)}</Mono>,
              <Texto bold>{m.nombre}</Texto>,
              <Tag color={m.movimiento === 'ENTRADA' ? 'up' : 'muted'}>
                {m.movimiento.toLowerCase()}
              </Tag>,
              <Mono color={m.movimiento === 'ENTRADA' ? 'up' : 'dim'}>
                {m.movimiento === 'ENTRADA' ? '+' : '−'}
                {miles(m.cantidad)}
              </Mono>,
              <Mono>{pesos(m.precio, { centavos: true })}</Mono>,
              <Texto dim>{m.referencia ?? '—'}</Texto>,
            ])}
          />
        </div>
      )}
    </Panel>
  );
}

function Conciliacion({ productos, escribe, usuario, onGuardado }) {
  const [f, setF] = useState({ id_producto: '', conteo_fisico: '', motivo: '' });
  const [aviso, setAviso] = useState(null);
  const [enviando, setEnviando] = useState(false);
  const producto = productos.find((p) => String(p.id_producto) === f.id_producto);
  const diferencia =
    producto && f.conteo_fisico !== '' ? Number(f.conteo_fisico) - producto.stock : null;

  async function guardar(e) {
    e.preventDefault();
    if (!producto || f.conteo_fisico === '' || Number(f.conteo_fisico) < 0) {
      return setAviso({
        tipo: 'error',
        texto: 'Elige el producto y captura un conteo físico válido.',
      });
    }
    if (diferencia !== 0 && !f.motivo.trim())
      return setAviso({ tipo: 'error', texto: 'Explica el motivo de la diferencia.' });
    setEnviando(true);
    try {
      const r = await registrarAjuste({
        ...f,
        stockSistema: producto.stock,
        responsable: usuario?.nombre,
      });
      setAviso(
        r.sinDiferencia
          ? { tipo: 'ok', texto: 'El conteo coincide con el sistema; no se registró ajuste.' }
          : { tipo: 'ok', texto: 'Ajuste registrado y stock alineado al conteo físico.' }
      );
      setF({ id_producto: '', conteo_fisico: '', motivo: '' });
      onGuardado();
    } catch (err) {
      setAviso({ tipo: 'error', texto: mensajeDeError(err) });
    } finally {
      setEnviando(false);
    }
  }

  if (!escribe)
    return (
      <Mensaje tipo="info">
        Tu rol puede consultar el inventario pero no registrar conciliaciones.
      </Mensaje>
    );

  return (
    <Panel title="Conciliación física · conteo contra sistema">
      <form onSubmit={guardar} className="flex flex-col gap-4 max-w-2xl">
        <RejillaForm columnas={3}>
          <Campo etiqueta="Producto">
            <Selector
              opciones={productos.map((p) => ({
                valor: String(p.id_producto),
                etiqueta: p.nombre,
              }))}
              value={f.id_producto}
              onChange={(e) => setF({ ...f, id_producto: e.target.value })}
            />
          </Campo>
          <Campo etiqueta="Stock del sistema">
            <Entrada disabled value={producto ? miles(producto.stock) : ''} />
          </Campo>
          <Campo etiqueta="Conteo físico">
            <Entrada
              type="number"
              min="0"
              value={f.conteo_fisico}
              onChange={(e) => setF({ ...f, conteo_fisico: e.target.value })}
            />
          </Campo>
        </RejillaForm>
        {diferencia !== null && (
          <div className="text-[12.5px] text-text-dim">
            Diferencia:{' '}
            <Mono bold color={diferencia < 0 ? 'down' : diferencia > 0 ? 'up' : 'text'}>
              {diferencia > 0 ? '+' : ''}
              {miles(diferencia)}
            </Mono>
          </div>
        )}
        <Campo etiqueta="Motivo">
          <Entrada
            value={f.motivo}
            onChange={(e) => setF({ ...f, motivo: e.target.value })}
            placeholder="Merma, DEVOLUCION, error de captura…"
          />
        </Campo>
        {aviso && <Mensaje tipo={aviso.tipo}>{aviso.texto}</Mensaje>}
        <Acciones>
          <Boton variante="primario" type="submit" disabled={enviando}>
            {enviando ? 'Guardando…' : 'Registrar conciliación'}
          </Boton>
        </Acciones>
      </form>
    </Panel>
  );
}

function Reportes() {
  const disc = useDatos(obtenerDiscrepancias);
  const rot = useDatos(obtenerRotacion);
  return (
    <div className="grid grid-cols-2 max-[960px]:grid-cols-1 gap-3.5">
      <Panel title="Discrepancias de conciliación">
        {disc.cargando ? (
          <Cargando />
        ) : disc.error ? (
          <Mensaje>{mensajeDeError(disc.error)}</Mensaje>
        ) : (
          <Table
            headers={['Fecha', 'Producto', 'Sistema', 'Físico', 'Diferencia', 'Motivo']}
            vacio="Sin discrepancias"
            rows={disc.datos.map((d) => [
              <Mono color="dim">{fechaCorta(d.fecha)}</Mono>,
              <Texto bold>{d.nombre}</Texto>,
              <Mono>{miles(d.stock_sistema)}</Mono>,
              <Mono>{miles(d.conteo_fisico)}</Mono>,
              <Mono bold color={d.diferencia < 0 ? 'down' : 'up'}>
                {d.diferencia > 0 ? '+' : ''}
                {miles(d.diferencia)}
              </Mono>,
              <Texto dim>{d.motivo ?? '—'}</Texto>,
            ])}
          />
        )}
      </Panel>
      <Panel title="Rotación por producto">
        {rot.cargando ? (
          <Cargando />
        ) : rot.error ? (
          <Mensaje>{mensajeDeError(rot.error)}</Mensaje>
        ) : (
          <Table
            headers={['Producto', 'Ingresado', 'Vendido', 'Stock', 'Rotación']}
            rows={rot.datos
              .filter((r) => r.volumen > 0)
              .map((r) => [
                <Texto bold>{r.nombre}</Texto>,
                <Mono color="up">{miles(r.volumen)}</Mono>,
                <Mono color="dim">{miles(r.vendido)}</Mono>,
                <Mono>{miles(r.stock)}</Mono>,
                <Mono bold color={Number(r.porcentaje_rotacion) < 30 ? 'accent' : 'text'}>
                  {porcentaje(r.porcentaje_rotacion)}
                </Mono>,
              ])}
          />
        )}
      </Panel>
    </div>
  );
}
