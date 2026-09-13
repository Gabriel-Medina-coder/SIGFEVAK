import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/lib/auth';

// Guardia de sesión: sin sesión manda al login y recuerda a dónde iba el usuario.
export default function RequiereSesion() {
  const { session, cargando } = useAuth();
  const location = useLocation();
  if (cargando) {
    return (
      <div className="min-h-dvh bg-bg text-text-dim grid place-items-center text-[12.5px]">
        Cargando sesión…
      </div>
    );
  }
  if (!session) return <Navigate to="/login" replace state={{ desde: location.pathname }} />;
  return <Outlet />;
}
