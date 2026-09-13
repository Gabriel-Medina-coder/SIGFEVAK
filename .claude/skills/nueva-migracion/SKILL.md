---
name: nueva-migracion
description: Crea un archivo de migración de Supabase con el nombre y el encabezado que exige el proyecto
disable-model-invocation: true
arguments: [area, descripcion]
allowed-tools: Bash(date *) Bash(ls *) Read Write Glob
---

Crea una migración nueva para el área $area con la descripción "$descripcion".

1. Obtén la fecha y hora actual en formato `AAAAMMDD_HHMM` (por ejemplo con `date +%Y%m%d_%H%M`).
2. Convierte la descripción a `snake_case` sin acentos ni espacios, máximo 5 palabras.
3. El nombre del archivo es `supabase/migrations/<fecha>_a$area_<descripcion>.sql`. Para lo compartido del coordinador el área es `00`.
4. Verifica con `ls supabase/migrations/` que no exista otra migración con el mismo nombre y que la nueva quede alfabéticamente después de las existentes.
5. Escribe el archivo con este encabezado y nada más (el cuerpo lo escribe la persona o se pide en un paso aparte):

   ```sql
   -- Área $area · Issue #___ · RN-A$area-__
   -- Qué hace: $descripcion
   -- Reglas: nunca editar esta migración después de aplicarla; un cambio es una migración nueva.

   ```

6. Recuerda en la respuesta:
   - Tablas y columnas en `minusculas_con_guion_bajo`, en español.
   - Toda tabla nueva activa RLS y define la política mínima para `authenticated`.
   - Toda función o trigger lleva comentario con la RN que implementa.
   - Nunca escribir `productos.stock` directamente.

No apliques la migración ni modifiques otras migraciones.
