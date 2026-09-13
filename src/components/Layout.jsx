import { createContext, useContext, useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { moduloPorRuta } from '@/lib/permisos';
import Sidebar from './Sidebar';
import Topbar from './Topbar';

// Cada pantalla registra sus botones de la topbar con useTopbar({ acciones, subtitulo }).
const TopbarContext = createContext({ set: () => {} });

export function useTopbar() {
  return useContext(TopbarContext);
}

// Estructura de pantalla (docs/GUIA_ESTILO.md sección 2): sidebar 240px + main con topbar y contenido.
export default function Layout() {
  const [menuAbierto, setMenuAbierto] = useState(false);
  const [extra, setExtra] = useState({});
  const { pathname } = useLocation();
  const modulo = moduloPorRuta(pathname);

  return (
    <TopbarContext.Provider value={{ set: setExtra }}>
      <div className="grid grid-cols-[240px_1fr] max-[960px]:block min-h-dvh bg-bg text-text">
        <Sidebar abierto={menuAbierto} onCerrar={() => setMenuAbierto(false)} />
        <main className="min-w-0 overflow-auto">
          <Topbar
            titulo={modulo.etiqueta}
            subtitulo={extra.subtitulo ?? modulo.subtitulo}
            acciones={extra.acciones}
            onAbrirMenu={() => setMenuAbierto(true)}
          />
          <div className="p-7 flex flex-col gap-6">
            <Outlet />
          </div>
        </main>
      </div>
    </TopbarContext.Provider>
  );
}
