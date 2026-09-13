// Píldora de categoría. `color`: accent | muted | up | down (semántica en docs/GUIA_ESTILO.md sección 5).
const COLORES = {
  accent: 'bg-accent-dim text-accent',
  muted: 'bg-surface-2 text-text-dim',
  up: 'bg-[rgba(62,207,142,0.1)] text-up',
  down: 'bg-[rgba(248,113,113,0.1)] text-down',
};

export default function Tag({ children, color = 'muted' }) {
  return (
    <span
      className={`font-mono text-[10.5px] px-2 py-[3px] rounded-[20px] whitespace-nowrap ${COLORES[color] ?? COLORES.muted}`}
    >
      {children}
    </span>
  );
}
