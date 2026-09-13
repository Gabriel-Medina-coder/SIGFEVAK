# Área N — <Nombre del área>

> **Documento de contexto del área N.** Fuente de verdad para el equipo y para cualquier agente de código.
> Ante contradicción entre este documento y el código, gana este documento. Ante contradicción con `PLAN.md`, gana `PLAN.md`.
> Ejemplo completo del formato: `docs/area4-nomina/CONTEXTO.md`.

| Campo | Valor |
| --- | --- |
| Proyecto | SIGFEVAK |
| Área | N de 6 — <nombre> |
| Etiqueta de issues | `area:N-<slug>` |
| Prefijo de commits | `areaN:` |
| Reglas de negocio | `RN-AN-01` … |
| Equipo | 5 personas (1 líder + 4 integrantes) |
| Plazo | Domingo 13 a jueves 17 de septiembre de 2026 (5 días de trabajo) |
| Stack | React + Vite, supabase-js, PostgreSQL en Supabase, pnpm (PLAN.md D-01) |
| Versión | 0.1 (borrador) |

---

## 1. Cómo debe usar este documento un agente

1. Este archivo es la única fuente de verdad del área N. Si el código lo contradice, el código se corrige.
2. No inventes tablas, columnas ni valores de enum. Si falta algo, regístralo en la sección 10 y detente.
3. No toques tablas de otras áreas. La sección 3 dice cuáles son de lectura.
4. Todo cambio de esquema es una migración nueva.
5. Cita las reglas `RN-AN-xx` en commits, comentarios y PR.
6. Commits: `areaN: <verbo> <objeto> (RN-AN-xx) #issue`. Sin mención a herramientas de IA.

## 2. Contexto de negocio

<!-- Qué hace la empresa en lo que toca a esta área. Marco legal si aplica. -->

## 3. Alcance

### Dentro del alcance (5 días)

-

### Fuera del alcance

-

### Tablas por nivel de acceso

| Tabla | Acceso del área N | Dueño |
| --- | --- | --- |
| | Escritura total | Área N |
| | Solo lectura | Área M |

## 4. Modelo entidad-relación

```mermaid
erDiagram
```

## 5. Diccionario de datos

### `tabla`

| Columna | Tipo | Nulo | Descripción y regla |
| --- | --- | --- | --- |

### Valores ENUM del área

| Tipo | Valores |
| --- | --- |

## 6. Flujos

```mermaid
flowchart TD
```

## 7. Reglas de negocio

| ID | Regla | Dónde se implementa |
| --- | --- | --- |
| **RN-AN-01** | | |

## 8. DDL y migraciones

```sql
```

## 9. Vistas y contratos con otras áreas

```sql
```

| Área | Dirección | Qué | Vía |
| --- | --- | --- | --- |

## 10. Preguntas abiertas

1.

## 11. Glosario

| Término | Significado en este proyecto |
| --- | --- |
