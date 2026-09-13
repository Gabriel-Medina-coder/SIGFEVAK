import { useEffect, useRef, useState } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { useAuth } from '@/lib/auth';
import { MODULOS } from '@/lib/permisos';
import { ICONO_MODULO } from '@/components/Iconos';
import './landing.css';

const REPO = 'https://github.com/Gabriel-Medina-coder/SIGFEVAK';
const HISTORIA = `${REPO}/blob/main/docs/HISTORIA_FLUJO.md`;

// Posición del puntero compartida por el fondo, la luz y el logo (una sola escucha en window)
const puntero = { x: -9999, y: -9999, t: 0 };
const sinMovimiento = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const TITULO = ['Toda', 'la', 'operación', 'de', 'la', 'comercializadora,'];

// Cifras de la base de demostración (dos años de operación, D-12)
const CIFRAS = [
  { valor: 25, prefijo: '$', sufijo: ' M', decimales: 1, etiqueta: 'capital de inversión' },
  { valor: 128819, etiqueta: 'unidades de volumen de comercialización' },
  { valor: 958, etiqueta: 'facturas vigentes' },
  { valor: 24, etiqueta: 'nóminas cerradas' },
  { valor: 83, etiqueta: 'impuestos, pedimentos y trámites cerrados' },
];

const MOVIMIENTOS = [
  ['entrada', '+100 Base para laptop aluminio', '$22,000'],
  ['factura', 'FAC-000984 pagada', '$15,660'],
  ['nómina', 'Octubre cerrada con 4 firmas', '$59,213'],
  ['fiscal', 'IVA septiembre conciliado', '$44,784'],
  ['pedimento', '26 47 3891 6004588 · Manzanillo', '$41,194'],
  ['producción', 'OP-2026-0003 · 19 kits a costo real', '$306.58'],
  ['marketing', 'Reactivación Golfo · ROI real', '18.01x'],
  ['inventario', 'Conciliación con faltante de 2 piezas', '−2'],
];

const FLUJO = [
  {
    area: 'Área 1 · Entradas',
    titulo: 'Llega o se fabrica la mercancía',
    texto:
      'Electrónicos importados y manufactura nacional con su valor, capital de inversión y volumen de comercialización.',
  },
  {
    area: 'Área 3 · Inventario',
    titulo: 'El stock se mueve solo',
    texto: 'Solo los triggers escriben el stock. El kardex guarda cada movimiento con su origen.',
  },
  {
    area: 'Área 2 · Contabilidad',
    titulo: 'Se factura y se cobra',
    texto:
      'Cada cliente con su número de comercializador; folio, IVA y totales los pone la base. No se vende lo que no hay.',
  },
  {
    area: 'Área 4 · Nómina',
    titulo: 'Se paga a los agentes',
    texto:
      'Sueldo, comisión sobre lo cobrado y bonos, con ISR e IMSS. Quien calcula el periodo no lo autoriza.',
  },
  {
    area: 'Área 5 · Fiscal',
    titulo: 'Se pagan impuestos, aduanas y permisos',
    texto:
      'Impuestos de gobierno, contribuciones aduanales, licencias y permisos con orden de pago dirigida, autorización y comprobante.',
  },
  {
    area: 'Área 6 · Marketing',
    titulo: 'Se invierte en marketing y se mide',
    texto:
      'Costos e investigación de mercado de campañas externas y directas; el ROI real sale de las facturas pagadas.',
  },
];

const REGLAS = [
  {
    titulo: 'No se vende lo que no hay',
    comando: 'agregar renglón · 500 bases para laptop',
    respuesta: 'Stock insuficiente (disponible: 170, solicitado: 500)',
  },
  {
    titulo: 'Quien calcula no autoriza',
    comando: 'autorizar nómina de octubre · admin',
    respuesta: 'admin calculó el periodo y no puede autorizarlo',
  },
  {
    titulo: 'Sin sesión no hay datos',
    comando: 'leer v_nomina_totales · sin iniciar sesión',
    respuesta: 'permiso denegado: inicia sesión para continuar',
  },
];

// ---------- Utilidades de animación ----------

// Bloque que aparece al entrar en pantalla. Lo visto vive en el estado de React: si el bloque se vuelve a
// pintar no se oculta de nuevo, y lo que ya quedó arriba de la pantalla (recarga a media página) se muestra.
function Revelar({ className = '', refExterno, children, ...resto }) {
  const propio = useRef(null);
  const [visible, setVisible] = useState(sinMovimiento);
  useEffect(() => {
    const el = propio.current;
    if (visible || !el) return;
    const obs = new IntersectionObserver(
      ([en]) => {
        if (en.isIntersecting || en.boundingClientRect.bottom < 0) {
          setVisible(true);
          obs.disconnect();
        }
      },
      { threshold: 0.1 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [visible]);
  const unir = (nodo) => {
    propio.current = nodo;
    if (typeof refExterno === 'function') refExterno(nodo);
    else if (refExterno) refExterno.current = nodo;
  };
  return (
    <div ref={unir} className={`lp-revelar ${visible ? 'lp-visible' : ''} ${className}`} {...resto}>
      {children}
    </div>
  );
}

function useAlVer(umbral = 0.3) {
  const ref = useRef(null);
  const [visto, setVisto] = useState(false);
  useEffect(() => {
    if (!ref.current) return;
    const obs = new IntersectionObserver(
      ([en]) => {
        if (en.isIntersecting) {
          setVisto(true);
          obs.disconnect();
        }
      },
      { threshold: umbral }
    );
    obs.observe(ref.current);
    return () => obs.disconnect();
  }, [umbral]);
  return [ref, visto];
}

function colorToken(nombre, respaldo) {
  const v = getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
  return v || respaldo;
}

function aRgb(hex) {
  const h = hex.replace('#', '');
  const n = parseInt(h.length === 3 ? [...h].map((c) => c + c).join('') : h, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

// Tarjeta con borde y reflejo que siguen al cursor
function iluminar(e) {
  const r = e.currentTarget.getBoundingClientRect();
  e.currentTarget.style.setProperty('--px', `${e.clientX - r.left}px`);
  e.currentTarget.style.setProperty('--py', `${e.clientY - r.top}px`);
}

// ---------- Fondo ----------

// Partículas que suben despacio como mercancía en tránsito; cerca del cursor se enlazan con él y se apartan
function Particulas() {
  const ref = useRef(null);
  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas.getContext('2d');
    const [r, g, b] = aRgb(colorToken('--color-accent', '#f0a500'));
    const [tr, tg, tb] = aRgb(colorToken('--color-text', '#e8e8e8'));
    let ancho = 0;
    let alto = 0;
    let puntos = [];
    let raf = 0;

    const crear = () => ({
      x: Math.random() * ancho,
      y: Math.random() * alto,
      vx: (Math.random() - 0.5) * 0.18,
      vy: -(0.08 + Math.random() * 0.32),
      radio: 0.6 + Math.random() * 1.5,
      calido: Math.random() < 0.35,
    });

    const medir = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      ancho = window.innerWidth;
      alto = window.innerHeight;
      canvas.width = ancho * dpr;
      canvas.height = alto * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      const total = Math.min(110, Math.round((ancho * alto) / 15000));
      puntos = Array.from({ length: total }, crear);
    };

    const dibujar = () => {
      ctx.clearRect(0, 0, ancho, alto);
      const mx = puntero.x;
      const my = puntero.y;
      for (const p of puntos) {
        const dx = p.x - mx;
        const dy = p.y - my;
        const d = Math.hypot(dx, dy);
        if (d < 140 && d > 0) {
          p.x += (dx / d) * 0.9;
          p.y += (dy / d) * 0.9;
        }
        p.x += p.vx;
        p.y += p.vy;
        if (p.y < -10) {
          p.y = alto + 10;
          p.x = Math.random() * ancho;
        }
        if (p.x < -10) p.x = ancho + 10;
        if (p.x > ancho + 10) p.x = -10;
      }
      for (let i = 0; i < puntos.length; i++) {
        const a = puntos[i];
        for (let j = i + 1; j < puntos.length; j++) {
          const c = puntos[j];
          const d = Math.hypot(a.x - c.x, a.y - c.y);
          if (d < 120) {
            ctx.strokeStyle = `rgba(${tr},${tg},${tb},${0.07 * (1 - d / 120)})`;
            ctx.lineWidth = 0.6;
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(c.x, c.y);
            ctx.stroke();
          }
        }
        const dm = Math.hypot(a.x - mx, a.y - my);
        if (dm < 200) {
          ctx.strokeStyle = `rgba(${r},${g},${b},${0.35 * (1 - dm / 200)})`;
          ctx.lineWidth = 0.8;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(mx, my);
          ctx.stroke();
        }
        const cerca = dm < 200 ? 1 - dm / 200 : 0;
        ctx.fillStyle = a.calido
          ? `rgba(${r},${g},${b},${0.55 + cerca * 0.45})`
          : `rgba(${tr},${tg},${tb},${0.25 + cerca * 0.5})`;
        ctx.beginPath();
        ctx.arc(a.x, a.y, a.radio + cerca * 1.2, 0, Math.PI * 2);
        ctx.fill();
      }
    };

    const ciclo = () => {
      dibujar();
      raf = requestAnimationFrame(ciclo);
    };

    medir();
    if (sinMovimiento()) dibujar();
    else raf = requestAnimationFrame(ciclo);
    window.addEventListener('resize', medir);
    const visibilidad = () => {
      cancelAnimationFrame(raf);
      if (!document.hidden && !sinMovimiento()) raf = requestAnimationFrame(ciclo);
    };
    document.addEventListener('visibilitychange', visibilidad);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', medir);
      document.removeEventListener('visibilitychange', visibilidad);
    };
  }, []);
  return <canvas ref={ref} className="lp-canvas" aria-hidden="true" />;
}

// Luz suave que persigue al cursor con retraso
function LuzCursor() {
  const ref = useRef(null);
  useEffect(() => {
    let x = -999;
    let y = -999;
    let raf = 0;
    const ciclo = () => {
      x += (puntero.x - x) * 0.12;
      y += (puntero.y - y) * 0.12;
      ref.current?.style.setProperty('--cx', `${x}px`);
      ref.current?.style.setProperty('--cy', `${y}px`);
      raf = requestAnimationFrame(ciclo);
    };
    raf = requestAnimationFrame(ciclo);
    return () => cancelAnimationFrame(raf);
  }, []);
  return <div ref={ref} className="lp-cursor" aria-hidden="true" />;
}

// ---------- Logo neón ----------

// Apagado por defecto. El cursor lo alumbra en un radio que se desvanece; encima del logo se enciende completo.
// Sin mouse (celular) o sin moverlo un rato, la luz recorre el logo sola.
function LogoNeon() {
  const ref = useRef(null);
  const [encendido, setEncendido] = useState(false);
  const [pista, setPista] = useState(true);

  useEffect(() => {
    const el = ref.current;
    if (sinMovimiento()) {
      el.style.setProperty('--r', '2000px');
      el.style.setProperty('--halo', '1');
      return;
    }
    let lx = 0.5;
    let ly = 0.5;
    let radio = 0;
    let raf = 0;
    let estabaEncendido = false;
    let activo = false;

    const ciclo = (t) => {
      const caja = el.getBoundingClientRect();
      const w = caja.width;
      const h = caja.height;
      const reciente = performance.now() - puntero.t < 2600;
      let objX;
      let objY;
      let objR;
      if (reciente) {
        objX = puntero.x - caja.left;
        objY = puntero.y - caja.top;
        const dentro = objX > w * 0.14 && objX < w * 0.86 && objY > h * 0.1 && objY < h * 0.9;
        objR = dentro ? w * 1.25 : w * 0.42;
      } else {
        objX = w / 2 + Math.cos(t / 1900) * w * 0.34;
        objY = h / 2 + Math.sin(t / 1400) * h * 0.3;
        objR = w * 0.36;
      }
      lx += (objX - lx) * 0.14;
      ly += (objY - ly) * 0.14;
      radio += (objR - radio) * 0.08;
      el.style.setProperty('--lx', `${lx}px`);
      el.style.setProperty('--ly', `${ly}px`);
      el.style.setProperty('--r', `${radio}px`);
      el.style.setProperty('--halo', `${Math.min(radio / (w * 1.1), 1)}`);
      const ahora = radio > w * 0.95;
      if (ahora !== estabaEncendido) {
        estabaEncendido = ahora;
        setEncendido(ahora);
        if (ahora) setPista(false);
      }
      raf = requestAnimationFrame(ciclo);
    };

    const obs = new IntersectionObserver(([en]) => {
      if (en.isIntersecting && !activo) {
        activo = true;
        raf = requestAnimationFrame(ciclo);
      } else if (!en.isIntersecting && activo) {
        activo = false;
        cancelAnimationFrame(raf);
      }
    });
    obs.observe(el);
    return () => {
      obs.disconnect();
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <div ref={ref} className="lp-logo" data-encendido={encendido} aria-hidden="true">
      <div className="lp-halo" />
      <img className="lp-logo-base" src="/logo-neon.webp" alt="" />
      <img className="lp-logo-luz" src="/logo-neon.webp" alt="" />
      <div className="lp-logo-pista" style={{ opacity: pista ? 1 : 0 }}>
        acerca el cursor
      </div>
    </div>
  );
}

// ---------- Secciones ----------

function Navegacion() {
  const [compacta, setCompacta] = useState(false);
  useEffect(() => {
    const alScroll = () => setCompacta(window.scrollY > 40);
    alScroll();
    window.addEventListener('scroll', alScroll, { passive: true });
    return () => window.removeEventListener('scroll', alScroll);
  }, []);
  const ir = (id) => (e) => {
    e.preventDefault();
    document
      .getElementById(id)
      ?.scrollIntoView({ behavior: sinMovimiento() ? 'auto' : 'smooth', block: 'start' });
  };
  return (
    <nav className="lp-nav" data-compacta={compacta}>
      <a href="#inicio" onClick={ir('inicio')} className="flex items-center gap-2.5">
        <img src="/logo-sigfevak.png" alt="" className="w-9 h-9 object-cover" />
        <span className="font-bold text-[14px] tracking-[-0.02em]">SIGFEVAK</span>
      </a>
      <div className="flex items-center gap-6 max-[760px]:hidden">
        {[
          ['flujo', 'Flujo'],
          ['cifras', 'Cifras'],
          ['reglas', 'Reglas'],
          ['modulos', 'Módulos'],
        ].map(([id, texto]) => (
          <a key={id} href={`#${id}`} onClick={ir(id)} className="lp-enlace">
            {texto}
          </a>
        ))}
      </div>
      <Link to="/login" className="lp-boton lp-boton--acento !py-2 !px-4 !text-[12.5px]">
        Entrar <span className="lp-flecha">→</span>
      </Link>
    </nav>
  );
}

function Hero() {
  return (
    <section
      id="inicio"
      className="max-w-6xl mx-auto px-6 pt-36 pb-16 grid grid-cols-[1.1fr_1fr] items-center gap-10 max-[960px]:grid-cols-1 max-[960px]:pt-28"
    >
      <div>
        <div className="lp-ceja lp-palabra" style={{ animationDelay: '0.05s' }}>
          <b>[</b> Sistema de gestión · 6 áreas <b>]</b>
        </div>
        <h1 className="lp-titulo mt-6">
          {TITULO.map((p, i) => (
            <span key={i} className="lp-palabra" style={{ animationDelay: `${0.15 + i * 0.07}s` }}>
              {p}&nbsp;
            </span>
          ))}
          <span
            className="lp-palabra"
            style={{ animationDelay: `${0.15 + TITULO.length * 0.07}s` }}
          >
            <span className="lp-resaltado">en una sola app.</span>
          </span>
        </h1>
        <p
          className="lp-palabra text-[15px] text-text-dim mt-6 leading-relaxed max-w-xl"
          style={{ animationDelay: '0.75s' }}
        >
          Comercializadora mexicana de electrónicos y manufactura nacional. De la mercancía que
          llega al almacén al impuesto que se paga: entradas, facturas, inventario, pagos a agentes,
          trámites de gobierno y marketing conectados, con las reglas de negocio en la base de
          datos.
        </p>
        <div className="lp-palabra mt-9 flex flex-wrap gap-3" style={{ animationDelay: '0.9s' }}>
          <Link to="/login" className="lp-boton lp-boton--acento">
            Iniciar sesión <span className="lp-flecha">→</span>
          </Link>
          <a href={HISTORIA} target="_blank" rel="noreferrer" className="lp-boton lp-boton--vidrio">
            Ver la historia con capturas
          </a>
        </div>
        <div
          className="lp-palabra mt-10 flex items-center gap-3 text-[11.5px] text-text-dim"
          style={{ animationDelay: '1.05s' }}
        >
          <span className="lp-pulso w-2 h-2 rounded-full bg-up inline-block" />
          Base de demostración con dos años de operación · sep 2024 a sep 2026
        </div>
      </div>
      <div className="flex justify-center lp-palabra" style={{ animationDelay: '0.4s' }}>
        <LogoNeon />
      </div>
    </section>
  );
}

function Cinta() {
  const fila = (lista, inversa) => (
    <div className="lp-cinta overflow-hidden">
      <div className={`lp-cinta-pista ${inversa ? 'lp-cinta-pista--inversa' : ''}`}>
        {[...lista, ...lista].map(([tipo, texto, monto], i) => (
          <div
            key={i}
            className="flex items-center gap-3 rounded-full border border-border bg-surface/60 backdrop-blur px-4 py-2 whitespace-nowrap"
          >
            <span className="font-mono text-[10px] uppercase tracking-[0.12em] text-accent">
              {tipo}
            </span>
            <span className="text-[12.5px] text-text">{texto}</span>
            <span className="font-mono text-[12px] text-up">{monto}</span>
          </div>
        ))}
      </div>
    </div>
  );
  return (
    <section className="py-6 flex flex-col gap-3" aria-label="Movimientos recientes">
      {fila(MOVIMIENTOS, false)}
      {fila([...MOVIMIENTOS].reverse(), true)}
    </section>
  );
}

// Ventana de la app que se endereza al entrar en pantalla y se inclina con el cursor
function VentanaApp() {
  const escena = useRef(null);
  const ventana = useRef(null);
  const [refVista, visto] = useAlVer(0.25);

  useEffect(() => {
    if (sinMovimiento()) {
      ventana.current?.style.setProperty('--entrada', '0');
      return;
    }
    const alScroll = () => {
      const caja = escena.current?.getBoundingClientRect();
      if (!caja) return;
      const avance = Math.min(
        Math.max((window.innerHeight - caja.top) / (window.innerHeight * 0.7), 0),
        1
      );
      ventana.current?.style.setProperty('--entrada', `${1 - avance}`);
    };
    alScroll();
    window.addEventListener('scroll', alScroll, { passive: true });
    return () => window.removeEventListener('scroll', alScroll);
  }, []);

  const inclinar = (e) => {
    if (sinMovimiento()) return;
    const caja = e.currentTarget.getBoundingClientRect();
    const px = (e.clientX - caja.left) / caja.width;
    const py = (e.clientY - caja.top) / caja.height;
    ventana.current.style.setProperty('--ty', `${(px - 0.5) * 6}deg`);
    ventana.current.style.setProperty('--tx', `${(0.5 - py) * 5}deg`);
    ventana.current.style.setProperty('--gx', `${px * 100}%`);
    ventana.current.style.setProperty('--gy', `${py * 100}%`);
  };
  const soltar = () => {
    ventana.current.style.setProperty('--ty', '0deg');
    ventana.current.style.setProperty('--tx', '0deg');
  };

  const barras = [58, 66, 49, 81, 72, 88, 64, 77, 70, 94, 83, 100];
  const meses = [
    'oct',
    'nov',
    'dic',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
  ];
  const kpis = [
    ['Capital de inversión', '$24.97 M', '2 años'],
    ['Clientes activos', '24', '$987,392 por cobrar'],
    ['Nómina del periodo', '$59,213', '5 agentes'],
    ['Pagado en obligaciones', '$1.59 M', 'este año'],
  ];

  return (
    <section className="max-w-6xl mx-auto px-6 pb-24" ref={escena}>
      <div className="lp-escena" onPointerMove={inclinar} onPointerLeave={soltar}>
        <div ref={ventana} className={`lp-ventana ${visto ? 'lp-visible' : ''}`}>
          <div
            ref={refVista}
            className="flex items-center gap-2 px-5 py-3.5 border-b border-border"
          >
            <span className="w-2.5 h-2.5 rounded-full bg-down/80" />
            <span className="w-2.5 h-2.5 rounded-full bg-accent/80" />
            <span className="w-2.5 h-2.5 rounded-full bg-up/80" />
            <span className="ml-4 font-mono text-[11px] text-text-dim">
              sigfevak / resumen general
            </span>
          </div>
          <div className="p-6 grid grid-cols-4 gap-3 max-[900px]:grid-cols-2">
            {kpis.map(([etiqueta, valor, nota]) => (
              <div key={etiqueta} className="rounded-xl border border-border bg-bg/50 px-4 py-3.5">
                <div className="text-[10px] uppercase tracking-[0.06em] text-text-dim">
                  {etiqueta}
                </div>
                <div className="font-mono text-[22px] font-semibold mt-1 max-[520px]:text-[17px]">
                  {valor}
                </div>
                <div className="font-mono text-[10.5px] text-up mt-0.5">{nota}</div>
              </div>
            ))}
          </div>
          <div className="px-6 pb-6 grid grid-cols-[1.6fr_1fr] gap-3 max-[900px]:grid-cols-1">
            <div className="rounded-xl border border-border bg-bg/50 p-4">
              <div className="text-[12px] font-medium">Facturación sin IVA por mes</div>
              <div className="flex items-end gap-2 h-36 mt-4">
                {barras.map((h, i) => (
                  <div
                    key={i}
                    className="flex-1 flex flex-col items-center gap-1.5 h-full justify-end"
                  >
                    <div
                      className={`lp-barra w-full rounded-[4px] ${i === barras.length - 1 ? 'bg-accent' : 'bg-surface-2 border border-border'}`}
                      style={{ height: `${h}%`, transitionDelay: `${i * 60}ms` }}
                    />
                    <span className="font-mono text-[9px] text-muted">{meses[i]}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="rounded-xl border border-border bg-bg/50 p-4 flex flex-col gap-2.5">
              <div className="text-[12px] font-medium">Próximas obligaciones</div>
              {[
                ['Licencia de uso de suelo', '30 sep', '$4,800'],
                ['Pago provisional de ISR', '17 oct', '$22,884'],
                ['ISN Chiapas', '17 nov', '$871'],
              ].map(([n, f, m]) => (
                <div
                  key={n}
                  className="flex items-center justify-between border-b border-border pb-2"
                >
                  <div>
                    <div className="text-[12px]">{n}</div>
                    <div className="text-[10.5px] text-text-dim">vence {f}</div>
                  </div>
                  <span className="font-mono text-[12px] text-down">{m}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="lp-aviso absolute right-5 -bottom-5 max-[520px]:right-3 rounded-xl border border-up/40 bg-surface/90 backdrop-blur px-4 py-2.5 flex items-center gap-3 shadow-2xl">
            <span className="w-2 h-2 rounded-full bg-up" />
            <span className="text-[12px]">FAC-000984 pagada</span>
            <span className="font-mono text-[12px] text-up">$15,660</span>
          </div>
        </div>
      </div>
    </section>
  );
}

function Contador({ valor, prefijo = '', sufijo = '', decimales = 0, activo }) {
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!activo) return;
    if (sinMovimiento()) {
      setN(valor);
      return;
    }
    let raf = 0;
    const inicio = performance.now();
    const ciclo = (t) => {
      const p = Math.min((t - inicio) / 1800, 1);
      setN(valor * (1 - Math.pow(1 - p, 4)));
      if (p < 1) raf = requestAnimationFrame(ciclo);
    };
    raf = requestAnimationFrame(ciclo);
    return () => cancelAnimationFrame(raf);
  }, [activo, valor]);
  return (
    <span>
      {prefijo}
      {n.toLocaleString('es-MX', {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales,
      })}
      {sufijo}
    </span>
  );
}

function Cifras() {
  const [ref, visto] = useAlVer(0.35);
  return (
    <section id="cifras" className="max-w-6xl mx-auto px-6 py-20 scroll-mt-24">
      <Revelar refExterno={ref} className="lp-panel-cifras px-10 py-12 max-[640px]:px-6">
        <div className="lp-grano" />
        <div className="relative grid grid-cols-[1fr_1.6fr] gap-10 items-center max-[900px]:grid-cols-1">
          <div>
            <div className="lp-ceja">
              <b>[</b> Dos años en la base <b>]</b>
            </div>
            <h2 className="text-[34px] leading-[1.05] font-bold tracking-[-0.03em] mt-4 m-0">
              Probado con uso real, no con tres registros de ejemplo.
            </h2>
            <p className="text-[13.5px] text-text-dim mt-4 leading-relaxed">
              La base de demostración simula la operación de septiembre de 2024 a hoy. Todo entró
              por las mismas reglas que usa la app y las pruebas de las seis áreas siguen pasando.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-x-8 gap-y-7 max-[480px]:grid-cols-1">
            {CIFRAS.map((c, i) => (
              <div key={c.etiqueta} className={i === 0 ? 'col-span-2 max-[480px]:col-span-1' : ''}>
                <div
                  className={`font-mono font-semibold tracking-[-0.02em] ${i === 0 ? 'text-[56px] text-accent max-[480px]:text-[42px]' : 'text-[34px]'}`}
                  style={i === 0 ? { textShadow: '0 0 30px var(--color-accent-dim)' } : undefined}
                >
                  <Contador {...c} activo={visto} />
                </div>
                <div className="text-[12px] text-text-dim mt-1">{c.etiqueta}</div>
              </div>
            ))}
          </div>
        </div>
      </Revelar>
    </section>
  );
}

function Flujo() {
  const lista = useRef(null);
  const [avance, setAvance] = useState(0);
  useEffect(() => {
    const alScroll = () => {
      const caja = lista.current?.getBoundingClientRect();
      if (!caja) return;
      const centro = window.innerHeight * 0.55;
      setAvance(Math.min(Math.max((centro - caja.top) / caja.height, 0), 1));
    };
    alScroll();
    window.addEventListener('scroll', alScroll, { passive: true });
    window.addEventListener('resize', alScroll);
    return () => {
      window.removeEventListener('scroll', alScroll);
      window.removeEventListener('resize', alScroll);
    };
  }, []);

  return (
    <section id="flujo" className="max-w-6xl mx-auto px-6 py-20 scroll-mt-24">
      <div className="grid grid-cols-[1fr_1.3fr] gap-14 max-[900px]:grid-cols-1">
        <Revelar className="min-[901px]:sticky min-[901px]:top-32 self-start">
          <div className="lp-ceja">
            <b>[</b> De punta a punta <b>]</b>
          </div>
          <h2 className="text-[40px] leading-[1.03] font-bold tracking-[-0.03em] mt-4 m-0">
            Una venta recorre las seis áreas sin recapturar nada.
          </h2>
          <p className="text-[14px] text-text-dim mt-5 leading-relaxed">
            Cada paso deja listo el siguiente. Lo que captura almacén lo usa contabilidad, lo que
            cobra contabilidad paga la comisión y el impuesto, y marketing mide contra ventas
            reales.
          </p>
        </Revelar>
        <div ref={lista} className="relative pl-14">
          <div className="lp-linea" style={{ '--avance': avance }}>
            <span />
          </div>
          {FLUJO.map((p, i) => (
            <div
              key={p.titulo}
              className="lp-paso relative pb-10 last:pb-0"
              data-activo={avance >= (i + 0.2) / FLUJO.length}
            >
              <div className="lp-nodo absolute -left-14 top-0 w-10 h-10 rounded-full border border-border bg-surface flex items-center justify-center font-mono text-[13px] text-text-dim">
                {String(i + 1).padStart(2, '0')}
              </div>
              <Revelar
                className="lp-tarjeta px-5 py-4"
                style={{ '--retraso': '80ms' }}
                onPointerMove={iluminar}
              >
                <div className="relative">
                  <div className="font-mono text-[10.5px] text-accent uppercase tracking-[0.1em]">
                    {p.area}
                  </div>
                  <div className="text-[17px] font-semibold mt-1.5">{p.titulo}</div>
                  <div className="text-[13px] text-text-dim mt-1.5 leading-relaxed">{p.texto}</div>
                </div>
              </Revelar>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// Terminal que escribe la acción y muestra el rechazo de la base
function Terminal({ comando, respuesta, activo }) {
  const [escrito, setEscrito] = useState('');
  const [mostrar, setMostrar] = useState(false);
  useEffect(() => {
    if (!activo) return;
    if (sinMovimiento()) {
      setEscrito(comando);
      setMostrar(true);
      return;
    }
    let i = 0;
    const id = setInterval(() => {
      i += 1;
      setEscrito(comando.slice(0, i));
      if (i >= comando.length) {
        clearInterval(id);
        setTimeout(() => setMostrar(true), 350);
      }
    }, 28);
    return () => clearInterval(id);
  }, [activo, comando]);
  return (
    <div className="rounded-xl border border-border bg-bg/70 p-4 font-mono text-[11.5px] leading-relaxed min-h-[96px]">
      <div className="text-text-dim">
        <span className="text-accent">❯ </span>
        <span className={mostrar ? '' : 'lp-cursor-texto'}>{escrito}</span>
      </div>
      <div
        className="text-down mt-2 transition-all duration-500"
        style={{ opacity: mostrar ? 1 : 0, transform: mostrar ? 'none' : 'translateY(6px)' }}
      >
        ✕ {respuesta}
      </div>
    </div>
  );
}

function Reglas() {
  const [ref, visto] = useAlVer(0.3);
  return (
    <section id="reglas" className="max-w-6xl mx-auto px-6 py-20 scroll-mt-24">
      <Revelar className="text-center max-w-2xl mx-auto">
        <div className="lp-ceja">
          <b>[</b> Reglas que no se rompen <b>]</b>
        </div>
        <h2 className="text-[40px] leading-[1.05] font-bold tracking-[-0.03em] mt-4 m-0">
          La base dice que no, aunque la pantalla se equivoque.
        </h2>
      </Revelar>
      <div ref={ref} className="grid grid-cols-3 gap-4 mt-12 max-[960px]:grid-cols-1">
        {REGLAS.map((r, i) => (
          <Revelar
            key={r.titulo}
            className="lp-tarjeta p-5"
            style={{ '--retraso': `${i * 120}ms` }}
            onPointerMove={iluminar}
          >
            <div className="relative">
              <div className="text-[15px] font-semibold mb-4">{r.titulo}</div>
              <Terminal comando={r.comando} respuesta={r.respuesta} activo={visto} />
            </div>
          </Revelar>
        ))}
      </div>
    </section>
  );
}

function Modulos() {
  return (
    <section id="modulos" className="max-w-6xl mx-auto px-6 py-20 scroll-mt-24">
      <Revelar className="flex items-end justify-between gap-6 flex-wrap">
        <div>
          <div className="lp-ceja">
            <b>[</b> Siete módulos <b>]</b>
          </div>
          <h2 className="text-[40px] leading-[1.05] font-bold tracking-[-0.03em] mt-4 m-0">
            Cada área en su módulo.
          </h2>
        </div>
        <p className="text-[13.5px] text-text-dim max-w-md leading-relaxed">
          Todos se ven; cada quien captura solo en lo de su rol. La coordinación ve el resumen de
          las seis.
        </p>
      </Revelar>
      <div className="grid grid-cols-4 gap-3.5 mt-10 max-[960px]:grid-cols-2 max-[520px]:grid-cols-1">
        {MODULOS.map((m, i) => {
          const Icono = ICONO_MODULO[m.id];
          return (
            <Revelar
              key={m.id}
              className={`lp-tarjeta px-5 py-5 ${i === 0 ? 'col-span-2 max-[520px]:col-span-1' : ''}`}
              style={{ '--retraso': `${i * 70}ms` }}
              onPointerMove={iluminar}
            >
              <div className="relative">
                <div className="lp-icono text-text-dim mb-4">
                  <Icono size={22} />
                </div>
                <div className="text-[14px] font-semibold">{m.etiqueta}</div>
                <div className="text-[12px] text-text-dim mt-1">{m.subtitulo}</div>
              </div>
            </Revelar>
          );
        })}
      </div>
    </section>
  );
}

function Final() {
  return (
    <section className="max-w-6xl mx-auto px-6 pt-10 pb-24">
      <Revelar className="lp-panel-cifras px-10 py-16 text-center max-[640px]:px-6">
        <div className="lp-grano" />
        <div className="relative">
          <img
            src="/logo-neon.webp"
            alt=""
            className="w-24 h-24 mx-auto object-contain"
            style={{ filter: 'drop-shadow(0 0 24px var(--color-accent))' }}
          />
          <h2 className="text-[42px] leading-[1.05] font-bold tracking-[-0.03em] mt-6 m-0 max-[640px]:text-[32px]">
            Entra y recorre la operación.
          </h2>
          <p className="text-[14px] text-text-dim mt-4 max-w-lg mx-auto leading-relaxed">
            Cada rol tiene su cuenta de prueba. Si prefieres verlo antes, la historia completa trae
            capturas y cifras de cada paso.
          </p>
          <div className="mt-8 flex justify-center flex-wrap gap-3">
            <Link to="/login" className="lp-boton lp-boton--acento">
              Iniciar sesión <span className="lp-flecha">→</span>
            </Link>
            <a href={REPO} target="_blank" rel="noreferrer" className="lp-boton lp-boton--vidrio">
              Ver el proyecto
            </a>
          </div>
        </div>
      </Revelar>
    </section>
  );
}

// Página pública de entrada. Si ya hay sesión, pasa directo a la app.
export default function Landing() {
  const { session, cargando } = useAuth();

  useEffect(() => {
    const mover = (e) => {
      puntero.x = e.clientX;
      puntero.y = e.clientY;
      puntero.t = performance.now();
    };
    window.addEventListener('pointermove', mover, { passive: true });
    return () => window.removeEventListener('pointermove', mover);
  }, []);

  if (!cargando && session) return <Navigate to="/app" replace />;

  return (
    <div className="lp">
      <Particulas />
      <LuzCursor />
      <div className="lp-orbe lp-orbe--a" />
      <div className="lp-orbe lp-orbe--b" />
      <Navegacion />
      <main className="lp-contenido">
        <Hero />
        <VentanaApp />
        <Cinta />
        <Flujo />
        <Cifras />
        <Reglas />
        <Modulos />
        <Final />
      </main>
      <footer className="lp-contenido max-w-6xl mx-auto px-6 py-8 border-t border-border flex justify-between flex-wrap gap-3 text-[11.5px] text-muted">
        <span>SIGFEVAK · Comercializadora Nacional · Proyecto escolar</span>
        <span>Septiembre 2026</span>
      </footer>
    </div>
  );
}
