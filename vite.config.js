import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'node:path';
import { defineConfig } from 'vite';

// Cabeceras de seguridad en las respuestas del servidor de Vite (dev y preview).
// En dev no se pone CSP para no romper el HMR; en preview (cercano a producción) se pone una CSP estricta que
// solo permite el propio origen y la API de Supabase. En un hosting real, el servidor debe enviar estas cabeceras.
function cabecerasSeguridad() {
  const supabase = process.env.VITE_SUPABASE_URL || '';
  const comunes = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
  };
  const csp = [
    "default-src 'self'",
    "base-uri 'self'",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "img-src 'self' data: blob:",
    "style-src 'self' 'unsafe-inline'",
    "script-src 'self'",
    "font-src 'self'",
    `connect-src 'self' ${supabase} https://*.supabase.co wss://*.supabase.co`.trim(),
    'upgrade-insecure-requests',
  ].join('; ');
  const aplica = (extra) => (req, res, next) => {
    for (const [k, v] of Object.entries({ ...comunes, ...extra })) res.setHeader(k, v);
    next();
  };
  return {
    name: 'cabeceras-seguridad',
    configureServer(s) {
      s.middlewares.use(aplica({}));
    },
    configurePreviewServer(s) {
      s.middlewares.use(
        aplica({
          'Content-Security-Policy': csp,
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        })
      );
    },
  };
}

// https://vite.dev/config/
// React, Tailwind CSS v4, el alias "@" hacia src/ y las cabeceras de seguridad.
export default defineConfig({
  plugins: [react(), tailwindcss(), cabecerasSeguridad()],
  resolve: {
    alias: { '@': path.resolve(import.meta.dirname, 'src') },
  },
  build: {
    // Separa las librerías grandes en su propio chunk para que carguen en paralelo y se cacheen aparte.
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return;
          if (id.includes('react')) return 'react';
          if (id.includes('@supabase')) return 'supabase';
          if (id.includes('zod')) return 'validacion';
          return 'vendor';
        },
      },
    },
  },
});
