# Setup de release/deploy — frontend React/Vite → Vercel

Checklist para dejar operativo el flujo de release y deploy en un proyecto
nuevo. Requiere que el setup único de acceso de `release-toolkit` ya esté
hecho (ver su README).

## 1. Copiar estos archivos al proyecto

`.github/` completo (workflows + ISSUE_TEMPLATE), `CHANGELOG.md`, y el
campo `"version": "0.0.0"` de `package.json` (fusiónalo con tu
`package.json` real, no lo sobreescribas).

## 2. Revisar `code_paths_regex`

En `.github/workflows/release.yml` y `release-preview.yml`: ajusta la regex
a la estructura real del proyecto.

## 3. `vercel.json`: apagar los deploys automáticos por git

```json
{ "git": { "deploymentEnabled": false } }
```

Sin esto, Vercel desplegaría en cada push además del deploy manual del
workflow.

## 4. Ramas

- `develop` como rama por defecto del repo.
- `main` protegida — solo recibe merges desde `develop` o `hotfix/*`.

## 5. Labels (crear una vez con `gh label create`)

```bash
gh label create "release-type/patch" --color 0e8a16
gh label create "release-type/minor" --color fbca04
gh label create "release-type/major" --color d93f0b
gh label create "deploy" --color 1d76db
```

## 6. Secrets del repo

- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`

## 7. Variables del repo (`gh variable set`)

- `VITE_API_URL_PROD` (o el nombre que pases en `api_url_prod_var`)
- `URL_PRE`, `URL_PRE_TEST` — URL de la API del backend de cada slot

## 8. Alias fijos en Vercel

Crea los dominios `alias_pre` / `alias_pre_test` que pusiste en
`deploy-version.yml` (Vercel → Project → Domains) para que el workflow los
re-aliase en cada snapshot.

## 9. GitHub Environment

Crea `production` (Settings → Environments) — es el gate de
`deploy-vercel.yml` para el deploy a producción.

## 10. Probar

1. Abre un PR `feature/x → develop`, mergéalo.
2. Abre un PR `develop → main` con label `release-type/patch` — comprueba
   que el título cambie a "Prepare Release vX.Y.Z" y aparezca el comentario
   de vista previa.
3. Mergéalo — comprueba el tag, el GitHub Release (con link al CHANGELOG) y
   el PR de sync "Sync release vX.Y.Z to develop".
4. Abre un issue con label `deploy` y cuerpo `/deploy vX.Y.Z` — comprueba el
   deploy a Vercel.
