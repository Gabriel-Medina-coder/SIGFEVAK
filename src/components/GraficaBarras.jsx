// Gráfica de barras con divs, como en la referencia: la última en accent y las demás en surface-2 con borde.
// data: [{ label, value, titulo? }]
export default function GraficaBarras({ data, alto = 100, unidad = '' }) {
  const max = Math.max(...data.map((d) => Number(d.value) || 0), 1);
  return (
    <div className="flex items-end gap-2.5" style={{ height: alto }}>
      {data.map((d, i) => {
        const pct = ((Number(d.value) || 0) / max) * 100;
        const ultima = i === data.length - 1;
        return (
          <div key={d.label} className="flex-1 flex flex-col items-center gap-1.5 h-full">
            <div className="flex-1 w-full flex items-end">
              <div
                title={d.titulo ?? `${d.label}: ${d.value}${unidad}`}
                className={`w-full rounded-t transition-[height] duration-300 ${ultima ? 'bg-accent' : 'bg-surface-2 border border-border'}`}
                style={{ height: `${pct}%` }}
              />
            </div>
            <span className={`font-mono text-[10px] ${ultima ? 'text-text' : 'text-muted'}`}>
              {d.label}
            </span>
          </div>
        );
      })}
    </div>
  );
}
