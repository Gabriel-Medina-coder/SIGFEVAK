import { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { useAuth } from '@/lib/auth';
import { Campo, Entrada, Boton, Mensaje } from '@/components/Formulario';

const esquema = z.object({
  correo: z.string().trim().email('Escribe un correo válido.'),
  contrasena: z.string().min(6, 'La contraseña tiene al menos 6 caracteres.'),
});

export default function Login() {
  const { session, cargando, iniciarSesion } = useAuth();
  const navigate = useNavigate();
  const { state } = useLocation();
  const [form, setForm] = useState({ correo: '', contrasena: '' });
  const [errores, setErrores] = useState({});
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);

  if (!cargando && session) return <Navigate to={state?.desde ?? '/app'} replace />;

  async function enviar(e) {
    e.preventDefault();
    setError('');
    const r = esquema.safeParse(form);
    if (!r.success) {
      setErrores(Object.fromEntries(r.error.issues.map((i) => [i.path[0], i.message])));
      return;
    }
    setErrores({});
    setEnviando(true);
    try {
      await iniciarSesion(r.data.correo, r.data.contrasena);
      navigate(state?.desde ?? '/app', { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <main className="min-h-dvh bg-bg text-text grid place-items-center p-6">
      <section className="bg-surface border border-border rounded-xl w-full max-w-sm">
        <div className="px-[22px] py-[18px] border-b border-border flex items-center gap-2.5">
          <img src="/logo-sigfevak.png" alt="SIGFEVAK" className="w-8 h-8 rounded-[7px]" />
          <div>
            <div className="font-bold text-[14.5px] tracking-[-0.02em] leading-none">SIGFEVAK</div>
            <div className="text-[10.5px] text-text-dim mt-0.5">Iniciar sesión</div>
          </div>
        </div>
        <form onSubmit={enviar} className="px-[22px] py-5 flex flex-col gap-4" noValidate>
          <Campo etiqueta="Correo" error={errores.correo}>
            <Entrada
              type="email"
              autoComplete="username"
              placeholder="usuario@sigfevak.mx"
              value={form.correo}
              onChange={(e) => setForm({ ...form, correo: e.target.value })}
            />
          </Campo>
          <Campo etiqueta="Contraseña" error={errores.contrasena}>
            <Entrada
              type="password"
              autoComplete="current-password"
              placeholder="••••••••"
              value={form.contrasena}
              onChange={(e) => setForm({ ...form, contrasena: e.target.value })}
            />
          </Campo>
          {error && <Mensaje>{error}</Mensaje>}
          <Boton variante="primario" type="submit" disabled={enviando} className="py-2.5">
            {enviando ? 'Entrando…' : 'Entrar'}
          </Boton>
          <p className="text-[11px] text-muted text-center m-0">
            El rol de cada cuenta lo asigna la coordinación.{' '}
            <Link to="/" className="text-text-dim hover:text-text">
              Volver al inicio
            </Link>
          </p>
        </form>
      </section>
    </main>
  );
}
