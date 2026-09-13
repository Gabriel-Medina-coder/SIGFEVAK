// Texto monoespaciado 12px para folios, montos, cantidades y fechas cortas.
// `color`: text | up | down | accent | dim
const COLORES = {
  text: 'text-text',
  up: 'text-up',
  down: 'text-down',
  accent: 'text-accent',
  dim: 'text-text-dim',
  muted: 'text-muted',
};

export default function Mono({ children, color = 'text', bold = false, className = '' }) {
  return (
    <span
      className={`font-mono text-[12px] ${COLORES[color] ?? COLORES.text} ${bold ? 'font-semibold' : ''} ${className}`}
    >
      {children}
    </span>
  );
}
