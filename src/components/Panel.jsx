// Contenedor con cabecera y borde. Envuelve tablas, gráficas, listas y formularios.
export default function Panel({ title, acciones, children }) {
  return (
    <div className="bg-surface border border-border rounded-xl overflow-hidden">
      {title && (
        <div className="px-[22px] py-[18px] border-b border-border text-[13px] font-medium flex items-center justify-between gap-3">
          <span>{title}</span>
          {acciones && <div className="flex items-center gap-2">{acciones}</div>}
        </div>
      )}
      <div className="px-[22px] py-5">{children}</div>
    </div>
  );
}
