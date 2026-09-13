---
name: contexto-area
description: Resume el contexto de un área (tablas de escritura y lectura, reglas de negocio, vistas de contrato y preguntas abiertas) para orientarse antes de pedir código
disable-model-invocation: true
arguments: [area]
allowed-tools: Read Grep Glob
---

Carga y resume el contexto del área $area.

1. Localiza `docs/area$area-*/CONTEXTO.md` y léelo completo. Si el archivo todavía es un borrador o no está en el formato común, dilo al inicio.
2. Responde con estas secciones, cortas y en español:
   - **Responsabilidad del área** en dos líneas.
   - **Tablas de escritura** (propias) y **tablas de lectura** (de otras áreas), en una tabla.
   - **Reglas de negocio** `RN-A$area-xx`: identificador y una línea cada una.
   - **Vistas de contrato** que esta área publica y para quién.
   - **Dependencias** de otras áreas que aún no están resueltas.
   - **Preguntas abiertas** tal como están en el documento.
3. Termina con una línea: "Antes de programar, confirma con el líder del área si alguna pregunta abierta afecta tu issue."

No modifiques ningún archivo.
