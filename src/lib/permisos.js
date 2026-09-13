// Qué puede hacer cada rol en cada módulo (docs/FLUJO_APP.md sección 1).
// Todos los usuarios autenticados ven las siete pantallas; escribir depende del rol.

export const MODULOS = [
  {
    id: 'resumen',
    ruta: '/app',
    etiqueta: 'Resumen General',
    subtitulo: 'Coordinación · KPI de las seis áreas',
  },
  {
    id: 'entradas',
    ruta: '/app/entradas',
    etiqueta: 'Entradas de Producción',
    subtitulo: 'Área 1 · proveedores, entradas y producción',
  },
  {
    id: 'contable',
    ruta: '/app/contable',
    etiqueta: 'Registro Contable',
    subtitulo: 'Área 2 · comercializadores, facturas y cobros',
  },
  {
    id: 'inventario',
    ruta: '/app/inventario',
    etiqueta: 'Base de Productos',
    subtitulo: 'Área 3 · catálogo, kardex y conciliación',
  },
  {
    id: 'nomina',
    ruta: '/app/nomina',
    etiqueta: 'Nómina y Personal',
    subtitulo: 'Área 4 · agentes, metas, periodos y recibos',
  },
  {
    id: 'regulacion',
    ruta: '/app/regulacion',
    etiqueta: 'Regulación y Pagos',
    subtitulo: 'Área 5 · obligaciones, alertas y pagos',
  },
  {
    id: 'marketing',
    ruta: '/app/marketing',
    etiqueta: 'Marketing',
    subtitulo: 'Área 6 · campañas, costos e investigación',
  },
];

const ESCRITURA = {
  ADMINISTRADOR: ['entradas', 'contable', 'inventario', 'nomina', 'regulacion', 'marketing'],
  ALMACEN: ['entradas', 'inventario'],
  CONTADOR: ['contable', 'regulacion'],
  GERENTE_VENTAS: ['nomina'],
  AUTORIZADOR: ['nomina', 'regulacion'],
  COMERCIO_EXTERIOR: ['regulacion'],
  MARKETING: ['marketing'],
  CAPTURISTA: [],
};

export const ETIQUETA_ROL = {
  ADMINISTRADOR: 'Administrador',
  ALMACEN: 'Almacén',
  CONTADOR: 'Contador',
  GERENTE_VENTAS: 'Gerente de ventas',
  AUTORIZADOR: 'Autorizador financiero',
  COMERCIO_EXTERIOR: 'Comercio exterior',
  MARKETING: 'Marketing',
  CAPTURISTA: 'Capturista',
};

export function puedeEscribir(rol, modulo) {
  return (ESCRITURA[rol] ?? []).includes(modulo);
}

export function moduloPorRuta(pathname) {
  const exacto = MODULOS.find((m) => m.ruta === pathname);
  if (exacto) return exacto;
  return (
    MODULOS.filter((m) => m.id !== 'resumen').find((m) => pathname.startsWith(m.ruta)) ?? MODULOS[0]
  );
}
