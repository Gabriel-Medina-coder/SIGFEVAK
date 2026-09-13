// Iconos de la referencia (docs/referencia-ui/App.jsx): SVG 16x16 con stroke currentColor.
const base = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.3 };

export function GridIcon({ size = 14 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" {...base}>
      <rect x="1" y="1" width="6" height="6" rx="1.5" />
      <rect x="9" y="1" width="6" height="6" rx="1.5" />
      <rect x="1" y="9" width="6" height="6" rx="1.5" />
      <rect x="9" y="9" width="6" height="6" rx="1.5" />
    </svg>
  );
}
export function BoxIcon({ size = 14 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" {...base} strokeLinejoin="round">
      <path d="M2 5l6-3 6 3v6l-6 3-6-3V5z" />
      <path d="M8 2v12M2 5l6 3 6-3" />
    </svg>
  );
}
export function ReceiptIcon({ size = 14 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeLinejoin="round"
      strokeLinecap="round"
    >
      <path d="M3 1h10v14l-2-1.5-2 1.5-2-1.5L5 15 3 13.5V1z" />
      <line x1="5" y1="5" x2="11" y2="5" />
      <line x1="5" y1="8" x2="11" y2="8" />
      <line x1="5" y1="11" x2="8" y2="11" />
    </svg>
  );
}
export function DatabaseIcon({ size = 14 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" {...base}>
      <ellipse cx="8" cy="4" rx="5" ry="2" />
      <path d="M3 4v4c0 1.1 2.2 2 5 2s5-.9 5-2V4" />
      <path d="M3 8v4c0 1.1 2.2 2 5 2s5-.9 5-2V8" />
    </svg>
  );
}
export function UsersIcon({ size = 14 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" {...base} strokeLinecap="round">
      <circle cx="6" cy="5" r="2.5" />
      <path d="M1 14c0-2.8 2.2-5 5-5s5 2.2 5 5" />
      <circle cx="12" cy="5" r="2" />
      <path d="M15 14c0-2.2-1.3-4-3-4.5" />
    </svg>
  );
}
export function ShieldIcon({ size = 14 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeLinejoin="round"
      strokeLinecap="round"
    >
      <path d="M8 1l5 2v4c0 3-2 5.5-5 7C6 12.5 3 10 3 7V3l5-2z" />
      <polyline points="5.5,8 7,9.5 10.5,6" />
    </svg>
  );
}
export function MegaphoneIcon({ size = 14 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeLinejoin="round"
      strokeLinecap="round"
    >
      <path d="M2 6h2v4H2z" />
      <path d="M4 6l8-3v10L4 10V6z" />
      <path d="M4 10l1.5 4h2L6 10" />
    </svg>
  );
}
export function MenuIcon({ size = 16 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeWidth="1.4"
      strokeLinecap="round"
    >
      <line x1="2" y1="4" x2="14" y2="4" />
      <line x1="2" y1="8" x2="14" y2="8" />
      <line x1="2" y1="12" x2="14" y2="12" />
    </svg>
  );
}
export function CloseIcon({ size = 14 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeWidth="1.4"
      strokeLinecap="round"
    >
      <line x1="3" y1="3" x2="13" y2="13" />
      <line x1="13" y1="3" x2="3" y2="13" />
    </svg>
  );
}
export function LogoutIcon({ size = 14 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      {...base}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M6 2H3v12h3" />
      <path d="M10 5l3 3-3 3M13 8H6" />
    </svg>
  );
}

export const ICONO_MODULO = {
  resumen: GridIcon,
  entradas: BoxIcon,
  contable: ReceiptIcon,
  inventario: DatabaseIcon,
  nomina: UsersIcon,
  regulacion: ShieldIcon,
  marketing: MegaphoneIcon,
};
