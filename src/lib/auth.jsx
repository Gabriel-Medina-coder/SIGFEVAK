import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from './supabaseClient';

// Sesión de Supabase Auth más la fila de `usuarios` (nombre, rol, área) del usuario conectado.
const AuthContext = createContext(null);

async function cargarUsuario(session) {
  if (!session?.user) return null;
  const { data, error } = await supabase
    .from('usuarios')
    .select('id_usuario, nombre, correo, rol, area, activo')
    .eq('id_usuario', session.user.id)
    .maybeSingle();
  if (error) throw error;
  return (
    data ?? {
      id_usuario: session.user.id,
      nombre: session.user.email,
      correo: session.user.email,
      rol: 'CAPTURISTA',
      area: null,
      activo: true,
    }
  );
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [usuario, setUsuario] = useState(null);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    let vivo = true;
    supabase.auth
      .getSession()
      .then(async ({ data }) => {
        if (!vivo) return;
        setSession(data.session);
        setUsuario(await cargarUsuario(data.session).catch(() => null));
      })
      .finally(() => vivo && setCargando(false));

    const { data: sub } = supabase.auth.onAuthStateChange(async (_evento, nueva) => {
      if (!vivo) return;
      setSession(nueva);
      setUsuario(await cargarUsuario(nueva).catch(() => null));
    });
    return () => {
      vivo = false;
      sub.subscription.unsubscribe();
    };
  }, []);

  async function iniciarSesion(correo, contrasena) {
    const { error } = await supabase.auth.signInWithPassword({
      email: correo,
      password: contrasena,
    });
    if (error) {
      const msg = /invalid login credentials/i.test(error.message)
        ? 'Correo o contraseña incorrectos.'
        : 'No se pudo iniciar sesión. Intenta de nuevo.';
      throw new Error(msg);
    }
  }

  async function cerrarSesion() {
    await supabase.auth.signOut();
  }

  return (
    <AuthContext.Provider value={{ session, usuario, cargando, iniciarSesion, cerrarSesion }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
