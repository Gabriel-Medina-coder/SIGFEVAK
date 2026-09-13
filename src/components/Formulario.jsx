// Formularios base (docs/GUIA_ESTILO.md sección 4): campo con etiqueta arriba, entradas con borde y foco ámbar,
// botones primario y secundario, mensajes de error y estados de carga.

const ENTRADA =
  'w-full bg-surface border border-border rounded-[7px] px-3 py-2 text-[13px] text-text placeholder:text-muted outline-none focus:border-accent disabled:opacity-60';

export function Campo({ etiqueta, error, children, ayuda }) {
  return (
    <label className="block">
      <span className="block text-[10.5px] uppercase tracking-[0.04em] text-text-dim mb-1.5">
        {etiqueta}
      </span>
      {children}
      {error && <span className="block text-[11px] text-down mt-1">{error}</span>}
      {!error && ayuda && <span className="block text-[11px] text-muted mt-1">{ayuda}</span>}
    </label>
  );
}

export function Entrada({ className = '', ...props }) {
  return <input className={`${ENTRADA} ${className}`} {...props} />;
}

export function AreaTexto({ className = '', ...props }) {
  return <textarea className={`${ENTRADA} min-h-[80px] ${className}`} {...props} />;
}

export function Selector({ opciones, placeholder = 'Selecciona…', className = '', ...props }) {
  return (
    <select className={`${ENTRADA} ${className}`} {...props}>
      <option value="">{placeholder}</option>
      {opciones.map((o) => (
        <option key={o.valor} value={o.valor}>
          {o.etiqueta}
        </option>
      ))}
    </select>
  );
}

export function Boton({ variante = 'secundario', className = '', children, ...props }) {
  const estilos =
    variante === 'primario'
      ? 'bg-accent text-black font-semibold hover:brightness-110'
      : variante === 'peligro'
        ? 'bg-surface border border-down text-down hover:bg-surface-2'
        : 'bg-surface border border-border text-text-dim hover:text-text hover:bg-surface-2';
  return (
    <button
      className={`rounded-[7px] px-3.5 py-1.5 text-[12px] cursor-pointer transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${estilos} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}

export function Mensaje({ tipo = 'error', children }) {
  const estilos =
    tipo === 'error'
      ? 'border-down text-down bg-[rgba(248,113,113,0.08)]'
      : tipo === 'ok'
        ? 'border-up text-up bg-[rgba(62,207,142,0.08)]'
        : 'border-border text-text-dim bg-surface-2';
  return <div className={`border rounded-[7px] px-3 py-2 text-[12px] ${estilos}`}>{children}</div>;
}

export function Cargando({ texto = 'Cargando…' }) {
  return <div className="text-[12.5px] text-text-dim py-6 text-center">{texto}</div>;
}

// Convierte los errores de Postgres (RN-xx-yy: mensaje) y de red en texto legible para el usuario.
export function mensajeDeError(error) {
  const texto = error?.message ?? String(error ?? '');
  const rn = texto.match(/RN-A\d-\d{2}:\s*(.+)/);
  if (rn) return rn[1].charAt(0).toUpperCase() + rn[1].slice(1);
  if (/ck_tipo_cambio_moneda/.test(texto))
    return 'Indica el tipo de cambio: en pesos es 1 y en otra moneda distinto de 1.';
  if (/ck_rfc_formato/.test(texto))
    return 'El RFC no tiene el formato correcto (12 o 13 caracteres).';
  if (/clientes_rfc_key|rfc.*already exists/i.test(texto))
    return 'Ya existe un comercializador con ese RFC.';
  if (/ck_entrada_cantidad|ck_detalle_cantidad/.test(texto))
    return 'La cantidad debe ser mayor a cero.';
  if (/row-level security/i.test(texto)) return 'Tu sesión no tiene permiso para esta operación.';
  if (/duplicate key/i.test(texto)) return 'Ya existe un registro con esos datos.';
  if (/violates check constraint/i.test(texto)) return 'Uno de los valores no es válido.';
  if (/violates foreign key/i.test(texto))
    return 'El registro está ligado a otros datos y no se puede modificar así.';
  if (/Failed to fetch|NetworkError/i.test(texto)) return 'Sin conexión con el servidor.';
  return texto || 'Ocurrió un error inesperado.';
}
