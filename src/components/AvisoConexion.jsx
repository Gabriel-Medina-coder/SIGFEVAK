import { useEffect, useState } from 'react';

// Barra fija que aparece cuando el navegador pierde la conexión, para que se entienda por qué la app no carga datos.
export default function AvisoConexion() {
  const [enLinea, setEnLinea] = useState(() =>
    typeof navigator === 'undefined' ? true : navigator.onLine
  );
  useEffect(() => {
    const subir = () => setEnLinea(true);
    const bajar = () => setEnLinea(false);
    window.addEventListener('online', subir);
    window.addEventListener('offline', bajar);
    return () => {
      window.removeEventListener('online', subir);
      window.removeEventListener('offline', bajar);
    };
  }, []);

  if (enLinea) return null;
  return (
    <div
      role="status"
      className="sticky top-0 z-50 bg-down text-black text-[12.5px] font-medium text-center py-1.5 px-4"
    >
      Sin conexión. Revisa tu internet; los datos se actualizarán al reconectar.
    </div>
  );
}
