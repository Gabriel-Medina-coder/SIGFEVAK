import { useEffect } from 'react';
import { CloseIcon } from './Iconos';

// Ventana modal con el mismo fondo y borde que un Panel. Cierra con Escape o clic fuera.
export default function Modal({ abierto, titulo, onCerrar, children, ancho = 'max-w-lg' }) {
  useEffect(() => {
    if (!abierto) return undefined;
    const escape = (e) => e.key === 'Escape' && onCerrar?.();
    window.addEventListener('keydown', escape);
    return () => window.removeEventListener('keydown', escape);
  }, [abierto, onCerrar]);

  if (!abierto) return null;
  return (
    <div
      className="fixed inset-0 z-[60] bg-black/60 flex items-start justify-center p-4 overflow-y-auto"
      onClick={onCerrar}
    >
      <div
        className={`bg-surface border border-border rounded-xl w-full ${ancho} mt-10`}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <div className="px-[22px] py-[18px] border-b border-border flex items-center justify-between">
          <span className="text-[13px] font-medium">{titulo}</span>
          <button
            onClick={onCerrar}
            className="text-text-dim hover:text-text cursor-pointer"
            aria-label="Cerrar"
          >
            <CloseIcon />
          </button>
        </div>
        <div className="px-[22px] py-5">{children}</div>
      </div>
    </div>
  );
}
