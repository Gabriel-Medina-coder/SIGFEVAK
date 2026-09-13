// Ayudantes para los servicios: convierten la respuesta de supabase-js en datos o lanzan el error.
export function datos({ data, error }) {
  if (error) throw error;
  return data ?? [];
}

export function uno({ data, error }) {
  if (error) throw error;
  return data ?? null;
}

// Quita campos vacíos ('' o undefined) para que la base aplique sus defaults.
export function limpiar(obj) {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== '' && v !== undefined));
}
