// Pestañas para dividir una pantalla de área en secciones (catálogo, reportes, etc.).
// opciones: [{ id, etiqueta }]
export default function Pestanas({ opciones, activa, onCambiar }) {
  return (
    <div className="flex gap-1 border-b border-border overflow-x-auto -mt-2">
      {opciones.map((o) => (
        <button
          key={o.id}
          onClick={() => onCambiar(o.id)}
          className={`px-3 py-2 text-[12.5px] whitespace-nowrap cursor-pointer border-b-2 -mb-px transition-colors ${
            activa === o.id
              ? 'border-accent text-accent font-medium'
              : 'border-transparent text-text-dim hover:text-text'
          }`}
        >
          {o.etiqueta}
        </button>
      ))}
    </div>
  );
}
