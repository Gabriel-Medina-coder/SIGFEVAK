// Exporta un arreglo de objetos a CSV (UTF-8 con BOM para que Excel respete acentos).
export function exportarCsv(nombreArchivo, filas, columnas) {
  if (!filas?.length) return;
  const cols = columnas ?? Object.keys(filas[0]).map((c) => ({ campo: c, titulo: c }));
  const escapar = (v) => {
    const s = v === null || v === undefined ? '' : String(v);
    return /[",\n;]/.test(s) ? `"${s.replaceAll('"', '""')}"` : s;
  };
  const lineas = [cols.map((c) => escapar(c.titulo)).join(',')];
  for (const f of filas) lineas.push(cols.map((c) => escapar(f[c.campo])).join(','));
  const blob = new Blob(['﻿' + lineas.join('\n')], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = nombreArchivo.endsWith('.csv') ? nombreArchivo : `${nombreArchivo}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}
