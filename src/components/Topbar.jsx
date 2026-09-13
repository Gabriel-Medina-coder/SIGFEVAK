import { MenuIcon } from './Iconos';

// Barra superior pegajosa: título y subtítulo del módulo más los botones de acción que cada pantalla decide.
export default function Topbar({ titulo, subtitulo, acciones, onAbrirMenu }) {
  return (
    <header className="px-7 py-[18px] border-b border-border flex items-center justify-between gap-3 sticky top-0 bg-bg z-10">
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={onAbrirMenu}
          className="hidden max-[960px]:block text-text-dim cursor-pointer p-1"
          aria-label="Abrir menú"
        >
          <MenuIcon size={18} />
        </button>
        <div className="min-w-0">
          <h1 className="m-0 text-[15px] font-semibold tracking-[-0.02em] truncate">{titulo}</h1>
          <p className="m-0 text-[11px] text-text-dim truncate">{subtitulo}</p>
        </div>
      </div>
      {acciones && <div className="flex gap-2 shrink-0">{acciones}</div>}
    </header>
  );
}
