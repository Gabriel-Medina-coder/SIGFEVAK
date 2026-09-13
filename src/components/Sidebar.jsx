import { NavLink } from 'react-router-dom';
import { MODULOS, ETIQUETA_ROL } from '@/lib/permisos';
import { useAuth } from '@/lib/auth';
import { ICONO_MODULO, LogoutIcon } from './Iconos';

function iniciales(nombre = '') {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('');
}

// Menú lateral con los siete módulos en el orden de la referencia. Una sola instancia en Layout.
export default function Sidebar({ abierto, onCerrar }) {
  const { usuario, cerrarSesion } = useAuth();
  return (
    <>
      <aside
        className={`bg-surface border-r border-border flex flex-col sticky top-0 h-dvh overflow-y-auto w-[240px] shrink-0
          max-[960px]:fixed max-[960px]:z-50 max-[960px]:inset-y-0 max-[960px]:left-0 max-[960px]:transition-transform max-[960px]:duration-300
          ${abierto ? 'max-[960px]:translate-x-0' : 'max-[960px]:-translate-x-full'}`}
      >
        <div className="px-5 pt-6 pb-5 border-b border-border">
          <div className="flex items-center gap-2.5">
            <img
              src="/logo-sigfevak.png"
              alt="SIGFEVAK"
              className="w-10 h-10 object-cover shrink-0"
            />
            <div>
              <div className="font-bold text-[14.5px] tracking-[-0.02em] leading-none">
                SIGFEVAK
              </div>
              <div className="text-[10.5px] text-text-dim mt-0.5">Comercializadora Nacional</div>
            </div>
          </div>
        </div>

        <nav className="p-2.5 flex-1">
          <div className="text-[9.5px] text-muted tracking-[0.08em] uppercase px-2.5 pt-2 pb-1.5">
            Módulos del sistema
          </div>
          {MODULOS.map((m) => {
            const Icono = ICONO_MODULO[m.id];
            return (
              <NavLink
                key={m.id}
                to={m.ruta}
                end={m.id === 'resumen'}
                onClick={onCerrar}
                className={({ isActive }) =>
                  `flex items-center gap-[9px] w-full px-2.5 py-[9px] rounded-[7px] text-[13px] mb-px transition-colors ${
                    isActive
                      ? 'bg-accent-dim text-accent font-medium'
                      : 'text-text-dim hover:bg-surface-2 hover:text-text'
                  }`
                }
              >
                <Icono size={14} />
                {m.etiqueta}
              </NavLink>
            );
          })}
        </nav>

        <div className="px-4 py-3.5 border-t border-border flex items-center gap-2.5">
          <div className="w-[30px] h-[30px] rounded-full bg-border flex items-center justify-center text-[11px] font-semibold text-text-dim shrink-0">
            {iniciales(usuario?.nombre) || 'U'}
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-[12.5px] font-medium truncate">{usuario?.nombre ?? 'Usuario'}</div>
            <div className="text-[10.5px] text-text-dim truncate">
              {ETIQUETA_ROL[usuario?.rol] ?? 'Sin rol'} · MX
            </div>
          </div>
          <button
            onClick={cerrarSesion}
            title="Cerrar sesión"
            className="text-text-dim hover:text-text cursor-pointer p-1"
            aria-label="Cerrar sesión"
          >
            <LogoutIcon />
          </button>
        </div>
      </aside>
      {abierto && (
        <div onClick={onCerrar} className="fixed inset-0 bg-black/60 z-40 min-[961px]:hidden" />
      )}
    </>
  );
}
