// Formato de montos, cantidades y fechas para toda la interfaz (es-MX).

const moneda = new Intl.NumberFormat('es-MX', {
  style: 'currency',
  currency: 'MXN',
  maximumFractionDigits: 0,
});
const monedaCentavos = new Intl.NumberFormat('es-MX', {
  style: 'currency',
  currency: 'MXN',
  minimumFractionDigits: 2,
});
const numero = new Intl.NumberFormat('es-MX');

export function pesos(valor, { centavos = false } = {}) {
  const n = Number(valor ?? 0);
  return centavos ? monedaCentavos.format(n) : moneda.format(n);
}

export function miles(valor) {
  return numero.format(Number(valor ?? 0));
}

export function porcentaje(valor, decimales = 1) {
  return `${Number(valor ?? 0).toFixed(decimales)}%`;
}

const MESES = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

// '2026-09-13' -> '13 Sep 2026'
export function fechaCorta(iso) {
  if (!iso) return '';
  const [a, m, d] = String(iso).slice(0, 10).split('-').map(Number);
  return `${String(d).padStart(2, '0')} ${MESES[m - 1]} ${a}`;
}

// '2026-09' -> 'Sep 2026'
export function periodoCorto(periodo) {
  if (!periodo) return '';
  const [a, m] = periodo.split('-').map(Number);
  return `${MESES[m - 1]} ${a}`;
}

export function hoyIso() {
  return new Date().toISOString().slice(0, 10);
}

export function periodoActual() {
  return hoyIso().slice(0, 7);
}
