# Guía de Git para el proyecto

Complementa a `CONTRIBUTING.md`, que tiene el flujo resumido. Aquí está el porqué y los problemas comunes.

## Conceptos en una línea

- **Repo original (`upstream`)**: `Gabriel-Medina-coder/SIGFEVAK`. Solo los líderes y el coordinador escriben ahí.
- **Tu fork (`origin`)**: tu copia en tu cuenta de GitHub. Ahí subes tus ramas.
- **`main`**: la rama protegida. Solo entra por PR aprobado por el líder del área.
- **Rama de trabajo**: `areaN/<issue>-<slug>`, una por issue, vive en tu fork.

## Configuración inicial (una vez)

```text
git clone https://github.com/<tu-usuario>/SIGFEVAK.git
cd SIGFEVAK
git remote add upstream https://github.com/Gabriel-Medina-coder/SIGFEVAK.git
git config core.hooksPath .githooks
git config user.name "Tu Nombre"
git config user.email "tu-correo@ejemplo.com"
```

Verifica con `git remote -v`: debes ver `origin` (tu fork) y `upstream` (el original).

## Ciclo por issue

```text
git fetch upstream
git switch main
git merge --ff-only upstream/main
git switch -c area3/42-trigger-conciliacion
# ... trabajas ...
git add <archivos>
git commit -m "area3: agrega trigger de conciliación (RN-A3-07) #42"
git push -u origin area3/42-trigger-conciliacion
```

Luego abres el PR desde GitHub: base `Gabriel-Medina-coder/SIGFEVAK:main`, compare `tu-usuario:area3/42-...`.

## Si el líder pide cambios

Haz los cambios en la misma rama, commit y `git push`. El PR se actualiza solo.

## Si `main` avanzó mientras trabajabas

```text
git fetch upstream
git rebase upstream/main
git push --force-with-lease
```

`--force-with-lease` es seguro en tu propia rama de tu fork. Nunca lo uses en `main`.

## Problemas comunes

| Síntoma | Causa | Solución |
| --- | --- | --- |
| "commit-msg hook rechazó mi commit" | El mensaje tiene rastro de IA o prefijo inválido | Corrige el mensaje: `areaN: verbo objeto #issue` |
| El PR muestra cambios que no hice | Tu `main` está atrasado o hiciste la rama desde otra rama | `git rebase upstream/main` |
| Conflicto al hacer rebase | Dos personas tocaron el mismo archivo | Resuelve en el editor, `git add`, `git rebase --continue`. Si es una migración, la tuya debe quedar con timestamp posterior |
| "Permission denied" al hacer push | Estás empujando a `upstream` en vez de a `origin` | `git push -u origin <rama>` |
| Aparece `package-lock.json` | Usaste npm | Bórralo, `pnpm install`, y no subas el lock de npm |
| Subí `.env` por error | No estaba en `.gitignore` local | Avisa al coordinador de inmediato; la llave se rota |

## Lo que nunca se hace

- Push directo a `main`.
- `git push --force` a `main` o a una rama de otra persona.
- Editar una migración ya aplicada.
- Commits con `Co-Authored-By` de herramientas de IA.
- Mezclar dos issues en una rama.
