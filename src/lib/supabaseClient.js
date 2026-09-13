import { createClient } from '@supabase/supabase-js';

// Único cliente de Supabase de la aplicación. Nadie crea otro (docs/FLUJO_APP.md sección 3).
// Las llaves vienen de .env (ver .env.example); la llave anon es pública y RLS protege los datos.
const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  throw new Error('Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. Copia .env.example a .env.');
}

export const supabase = createClient(url, anonKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false },
});
