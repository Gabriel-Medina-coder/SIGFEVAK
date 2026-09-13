import { useEffect, useRef, useState } from 'react';

// Efectos compartidos de la landing y el login: partículas, luz que sigue al mouse y logo neón.

// Posición del puntero compartida por el fondo, la luz y el logo (una sola escucha en window)
export const puntero = { x: -9999, y: -9999, t: 0 };
export const sinMovimiento = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Registra la posición del puntero para todos los efectos de la página
export function usePuntero() {
  useEffect(() => {
    const mover = (e) => {
      puntero.x = e.clientX;
      puntero.y = e.clientY;
      puntero.t = performance.now();
    };
    window.addEventListener('pointermove', mover, { passive: true });
    return () => window.removeEventListener('pointermove', mover);
  }, []);
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

// ---------- Fondo ----------

// Partículas que suben despacio como mercancía en tránsito; cerca del cursor se enlazan con él y se apartan
export function Particulas() {
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
export function LuzCursor() {
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
export function LogoNeon() {
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
