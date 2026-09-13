# Empieza aquí

Guía de arranque para líderes e integrantes. Lee esto primero; en quince minutos sabes qué hacer y dónde está todo.

## En una frase

Construimos una sola app para una comercializadora con seis módulos, uno por equipo, sobre una base de datos compartida, del domingo 13 al jueves 17 de septiembre. Todo entra por pull request y todo queda documentado.

## Cómo se trabaja ahora

La coordinación construye las seis áreas y el líder de cada una aparece como coautor de los commits de su área. Tú puedes contribuir por pull request cuando quieras; el flujo de abajo sirve para eso.

## Si eres integrante

1. **Lee tu área.** `docs/areaN-*/CONTEXTO.md` es la fuente de verdad: qué tablas son tuyas, qué reglas de negocio aplican, qué pantallas se esperan. Léelo completo una vez; después consúltalo por sección.
2. **Prepara tu máquina** con [`CONTRIBUTING.md`](../CONTRIBUTING.md): fork, clonar, `upstream`, el hook de commit. Diez minutos.
3. **Tu primer PR** es agregar tu nombre a [`EQUIPOS.md`](EQUIPOS.md). Sirve para probar el flujo sin riesgo.
4. **Toma un issue** de tu área con la etiqueta `estado:disponible`. Comenta "lo tomo" y tu líder te lo asigna. Empieza por los de `nivel:inicial` o `buena-primera-tarea` si es tu primera vez.
5. **Trabaja en tu rama** `areaN/<issue>-<slug>`, solo dentro de las carpetas de tu área. Commits en español con el formato `areaN: verbo objeto (RN-AN-xx) #issue`.
6. **Abre el PR** con la plantilla completa y evidencia (captura o salida de consola) guardada en `docs/areaN-*/evidencias/`. Tu líder revisa el mismo día.
7. **Si usas IA**, lee [`GUIA_IA.md`](GUIA_IA.md). Está permitido; lo que no está permitido es que quede rastro en commits o PRs.

Qué no hacer: tocar archivos de otra área, editar una migración existente, escribir `productos.stock` a mano, usar `npm`, subir `.env`.

## Si eres líder

1. **Domingo 13, con tu equipo:** lean el `CONTEXTO.md` juntos, aplica la evaluación de habilidades de `docs/areaN-*/EVALUACION.md` y asigna roles internos. Revisa `TAREAS.md`: los issues ya están en GitHub con ese desglose; ajusta lo que tu equipo vea distinto.
2. **Cierra tus integraciones** el mismo domingo. `docs/MODELO_DATOS.md` lista qué le pides a otras áreas y qué te piden a ti (I-01 a I-13). Cada acuerdo se escribe en su issue de integración.
3. **Cada día:** revisa los PRs de tu área en menos de 6 horas, actualiza `ESTADO.md` al cierre y llena la evaluación del día. Si alguien va atrasado, reasigna y anótalo en el registro de control de cambios.
4. **Miércoles 16 a las 18:00** se cierra el alcance. Después solo correcciones.
5. **Jueves 17 antes de las 14:00:** entrega `REPORTE_FINAL.md` con la plantilla de `docs/plantillas/`.

Con Claude Code, la skill `/revisar-pr <número>` te da la lista de observaciones de un PR en un minuto.

## Mapa de documentos

| Quieres saber | Lee |
| --- | --- |
| Qué se construye y por qué | [`PLAN.md`](../PLAN.md) |
| Cómo queda la app de punta a punta y qué demuestra cada área | [`FLUJO_APP.md`](FLUJO_APP.md) |
| Fechas, hitos y alcance mínimo | [`CRONOGRAMA.md`](CRONOGRAMA.md) |
| Qué tablas son de quién, vistas entre áreas, integraciones pendientes | [`MODELO_DATOS.md`](MODELO_DATOS.md) |
| Cómo deben verse las pantallas | [`GUIA_ESTILO.md`](GUIA_ESTILO.md) y `referencia-ui/` |
| Git paso a paso y problemas comunes | [`GUIA_GIT.md`](GUIA_GIT.md) |
| Decisiones ya tomadas que no se reabren | [`DECISIONES.md`](DECISIONES.md) |
| Términos del negocio | [`GLOSARIO.md`](GLOSARIO.md) |
| Quién es quién | [`EQUIPOS.md`](EQUIPOS.md) |

## Cuando algo no funciona

- Una consulta regresa vacío teniendo datos: es RLS, falta la política para `authenticated`.
- El stock se duplicó: alguien escribió `productos.stock` a mano; solo los triggers lo tocan.
- El commit fue rechazado: el mensaje tiene rastro de IA o el prefijo está mal.
- No sabes si algo está permitido: pregunta a tu líder antes de hacerlo, y si es entre áreas, abre un issue de integración.
