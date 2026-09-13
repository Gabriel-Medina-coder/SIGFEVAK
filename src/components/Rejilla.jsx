// Rejillas de la guía de estilo: KPI en 3 o 4 columnas y formularios en 1 a 3 columnas.
const KPI = {
  3: 'grid grid-cols-3 max-[960px]:grid-cols-1 gap-3.5',
  4: 'grid grid-cols-4 max-[960px]:grid-cols-2 max-[600px]:grid-cols-1 gap-3.5',
};

export function FilaKpi({ columnas = 4, children }) {
  return <div className={KPI[columnas] ?? KPI[4]}>{children}</div>;
}

const FORM = {
  1: 'grid grid-cols-1 gap-4',
  2: 'grid grid-cols-2 max-[600px]:grid-cols-1 gap-4',
  3: 'grid grid-cols-3 max-[960px]:grid-cols-2 max-[600px]:grid-cols-1 gap-4',
};

export function RejillaForm({ columnas = 2, children }) {
  return <div className={FORM[columnas] ?? FORM[2]}>{children}</div>;
}

export function Acciones({ children }) {
  return <div className="flex justify-end gap-2 pt-2">{children}</div>;
}

export function Texto({ children, dim = false, bold = false }) {
  return (
    <span
      className={`text-[13px] ${bold ? 'font-medium' : ''} ${dim ? 'text-[12px] text-text-dim' : ''}`}
    >
      {children}
    </span>
  );
}
