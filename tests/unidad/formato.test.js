// Pruebas unitarias de src/lib/formato.js (formato de montos, cantidades y fechas es-MX).
// Se corren con `node --test`, sin dependencias externas.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pesos, miles, porcentaje, fechaCorta, periodoCorto } from '../../src/lib/formato.js';

const soloDigitos = (s) => s.replace(/[^0-9.]/g, '');

test('pesos sin centavos redondea y sin decimales', () => {
  assert.equal(soloDigitos(pesos(15660)), '15660');
  assert.equal(soloDigitos(pesos(0)), '0');
});

test('pesos con centavos conserva dos decimales', () => {
  assert.equal(soloDigitos(pesos(306.58, { centavos: true })), '306.58');
  assert.equal(soloDigitos(pesos(220, { centavos: true })), '220.00');
});

test('pesos tolera null y undefined', () => {
  assert.equal(soloDigitos(pesos(null)), '0');
  assert.equal(soloDigitos(pesos(undefined)), '0');
});

test('miles agrupa por millares', () => {
  assert.equal(miles(128819), '128,819');
  assert.equal(miles(0), '0');
});

test('porcentaje con decimales configurables', () => {
  assert.equal(porcentaje(112), '112.0%');
  assert.equal(porcentaje(67.8571, 4), '67.8571%');
  assert.equal(porcentaje(null), '0.0%');
});

test('fechaCorta convierte ISO a formato legible', () => {
  assert.equal(fechaCorta('2026-09-13'), '13 Sep 2026');
  assert.equal(fechaCorta('2026-01-05T10:00:00Z'), '05 Ene 2026');
  assert.equal(fechaCorta(''), '');
  assert.equal(fechaCorta(null), '');
});

test('periodoCorto convierte AAAA-MM a mes y año', () => {
  assert.equal(periodoCorto('2026-09'), 'Sep 2026');
  assert.equal(periodoCorto('2024-12'), 'Dic 2024');
  assert.equal(periodoCorto(''), '');
});
