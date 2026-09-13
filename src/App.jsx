// Punto de entrada. El layout con el menú de las seis áreas, el login y las pantallas
// se agregan por bloques (ver docs/FLUJO_APP.md).
export default function App() {
  return (
    <main className="min-h-dvh grid place-items-center p-6">
      <section className="bg-surface border border-border rounded-xl p-6 max-w-md w-full">
        <div className="flex items-center gap-3">
          <img src="/logo-sigfevak.png" alt="SIGFEVAK" className="w-9 h-9 rounded-[7px]" />
          <div>
            <h1 className="text-[14.5px] font-bold tracking-tight leading-none">SIGFEVAK</h1>
            <p className="text-[10.5px] text-text-dim mt-0.5">Comercializadora Nacional</p>
          </div>
        </div>
        <p className="mt-4 text-text-dim text-[12.5px]">
          Base del proyecto inicializada. Cada área trabaja en su carpeta de{' '}
          <span className="font-mono">src/modules/</span>.
        </p>
      </section>
    </main>
  );
}
