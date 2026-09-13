// Pruebas unitarias de src/lib/consulta.js: manejo de la respuesta de supabase-js y limpieza de formularios.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { datos, uno, limpiar } from '../../src/lib/consulta.js';

test('datos devuelve el arreglo o vacío, y lanza el error', () => {
  assert.deepEqual(datos({ data: [1, 2], error: null }), [1, 2]);
  assert.deepEqual(datos({ data: null, error: null }), []);
  assert.throws(() => datos({ data: null, error: new Error('rls') }), /rls/);
});

test('uno devuelve el registro o null, y lanza el error', () => {
  assert.deepEqual(uno({ data: { id: 1 }, error: null }), { id: 1 });
  assert.equal(uno({ data: null, error: null }), null);
  assert.throws(() => uno({ data: null, error: new Error('x') }), /x/);
});

test('limpiar quita cadenas vacias e undefined pero conserva 0, false y null', () => {
  assert.deepEqual(limpiar({ a: '', b: undefined, c: 0, d: false, e: null, f: 'x' }), {
    c: 0,
    d: false,
    e: null,
    f: 'x',
  });
});
