import { useEffect, useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { useAuth } from '@/lib/auth';
import { Campo, Entrada, Mensaje } from '@/components/Formulario';
import { sinMovimiento, usePuntero, Particulas } from './efectosNeon';
import './landing.css';

const esquema = z.object({
  correo: z.string().trim().email('Escribe un correo válido.'),
  contrasena: z.string().min(6, 'La contraseña tiene al menos 6 caracteres.'),
});

const AREAS = ['entradas', 'facturas', 'inventario', 'nómina', 'impuestos', 'marketing'];

// Palabra que rota bajo el logo: una por área de la operación
function PalabraRotativa() {
  const [i, setI] = useState(0);
  useEffect(() => {
    if (sinMovimiento()) return;
    const id = setInterval(() => setI((n) => (n + 1) % AREAS.length), 2200);
    return () => clearInterval(id);
  }, []);
  return (
    <span key={AREAS[i]} className="lp-rota text-accent">
      {AREAS[i]}
    </span>
  );
}

export default function Login() {
  const { session, cargando, iniciarSesion } = useAuth();
  const navigate = useNavigate();
  const { state } = useLocation();
  const [form, setForm] = useState({ correo: '', contrasena: '' });
  const [errores, setErrores] = useState({});
  const [error, setError] = useState('');
  const [intento, setIntento] = useState(0);
  const [enviando, setEnviando] = useState(false);
  const [verContrasena, setVerContrasena] = useState(false);
  usePuntero();

  if (!cargando && session) return <Navigate to={state?.desde ?? '/app'} replace />;

  async function enviar(e) {
    e.preventDefault();
    setError('');
    const r = esquema.safeParse(form);
    if (!r.success) {
      setErrores(Object.fromEntries(r.error.issues.map((i) => [i.path[0], i.message])));
      setIntento((n) => n + 1);
      return;
    }
    setErrores({});
    setEnviando(true);
    try {
      await iniciarSesion(r.data.correo, r.data.contrasena);
      navigate(state?.desde ?? '/app', { replace: true });
    } catch (err) {
      setError(err.message);
      setIntento((n) => n + 1);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="lp">
      <Particulas />

      <main className="lp-contenido min-h-dvh grid grid-cols-[minmax(0,1.15fr)_minmax(0,1fr)] max-[900px]:grid-cols-1">
        {/* Bloque derecho: acceso */}
        <section className="order-2 flex flex-col justify-center px-10 py-8 max-[520px]:px-5">
          <div className="w-full max-w-[400px] mx-auto py-10">
            <div className="lp-ceja lp-palabra" style={{ animationDelay: '0.15s' }}>
              <b>[</b> Acceso <b>]</b>
            </div>
            <h1
              className="lp-palabra text-[38px] leading-[1.05] font-bold tracking-[-0.03em] mt-4 m-0"
              style={{ animationDelay: '0.25s' }}
            >
              Bienvenido de vuelta.
            </h1>
            <p
              className="lp-palabra text-[13.5px] text-text-dim mt-3 leading-relaxed"
              style={{ animationDelay: '0.35s' }}
            >
              Entra con tu cuenta para continuar con la operación.
            </p>

            <form
              key={intento}
              onSubmit={enviar}
              noValidate
              className={`lp-login-tarjeta lp-palabra mt-8 flex flex-col gap-4 p-6 ${intento ? 'lp-sacudir' : ''}`}
              style={{ animationDelay: intento ? '0s' : '0.45s' }}
            >
              <Campo etiqueta="Correo" error={errores.correo}>
                <Entrada
                  type="email"
                  autoComplete="username"
                  placeholder="usuario@sigfevak.mx"
                  value={form.correo}
                  onChange={(e) => setForm({ ...form, correo: e.target.value })}
                  className="!py-2.5"
                />
              </Campo>
              <Campo etiqueta="Contraseña" error={errores.contrasena}>
                <div className="relative">
                  <Entrada
                    type={verContrasena ? 'text' : 'password'}
                    autoComplete="current-password"
                    placeholder="••••••••"
                    value={form.contrasena}
                    onChange={(e) => setForm({ ...form, contrasena: e.target.value })}
                    className="!py-2.5 pr-20"
                  />
                  <button
                    type="button"
                    onClick={() => setVerContrasena((v) => !v)}
                    className="absolute right-2 top-1/2 -translate-y-1/2 text-[11px] text-text-dim hover:text-accent px-2 py-1 cursor-pointer"
                  >
                    {verContrasena ? 'Ocultar' : 'Mostrar'}
                  </button>
                </div>
              </Campo>
              {error && <Mensaje>{error}</Mensaje>}
              <button
                type="submit"
                disabled={enviando}
                className="lp-boton lp-boton--acento justify-center w-full mt-1 cursor-pointer disabled:opacity-60 disabled:cursor-wait"
              >
                {enviando ? (
                  <>
                    <span className="lp-giro" /> Entrando…
                  </>
                ) : (
                  <>
                    Entrar <span className="lp-flecha">→</span>
                  </>
                )}
              </button>
            </form>

            <p
              className="lp-palabra text-[11.5px] text-muted mt-5 text-center"
              style={{ animationDelay: '0.6s' }}
            >
              ¿No tienes acceso? Solicítalo al administrador del sistema.
            </p>
          </div>

          <div
            className="lp-palabra flex justify-center text-[11px] text-muted"
            style={{ animationDelay: '0.7s' }}
          >
            <Link to="/" className="hover:text-text transition-colors">
              ← Volver al inicio
            </Link>
          </div>
        </section>

        {/* Bloque izquierdo: logo neón encendido */}
        <section className="lp-login-escena order-1 relative flex flex-col items-center justify-center px-8 py-12 max-[900px]:hidden">
          <div className="lp-palabra" style={{ animationDelay: '0.3s' }}>
            <div className="lp-logo-fijo">
              <div className="lp-halo" />
              <img src="/logo-neon.webp" alt="SIGFEVAK" />
            </div>
          </div>
          <div className="lp-palabra text-center mt-6" style={{ animationDelay: '0.6s' }}>
            <div className="lp-nombre-neon">SIGFEVAK</div>
            <div className="text-[22px] font-bold tracking-[-0.02em] mt-4">
              Toda tu operación en un lugar
            </div>
            <div className="text-[15px] text-text-dim mt-2 h-6">
              Hoy toca revisar <PalabraRotativa />
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}
