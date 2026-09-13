import { Link, Navigate } from 'react-router-dom';
import { useAuth } from '@/lib/auth';
import { MODULOS } from '@/lib/permisos';
import { ICONO_MODULO } from '@/components/Iconos';

const PILARES = [
  {
    titulo: 'Una sola base',
    texto:
      'Seis áreas sobre las mismas tablas. Las reglas viven en la base de datos, no en cada pantalla.',
  },
  {
    titulo: 'Trazable de punta a punta',
    texto:
      'Una entrada de mercancía llega hasta la comisión del agente y la obligación fiscal sin recapturas.',
  },
  {
    titulo: 'Separación de funciones',
    texto: 'Quien calcula no autoriza. Quien captura no aprueba. Cada cambio queda en bitácora.',
  },
];

// Página pública de entrada. Si ya hay sesión, pasa directo a la app.
export default function Landing() {
  const { session, cargando } = useAuth();
  if (!cargando && session) return <Navigate to="/app" replace />;

  return (
    <div className="min-h-dvh bg-bg text-text">
      <header className="px-7 py-[18px] border-b border-border flex items-center justify-between max-w-6xl mx-auto">
        <div className="flex items-center gap-2.5">
          <img src="/logo-sigfevak.png" alt="SIGFEVAK" className="w-10 h-10 object-cover" />
          <div>
            <div className="font-bold text-[14.5px] tracking-[-0.02em] leading-none">SIGFEVAK</div>
            <div className="text-[10.5px] text-text-dim mt-0.5">Comercializadora Nacional</div>
          </div>
        </div>
        <Link
          to="/login"
          className="bg-accent text-black font-semibold text-[12px] rounded-[7px] px-3.5 py-1.5 hover:brightness-110"
        >
          Entrar
        </Link>
      </header>

      <main className="max-w-6xl mx-auto px-7 py-16 flex flex-col gap-16">
        <section className="max-w-2xl">
          <div className="font-mono text-[10.5px] text-accent tracking-[0.08em] uppercase mb-4">
            Sistema de gestión
          </div>
          <h1 className="text-[34px] leading-[1.1] font-semibold tracking-[-0.02em] m-0">
            Entradas, ventas, inventario, nómina, obligaciones y marketing en una sola aplicación.
          </h1>
          <p className="text-[14px] text-text-dim mt-5 leading-relaxed">
            SIGFEVAK administra la operación de una comercializadora mexicana de productos
            electrónicos y manufactura nacional: desde que llega la mercancía hasta que se paga el
            impuesto, con cada área en su módulo y las reglas de negocio en la base de datos.
          </p>
          <div className="mt-8 flex gap-3">
            <Link
              to="/login"
              className="bg-accent text-black font-semibold text-[12.5px] rounded-[7px] px-5 py-2.5 hover:brightness-110"
            >
              Iniciar sesión
            </Link>
            <a
              href="https://github.com/Gabriel-Medina-coder/SIGFEVAK"
              target="_blank"
              rel="noreferrer"
              className="bg-surface border border-border text-text-dim text-[12.5px] rounded-[7px] px-5 py-2.5 hover:text-text hover:bg-surface-2"
            >
              Ver el proyecto
            </a>
          </div>
        </section>

        <section>
          <div className="text-[10.5px] text-muted tracking-[0.06em] uppercase mb-4">
            Siete módulos
          </div>
          <div className="grid grid-cols-4 max-[960px]:grid-cols-2 max-[600px]:grid-cols-1 gap-3.5">
            {MODULOS.map((m) => {
              const Icono = ICONO_MODULO[m.id];
              return (
                <div
                  key={m.id}
                  className="bg-surface border border-border rounded-xl px-5 py-[18px]"
                >
                  <div className="text-accent mb-3">
                    <Icono size={18} />
                  </div>
                  <div className="text-[13px] font-medium">{m.etiqueta}</div>
                  <div className="text-[11.5px] text-text-dim mt-1">{m.subtitulo}</div>
                </div>
              );
            })}
          </div>
        </section>

        <section className="grid grid-cols-3 max-[960px]:grid-cols-1 gap-3.5">
          {PILARES.map((p) => (
            <div key={p.titulo} className="border-t border-border pt-4">
              <div className="text-[13px] font-medium">{p.titulo}</div>
              <div className="text-[12.5px] text-text-dim mt-1.5 leading-relaxed">{p.texto}</div>
            </div>
          ))}
        </section>
      </main>

      <footer className="max-w-6xl mx-auto px-7 py-8 border-t border-border text-[11px] text-muted">
        SIGFEVAK · Proyecto escolar · Septiembre 2026
      </footer>
    </div>
  );
}
