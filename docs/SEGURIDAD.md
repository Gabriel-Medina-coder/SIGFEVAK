# Seguridad · Auditoría y controles

Revisión de seguridad de SIGFEVAK siguiendo la guía OWASP (WSTG y Top 10). Las pruebas se hicieron contra la instancia real (Supabase en la nube y el servidor de Vite) atacando con la llave pública `anon` y con cuentas de cada rol, tal como lo haría un atacante con la app en la mano. Fecha: 13 sep 2026.

## Modelo de amenazas

- La app es un frontend estático que habla directo con la API de Supabase (PostgREST). La llave `anon` es pública (viaja en el bundle), así que **la seguridad no puede vivir en el frontend**: cualquiera puede llamar a la API con esa llave y un token de sesión.
- La defensa real está en la base: RLS (Row Level Security) por tabla, validación de reglas en triggers, y que sin sesión no se lea ni ejecute nada.

## Resultado de las pruebas

### Lo que ya estaba bien

| Prueba (OWASP) | Resultado |
| --- | --- |
| Acceso anónimo (sin login) a tablas, vistas y funciones | Bloqueado (HTTP 401) en todo. D-11 |
| Saltar el login por URL (`/app/...` sin sesión) | Redirige al login; la API no devuelve datos |
| JWT manipulado (`alg:none`, rol falso `service_role`) | Rechazado (HTTP 401): Supabase verifica la firma |
| Escalar a ADMINISTRADOR (cambiar el propio rol en `usuarios`) | Bloqueado: solo ADMINISTRADOR escribe `usuarios` |
| DELETE físico de una obligación | Se convierte en baja lógica (RN-A5-22) |
| Contraseñas | Las guarda Supabase Auth con bcrypt; nunca viajan en la URL |
| Secretos en el repo | Solo `.env.example`; `.env` y el token de administración `.env.supabase` están ignorados y no se sirven |
| XSS | React escapa por defecto; no hay `dangerouslySetInnerHTML`, `eval` ni `innerHTML` |
| SQL Injection | No hay SQL crudo desde el frontend; PostgREST y `supabase-js` parametrizan |

### Huecos encontrados y cerrados

Todos eran de **control de acceso roto** (OWASP A01): la autorización por módulo solo estaba en el frontend (`puedeEscribir` oculta botones), pero la RLS dejaba a cualquier usuario con sesión escribir en casi cualquier tabla.

| Hueco | Impacto | Arreglo |
| --- | --- | --- |
| Un usuario de bajo privilegio (almacén) leía toda la tabla `usuarios` (correos, roles, uuid) | Habilita suplantación | `usuarios`: cada quien ve solo su fila; ADMINISTRADOR ve todas (migración 0930) |
| Cualquier usuario podía cambiar las tasas legales y fiscales (`parametros_*`) | Corrompe todo el cálculo de nómina e impuestos | Escritura de parámetros y catálogos solo ADMINISTRADOR (0930) |
| Cualquier usuario escribía `productos.stock/volumen/capital` directo | Rompe RN-A3-06; inventario y capital falsos | Guard en la base: esas columnas solo las mueven los triggers de entrada, salida y ajuste (0930) |
| Un usuario firmaba pasos de nómina u obligaciones a nombre de otro | Salta la separación de funciones | La base exige que quien registra el paso sea el usuario conectado y con el rol correcto (0930) |
| Cualquier usuario escribía tablas de otras áreas (p. ej. almacén creaba campañas) | Manipulación de datos ajenos | RLS por rol: cada tabla solo la escribe el rol de su módulo, más ADMINISTRADOR (0940) |

Confirmado tras el arreglo: almacén y contador reciben **HTTP 403** al escribir fuera de su módulo; el contador sí crea facturas (su módulo) y no campañas (marketing). Las siete suites SQL y el flujo completo en la app (26 de 26 comprobaciones) siguen pasando.

### Riesgo residual aceptado

- **Lectura amplia entre áreas.** Cualquier usuario con sesión puede *leer* casi todas las tablas y vistas. Es una decisión de negocio (comercializadora chica: todos ven la operación); las lecturas de contrato entre áreas la necesitan. Los datos más sensibles siguen protegidos: `usuarios` es por fila y sin sesión no se lee nada.
- **Cabeceras en producción.** El servidor de Vite (dev y preview) ya manda `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy` y `Permissions-Policy`; en `preview` agrega CSP y HSTS. Un hosting real debe mandar estas cabeceras (y CSP) desde el servidor.

## Controles vigentes

- **Sin sesión, nada.** Vistas con `security_invoker` y sin privilegios para `anon` (D-11, migración 0800). Prueba automática: `supabase/tests/coord/seguridad.sql`.
- **Autorización en la base, no en botones.** RLS por rol reflejando `src/lib/permisos.js` (migraciones 0930 y 0940).
- **Reglas de negocio en triggers y CHECK**, no solo en el frontend (separación de funciones, topes, estados).
- **Auditoría.** `bitacora_nomina` y `bitacora_fiscal` registran cada cambio sensible.
- **Cero atribución de secretos en el repo**; el token de administración solo en `.env.supabase` (ignorado).

## Cómo reproducir las pruebas

Las pruebas de acceso están en `supabase/tests/coord/seguridad.sql` (falla si algo queda legible o ejecutable sin sesión). Las pruebas activas contra la API (anónimo, escalada, entre módulos, tasas, stock, JWT) se corren con el guion de pentest del entorno de trabajo; el procedimiento está en `docs/QA.md`.
