# release-toolkit

Flujo de versión, changelog, release y deploy — una sola vez, reusable desde
cualquier proyecto nuevo vía [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
de GitHub Actions (`workflow_call`).

## Por qué existe

Cada proyecto nuevo necesitaba re-crear a mano el mismo sistema de versionado
por labels (`release-type/*`), changelog automático, deploy manual controlado
(`/deploy vX.Y.Z`, snapshots `PRE`/`PRE-TEST`) y, si tiene BD, una línea de
versión independiente (`db-vX.Y.Z`). Este repo centraliza esa lógica: los
proyectos solo tienen un archivo "caller" de ~15 líneas por workflow que la
invoca.

## Setup único de la cuenta (una sola vez, no por proyecto)

Los reusables traen sus scripts con un `actions/checkout` de este repo. Eso lo
hace el `GITHUB_TOKEN` del repo que llama, que **no puede leer el contenido de
un repo privado de otro**: con este repo privado, `release`, `release-preview` y
`deploy` fallan con «repository not found» (solo los workflows que no hacen
checkout, como `ci-*`, funcionan). Dos opciones:

- **Recomendada: repo público.** Solo contiene workflows y scripts, sin secretos.
  Es lo que usa Jabbcode/release-toolkit y no necesita ningún paso por proyecto.
- Repo privado: además del ajuste **Settings → Actions → General → Access**
  ("Accessible from repositories owned by the user", que permite el `uses:`),
  hace falta un token de lectura en cada proyecto y pasarlo al checkout. Este
  repo no lo implementa.

## Workflows reusables (`.github/workflows/`)

| Workflow | Qué hace | Quién lo llama |
|---|---|---|
| `ci-node.yml` | install + typecheck + test + lint (opcional) + build | todos |
| `release.yml` | version + changelog + tag + GitHub Release + PR de sync, para código y (opcional) BD | todos |
| `release-preview.yml` | comenta y renombra el PR con la versión que se publicaría | todos |
| `deploy-render.yml` | deploy manual a Render (prod + snapshots) | proyectos backend en Render |
| `deploy-vercel.yml` | deploy manual a Vercel (prod + snapshots) | proyectos frontend en Vercel |
| `migrate-prisma.yml` | `prisma migrate deploy` manual (prod + snapshots) | proyectos con Prisma |
| `ci-next.yml` | pnpm install + prisma generate/validate + typecheck + lint + test + build | proyectos Next.js con pnpm |
| `release-next.yml` | version + changelog + tag + GitHub Release + PR de sync (solo código; valida etiqueta y tag antes de publicar) | proyectos Next.js con pnpm |
| `release-preview-next.yml` | comenta en el PR la versión que se publicaría, o el motivo por el que no | proyectos Next.js con pnpm |
| `deploy-vercel-next.yml` | deploy manual a producción en Vercel con `/deploy vX.Y.Z` en un issue (solo el dueño, sin slots) | proyectos Next.js con pnpm |

Cada workflow documenta sus `inputs`/`secrets` en su propia cabecera de
comentarios. Los scripts en `.github/scripts/` (`bump-version.sh`,
`build-changelog.sh`, `changed-paths.sh`, `resolve-release-type.sh`,
`parse-deploy-command.sh`) son genéricos y los usan internamente vía un
segundo `checkout` de este repo; `test-scripts.sh` prueba los dos últimos
(`bash .github/scripts/test-scripts.sh`).

## `templates/` — caller kits por stack

- `templates/backend-node/` — Express/Prisma → Render
- `templates/frontend-vite/` — React/Vite → Vercel
- `templates/frontend-next/` — Next.js/Prisma con pnpm → Vercel (solo producción)

Cada carpeta es lo que copias a un proyecto nuevo: los callers ya apuntan a
este toolkit, más `CHANGELOG.md`, `package.json` mínimo y un `README.md` con
el checklist de setup (labels, secrets, vars, Environments) para ese stack.
Ver la skill `new-project-cicd` para hacerlo guiado.

## Versionado del propio toolkit

Tags exactos (`v1.0.0`, `v1.1.0`, `v1.1.1`, `v1.1.2`, `v1.1.3`, ...) — sin tag flotante `v1`. Cada caller
fija el tag exacto en `uses: .../workflow.yml@vX.Y.Z` **y** en el input
`toolkit_ref` (deben coincidir: el segundo controla de qué ref se traen los
scripts). Para actualizar un proyecto a una versión nueva del toolkit,
edita esos dos valores a mano en sus workflows.
