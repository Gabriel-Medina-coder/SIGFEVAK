# Calidad y pruebas (QA)

Cómo se verifica SIGFEVAK antes de cada entrega y qué debe estar en verde. Nada de esto instala herramientas: todo corre con lo que ya trae el proyecto (pnpm, Node y `supabase/sql.mjs`).

## Niveles de prueba

| Nivel | Qué prueba | Cómo se corre | Dónde vive |
| --- | --- | --- | --- |
| Unitarias | Funciones puras del frontend (formato de montos y fechas, matriz de permisos por rol, manejo de respuestas) | `pnpm test` | `tests/unidad/*.test.js` (runner nativo `node --test`, sin dependencias) |
| SQL por área | Triggers, funciones y reglas de negocio de cada área; cada bloque lanza excepción si la regla no se cumple, dentro de una transacción que se revierte | `node supabase/sql.mjs file supabase/tests/areaN/pruebas_areaN.sql` | `supabase/tests/areaN/` |
| Seguridad | Que nada sea legible ni ejecutable sin sesión (D-11) | `node supabase/sql.mjs file supabase/tests/coord/seguridad.sql` | `supabase/tests/coord/` |
| Pentest de acceso | Ataques por la API con la llave pública y cuentas de cada rol (anónimo, escalada, entre módulos, tasas, stock, JWT) | Guion del entorno de trabajo; ver `docs/SEGURIDAD.md` | fuera del repo |
| Punta a punta | El flujo completo de las seis áreas en la app real (Chrome), con dos años de datos, verificando cifras y sin errores de consola | Recorrido grabado; evidencia en `docs/HISTORIA_FLUJO.md` | `docs/*/evidencias/` |
| Estático | Formato y lint | `pnpm lint` | Prettier + oxlint |
| Compilación | Que compile para producción | `pnpm build` | Vite |

## Criterios de aceptación (definición de "listo")

Una entrega está lista cuando, en este orden, todo pasa:

1. `pnpm lint` sin advertencias.
2. `pnpm test` con todas las unitarias en verde.
3. `pnpm build` sin errores.
4. Las siete suites SQL (`area1..6` y `coord/seguridad`) se ejecutan sin excepción.
5. El pentest de acceso: acceso anónimo, JWT falso, escalada y escrituras entre módulos, todos bloqueados (ver `docs/SEGURIDAD.md`).
6. El flujo de punta a punta en la app: 26 de 26 comprobaciones y consola sin errores.

## Métricas de la última medición (13 sep 2026)

| Métrica | Valor |
| --- | --- |
| Advertencias de lint | 0 |
| Pruebas unitarias | 17, todas en verde |
| Suites SQL | 7, todas en verde |
| Migraciones aplicadas | 37 |
| Comprobaciones de punta a punta | 26 de 26 |
| Errores de consola en el recorrido | 0 |
| Huecos de seguridad altos abiertos | 0 (cerrados en las migraciones 0930 y 0940) |
| Cobertura de reglas de negocio | cada `RN-AN-xx` con prueba SQL en su área |

## Procedimiento por cada cambio (checklist del líder)

1. Trabajar solo en las carpetas del área (`AGENTS.md` regla 3).
2. Citar la regla `RN-AN-xx` en el commit y en el código.
3. Antes de proponer el PR: `pnpm lint`, `pnpm test`, `pnpm build` y la suite SQL del área.
4. Cerrar cada issue con evidencia en `docs/areaN/evidencias/`.
5. Si el cambio toca la base, correr también `seguridad.sql`.
6. Actualizar `ESTADO.md` del área.
