// Ejecuta SQL en el proyecto de Supabase con la API de administración, sin CLI.
// Uso:
//   node supabase/sql.mjs query "select 1"                 -> ejecuta una consulta y muestra el resultado
//   node supabase/sql.mjs file ruta/al/archivo.sql          -> ejecuta el archivo completo
//   node supabase/sql.mjs migrate ruta/migrations/x.sql     -> aplica el archivo como migración registrada
//   node supabase/sql.mjs migrations                        -> lista las migraciones aplicadas
// Requiere .env.supabase (ignorado por git) con SUPABASE_ACCESS_TOKEN y SUPABASE_PROJECT_REF.
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

const env = Object.fromEntries(
  readFileSync(new URL('../.env.supabase', import.meta.url), 'utf8')
    .split(/\r?\n/)
    .filter((l) => l.includes('='))
    .map((l) => l.split('=').map((s) => s.trim()))
);
const base = `https://api.supabase.com/v1/projects/${env.SUPABASE_PROJECT_REF}/database`;
const headers = { Authorization: `Bearer ${env.SUPABASE_ACCESS_TOKEN}`, 'Content-Type': 'application/json' };

async function llamar(ruta, metodo, body) {
  const r = await fetch(`${base}${ruta}`, { method: metodo, headers, body: body ? JSON.stringify(body) : undefined });
  const texto = await r.text();
  if (!r.ok) {
    console.error(`HTTP ${r.status}: ${texto}`);
    process.exit(1);
  }
  return texto ? JSON.parse(texto) : null;
}

const [modo, arg] = process.argv.slice(2);
if (modo === 'query') {
  console.log(JSON.stringify(await llamar('/query', 'POST', { query: arg }), null, 2));
} else if (modo === 'file') {
  await llamar('/query', 'POST', { query: readFileSync(arg, 'utf8') });
  console.log(`ejecutado: ${arg}`);
} else if (modo === 'migrate') {
  const name = basename(arg).replace(/\.sql$/, '');
  await llamar('/migrations', 'POST', { name, query: readFileSync(arg, 'utf8') });
  console.log(`migración aplicada y registrada: ${name}`);
} else if (modo === 'migrations') {
  console.log(JSON.stringify(await llamar('/migrations', 'GET'), null, 2));
} else {
  console.error('modo desconocido');
  process.exit(1);
}
