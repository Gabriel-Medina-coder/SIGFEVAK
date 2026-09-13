import { Link } from 'react-router-dom';

export default function NoEncontrado() {
  return (
    <main className="min-h-dvh bg-bg text-text grid place-items-center p-6">
      <section className="bg-surface border border-border rounded-xl px-6 py-5 max-w-sm w-full text-center">
        <div className="font-mono text-[22px] font-semibold">404</div>
        <p className="text-[12.5px] text-text-dim mt-2">Esa página no existe.</p>
        <Link to="/app" className="inline-block mt-4 text-[12px] text-accent">
          Ir al resumen general
        </Link>
      </section>
    </main>
  );
}
