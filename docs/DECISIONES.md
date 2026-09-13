# Decisiones de arquitectura (ADR)

Cada decisión tiene contexto, opciones, decisión y consecuencias. Una decisión cerrada no se reabre sin una nueva entrada que la reemplace. El detalle largo de cada una está en `PLAN.md` sección 3.

| ID | Decisión | Estado | Fecha |
| --- | --- | --- | --- |
| D-01 | Stack: React + Vite, API de Supabase, PostgreSQL en Supabase, pnpm | Cerrada | 2026-09-11 |
| D-02 | Una sola base de datos compartida; fronteras lógicas por área | Cerrada | 2026-09-11 |
| D-03 | El Área 1 amplía el catálogo del Área 3 con migraciones aditivas | Cerrada | 2026-09-13 |
| D-04 | "Pago automático" del Área 5 = orden de pago + línea de captura + autorización + comprobante. Sin banco real | Cerrada | 2026-09-11 |
| D-05 | Una sola app React con un módulo por área | Cerrada | 2026-09-11 |
| D-06 | Todo en español | Cerrada | 2026-09-11 |
| D-07 | Plazo: equipos del domingo 13 al jueves 17 de septiembre de 2026 (5 días); congelamiento miércoles 16 a las 18:00 | Cerrada | 2026-09-12 |
| D-08 | Cero rastro de IA en commits, PRs, issues y documentos | Cerrada | 2026-09-11 |
| D-09 | Migraciones con nombre `AAAAMMDD_HHMM_aN_descripcion.sql` | Cerrada | 2026-09-11 |
| D-10 | Migraciones aplicadas por la coordinación sin Supabase CLI ni Docker | Cerrada | 2026-09-13 |
| D-11 | Ningún dato es legible sin sesión: vistas con `security_invoker` y sin privilegios para `anon` | Cerrada | 2026-09-13 |
| D-12 | La base de demostración trae dos años de operación simulada con `seed_historico.sql` | Cerrada | 2026-09-13 |

---

## D-01 · Stack tecnológico

**Contexto.** Tres documentos de área proponían stacks distintos (Spring Boot vs Supabase). 31 personas de niveles distintos y 5 días de trabajo.

**Decisión del coordinador.** Frontend React. Backend: la API de Supabase, sin servidor propio. Base de datos PostgreSQL en Supabase, un solo proyecto. Gestor de paquetes pnpm; npm prohibido.

**Derivado.** Vite, JavaScript, Tailwind, react-router, Zod, supabase-js, Supabase CLI para migraciones, Supabase Auth con tabla `usuarios` y `rol`, RLS en todas las tablas, Node 20, Prettier + ESLint en CI, pruebas SQL para triggers, ejecución local en la presentación.

**Consecuencias.** La lógica de negocio crítica vive en funciones y triggers de PostgreSQL. El Área 5 cambia su sección de tecnologías; las áreas 3 y 4 no cambian. No hay carpeta de backend.

## D-02 · Una base, un esquema

**Decisión.** Las seis áreas comparten una base. Cualquier área lee todo; cada área escribe solo en sus tablas. `docs/MODELO_DATOS.md` dice quién es dueño de cada tabla. Las otras áreas consumen vistas, nunca tablas.

## D-03 · Catálogo de productos: Área 1 sobre Área 3

**Contexto.** El Área 3 cerró `productos` con 7 columnas; el Área 1 necesita SKU, lotes, almacenes, órdenes de producción.

**Decisión recomendada.** El Área 1 solo agrega: columnas opcionales en `productos` y `entradas_producto`, tablas nuevas propias. El único cambio en código del Área 3 es la fórmula de capital en `fn_entrada_producto`, compatible hacia atrás porque flete e impuestos tienen default 0. Detalle en `PLAN.md` D-03.

**Cerrada el domingo 13 (I-01, issues #1 y #20).** `entradas_producto` nació con `flete_unitario`, `impuestos_unitarios` y `tipo_cambio` en la migración del Área 3, y `fn_entrada_producto` y `v_entradas_area1` ya usan la fórmula. El Área 1 agregó el resto de sus columnas y tablas sin tocar las del Área 3.

## D-04 · Alcance de "pago automático"

**Decisión.** Se genera la orden de pago, la línea de captura, el flujo de autorización y el registro del comprobante. No hay integración bancaria.

## D-05 · Un solo frontend

**Decisión.** Una app React con menú común y una carpeta por área en `src/modules/`.

## D-06 · Idioma

**Decisión.** Español en código de negocio, commits, issues y docs. APIs de librerías en inglés.

## D-07 · Plazo

**Decisión.** La coordinación prepara el repo el sábado 12. Los equipos trabajan del domingo 13 al jueves 17 de septiembre de 2026, 5 días. Congelamiento de alcance el miércoles 16 a las 18:00. Entrega el jueves 17. El viernes 18 no forma parte del plan. Corrige la versión anterior, que tenía los nombres de día corridos y la entrega un día tarde.

## D-08 · Cero rastro de IA

**Decisión.** Ningún commit, PR, issue, comentario ni documento entregable menciona herramientas de IA. Los coautores humanos (`Co-Authored-By: Nombre <usuario@users.noreply.github.com>`) sí se permiten y sirven para reconocer a quien participó en un bloque. Se aplica con `.claude/settings.json` (atribución apagada, hook), `.githooks/commit-msg` (para cualquier herramienta) y revisión del líder. Usar IA sí está permitido; que quede registrado, no.

## D-09 · Nombre de migraciones

**Decisión.** `AAAAMMDD_HHMM_aN_descripcion.sql`, con `a00` para lo compartido del coordinador. Nunca se edita una migración aplicada. El workflow `sql-lint.yml` lo verifica.

## D-10 · Migraciones sin CLI

**Contexto.** Instalar Supabase CLI y Docker en 31 máquinas no cabe en 5 días, y la base ya vive en un proyecto de Supabase en la nube.

**Decisión.** Las migraciones son archivos SQL en `supabase/migrations/` con el formato de D-09. La coordinación las aplica y las registra con `node supabase/sql.mjs migrate <archivo>`, que usa la API de administración de Supabase y el token de `.env.supabase` (ignorado por git). El mismo script corre seeds y pruebas SQL.

**Consecuencias.** Nadie más necesita el token. Quien escribe una migración la entrega en su PR; se aplica al mergear. `supabase db push` y `supabase db reset` ya no forman parte del flujo.

## D-11 · Acceso solo con sesión

**Contexto.** Las vistas de PostgreSQL corren con los permisos de su dueño y se saltan el RLS de las tablas. Con la llave pública, sin iniciar sesión, se leían las 42 vistas, incluidos nómina, RFC y CLABE, y se ejecutaban funciones como `fn_marcar_vencidas`.

**Decisión.** La migración `20260913_0800_a00_seguridad_anon.sql` pone `security_invoker` en todas las vistas y quita al rol `anon` todo privilegio sobre tablas, vistas, secuencias y funciones, también para lo que se cree después. Toda vista nueva se crea con `WITH (security_invoker = true)`.

**Consecuencias.** Sin sesión no se lee ni se ejecuta nada. Con sesión, cada vista respeta el RLS de sus tablas. `supabase/tests/coord/seguridad.sql` falla si una vista o una función vuelve a quedar expuesta; se corre después de cada migración. En Supabase el privilegio por defecto no evita que PostgreSQL dé ejecución pública a cada función nueva; por eso toda migración que crea funciones termina con el `REVOKE` y el `GRANT` de `20260913_0910_a00_permisos_funciones_nuevas`.

## D-12 · Dos años de operación en la base de demostración

**Contexto.** Con solo los seeds de área la app muestra un mes de datos: gráficas vacías, kardex de dos renglones y nóminas sin historia. Así no se ve cómo se comporta el sistema con uso real ni se prueban listas largas.

**Decisión.** `supabase/seed/seed_historico.sql` simula la operación de sep 2024 a ago 2026 y se carga después de todas las migraciones y seeds de área. Todo entra por los triggers con fechas explícitas: compras, unas 960 facturas cobradas o canceladas, conciliaciones, 23 nóminas mensuales cerradas, obligaciones fiscales cerradas, pedimentos, licencias vencidas, campañas e investigaciones. Lo comprado cada mes es lo vendido ese mes, así el stock final y los ejemplos de los seeds no cambian. Es determinista e idempotente. Los parámetros legales y fiscales de 2024 y 2025 entran con su vigencia.

**Consecuencias.** Las siete suites de `supabase/tests/` siguen pasando sobre la base completa. Los ids ya no siguen el orden del calendario, así que las pantallas ordenan por fecha. Los folios de las facturas históricas son posteriores a los de los seeds de área.
