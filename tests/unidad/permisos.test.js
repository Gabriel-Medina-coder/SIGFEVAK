// Pruebas unitarias de src/lib/permisos.js: la matriz de escritura por rol y módulo, y la ruta a módulo.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { puedeEscribir, moduloPorRuta, MODULOS } from '../../src/lib/permisos.js';

test('ALMACEN solo escribe en entradas e inventario', () => {
  assert.equal(puedeEscribir('ALMACEN', 'entradas'), true);
  assert.equal(puedeEscribir('ALMACEN', 'inventario'), true);
  assert.equal(puedeEscribir('ALMACEN', 'contable'), false);
  assert.equal(puedeEscribir('ALMACEN', 'nomina'), false);
  assert.equal(puedeEscribir('ALMACEN', 'marketing'), false);
});

test('CONTADOR escribe contable, nomina y regulacion, no marketing', () => {
  assert.equal(puedeEscribir('CONTADOR', 'contable'), true);
  assert.equal(puedeEscribir('CONTADOR', 'nomina'), true);
  assert.equal(puedeEscribir('CONTADOR', 'regulacion'), true);
  assert.equal(puedeEscribir('CONTADOR', 'marketing'), false);
});

test('ADMINISTRADOR escribe en las seis áreas', () => {
  for (const m of ['entradas', 'contable', 'inventario', 'nomina', 'regulacion', 'marketing'])
    assert.equal(puedeEscribir('ADMINISTRADOR', m), true, m);
});

test('MARKETING solo escribe marketing', () => {
  assert.equal(puedeEscribir('MARKETING', 'marketing'), true);
  assert.equal(puedeEscribir('MARKETING', 'contable'), false);
});

test('CAPTURISTA no escribe en ningún módulo', () => {
  for (const m of MODULOS.filter((x) => x.id !== 'resumen'))
    assert.equal(puedeEscribir('CAPTURISTA', m.id), false, m.id);
});

test('rol desconocido o indefinido no escribe nada', () => {
  assert.equal(puedeEscribir(undefined, 'entradas'), false);
  assert.equal(puedeEscribir('HACKER', 'nomina'), false);
});

test('moduloPorRuta ubica el módulo activo por la ruta', () => {
  assert.equal(moduloPorRuta('/app').id, 'resumen');
  assert.equal(moduloPorRuta('/app/nomina').id, 'nomina');
  assert.equal(moduloPorRuta('/app/regulacion/lo-que-sea').id, 'regulacion');
});
