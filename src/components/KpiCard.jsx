// Tarjeta de indicador (docs/GUIA_ESTILO.md sección 3). `value` en mono 22px; `delta` verde si `up`, rojo si no.
export default function KpiCard({ label, value, delta, up = true, sub }) {
  return (
    <div className="bg-surface border border-border hover:border-[#3a3a3a] rounded-xl px-5 py-[18px] transition-colors">
      <div className="text-[10.5px] text-text-dim mb-2 tracking-[0.04em] uppercase">{label}</div>
      <div className="font-mono text-[22px] font-semibold tracking-[-0.03em] leading-none">
        {value}
      </div>
      {(delta || sub) && (
        <div className="mt-2 flex items-center gap-1.5">
          {delta && (
            <span className={`font-mono text-[11px] font-medium ${up ? 'text-up' : 'text-down'}`}>
              {delta}
            </span>
          )}
          {sub && <span className="text-[10.5px] text-muted">{sub}</span>}
        </div>
      )}
    </div>
  );
}
