# Setup de release/deploy — Next.js + pnpm + Prisma → Vercel

Checklist para dejar operativo el flujo de CI, release y deploy en un
proyecto Next.js con pnpm. Requiere que el setup único de acceso de
`release-toolkit` ya esté hecho (ver su README). Los callers apuntan a
`@v1.1.4` y fijan `toolkit_ref: v1.1.4` (deben coincidir). El nombre del
repositorio del toolkit aparece solo en los callers (`uses:` y
`toolkit_repository`): si usas un fork, cámbialo ahí y en ningún otro sitio.

Diferencias con el kit `frontend-vite`: usa pnpm (`pnpm/action-setup@v4`, sin
`npm ci` ni `npx`), solo despliega a producción (sin slots `PRE`/`PRE-TEST`),
no tiene pista de versión de BD y el deploy no necesita etiqueta.

## 0. Requisitos de GitHub (se descubren tarde si se olvidan)

- **El toolkit debe ser legible desde tu repo** (ver el README raíz): con el
  toolkit privado, `release`, `release-preview` y `deploy` fallan en el paso
  «Checkout scripts de release-toolkit».
- **Settings → Actions → General → Workflow permissions → «Allow GitHub Actions
  to create and approve pull requests».** Sin esto el release publica el tag y
  la Release pero falla al abrir el PR de sincronización (el comentario del
  fallo lo indica y el PR se crea a mano).
- **Registro de workflows:** si tras el primer push de un repo nuevo el
  apartado Actions no muestra los workflows, haz un commit que modifique los
  ficheros de `.github/workflows/` (basta un comentario). GitHub no escanea los
  que llegan en el push inicial de un repo vacío.
- **Los tres secretos de Vercel son obligatorios** incluso para rechazar
  órdenes: sin ellos el run de `/deploy` falla al evaluar los secretos, antes
  de leer la orden, y no comenta nada en el issue.

## 1. Copiar estos archivos al proyecto

`.github/` completo (workflows + ISSUE_TEMPLATE), `CHANGELOG.md` y el campo
`"version": "0.0.0"` de `package.json` (fusiónalo con tu `package.json`
real, no lo sobreescribas). El `CHANGELOG.md` debe conservar su cabecera de
6 líneas: el release inserta cada versión justo debajo.

## 2. Revisar `code_paths_regex`

En `release.yml` y `release-preview.yml`. Por defecto cuentan como código:
`src/`, `prisma/`, `next.config.ts`, `package.json`, `pnpm-lock.yaml`,
`tsconfig.json` y `vercel.json`. Un PR que solo toque otras rutas no genera
versión y el PR recibe un comentario que lo indica.

## 3. `vercel.json`: apagar los deploys automáticos por git

```json
{ "git": { "deploymentEnabled": false } }
```

Sin esto, Vercel desplegaría en cada push además del deploy manual del
workflow (publicar no despliega).

## 4. Ramas y protección

- `develop` como rama por defecto; `main` solo recibe merges desde `develop`
  o `hotfix/*`.
- Para que el CI bloquee la fusión de PRs a `develop`/`main` si falla, activa
  protección de rama o un ruleset con el check `ci` obligatorio. **En repos
  privados esto requiere un plan de pago de GitHub** (en repos públicos es
  gratis); sin él, el CI se ejecuta pero no impide fusionar.
- El release hace `push` del commit de versión a `main`: si `main` está
  protegida, permite que `github-actions[bot]` haga bypass.

## 5. Etiquetas (crear una vez con `gh label create`)

```bash
gh label create "release-type/patch" --color 0e8a16
gh label create "release-type/minor" --color fbca04
gh label create "release-type/major" --color d93f0b
```

Un PR `develop → main` lleva exactamente una. Sin etiqueta, o con más de una,
no se versiona y se comenta el motivo. El deploy no usa etiqueta.

## 6. Secrets del repo (Settings → Secrets and variables → Actions)

- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`

## 7. Variables en el proyecto de Vercel (Settings → Environment Variables → Production)

El deploy hace `vercel pull`, así que el build usa las variables del
proyecto en Vercel, no las de GitHub:

- `DATABASE_URL` (pooler de transacciones, puerto 6543, con `?pgbouncer=true&connection_limit=1`), `DIRECT_URL`
- `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_STORAGE_BUCKET`

No hay variables de repo (`gh variable set`) que configurar.

## 8. GitHub Environment

Crea `production` (Settings → Environments). Es el gate del deploy; puedes
añadir revisores obligatorios (el job queda "esperando aprobación").

## 9. Probar

1. Abre un PR `feature/x → develop`: el CI debe pasar.
2. Abre un PR `develop → main` con una etiqueta `release-type/patch`: debe
   aparecer el comentario de vista previa con la versión.
3. Fusiónalo: comprueba el commit de versión, el tag, el GitHub Release y el
   PR de sync a `develop`.
4. Abre un issue con el cuerpo `/deploy vX.Y.Z` (la versión publicada):
   despliega y cierra el issue. Si el tag no existe o no eres el dueño, se
   comenta el motivo y no se despliega. Dos órdenes seguidas: la segunda se
   rechaza con aviso.

## Límites conocidos

- La comprobación de dueño compara con `github.repository_owner`: válido para
  repos de cuenta personal, no para organizaciones.
- `/deploy` en un PR se rechaza con aviso (no hay snapshots).
- Un tercer `/deploy` en cola cancelaría al segundo sin comentario (GitHub
  cancela el pendiente cuando hay otro en la misma cola de `concurrency`).
