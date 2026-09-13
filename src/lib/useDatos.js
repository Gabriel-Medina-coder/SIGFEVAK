import { useCallback, useEffect, useState } from 'react';

// Carga datos de un servicio y expone { datos, error, cargando, recargar }.
export function useDatos(cargar, deps = []) {
  const [estado, setEstado] = useState({ datos: null, error: null, cargando: true });

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const ejecutar = useCallback(cargar, deps);

  const recargar = useCallback(async () => {
    setEstado((e) => ({ ...e, cargando: true, error: null }));
    try {
      const datos = await ejecutar();
      setEstado({ datos, error: null, cargando: false });
    } catch (error) {
      setEstado({ datos: null, error, cargando: false });
    }
  }, [ejecutar]);

  useEffect(() => {
    recargar();
  }, [recargar]);

  return { ...estado, recargar };
}
