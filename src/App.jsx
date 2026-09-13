import { lazy, Suspense } from 'react';
import { Route, Routes } from 'react-router-dom';
import Layout from '@/components/Layout';
import { Cargando } from '@/components/Formulario';
import Landing from '@/paginas/Landing';
import Login from '@/paginas/Login';
import RequiereSesion from '@/paginas/RequiereSesion';
import NoEncontrado from '@/paginas/NoEncontrado';

// Un módulo por ruta (docs/GUIA_ESTILO.md sección 7). Cada área es dueña de su carpeta en src/modules/.
const Resumen = lazy(() => import('@/modules/resumen/Resumen'));
const Entradas = lazy(() => import('@/modules/area1-entradas/Entradas'));
const Contable = lazy(() => import('@/modules/area2-contabilidad/Contable'));
const Inventario = lazy(() => import('@/modules/area3-inventario/Inventario'));
const Nomina = lazy(() => import('@/modules/area4-nomina/Nomina'));
const Regulacion = lazy(() => import('@/modules/area5-fiscal/Regulacion'));
const Marketing = lazy(() => import('@/modules/area6-marketing/Marketing'));

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route element={<RequiereSesion />}>
        <Route path="/app" element={<Layout />}>
          <Route
            index
            element={
              <Suspense fallback={<Cargando />}>
                <Resumen />
              </Suspense>
            }
          />
          <Route
            path="entradas"
            element={
              <Suspense fallback={<Cargando />}>
                <Entradas />
              </Suspense>
            }
          />
          <Route
            path="contable"
            element={
              <Suspense fallback={<Cargando />}>
                <Contable />
              </Suspense>
            }
          />
          <Route
            path="inventario"
            element={
              <Suspense fallback={<Cargando />}>
                <Inventario />
              </Suspense>
            }
          />
          <Route
            path="nomina"
            element={
              <Suspense fallback={<Cargando />}>
                <Nomina />
              </Suspense>
            }
          />
          <Route
            path="regulacion"
            element={
              <Suspense fallback={<Cargando />}>
                <Regulacion />
              </Suspense>
            }
          />
          <Route
            path="marketing"
            element={
              <Suspense fallback={<Cargando />}>
                <Marketing />
              </Suspense>
            }
          />
        </Route>
      </Route>
      <Route path="*" element={<NoEncontrado />} />
    </Routes>
  );
}
