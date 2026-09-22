# Setup de release/deploy — backend Node/Prisma → Render

Checklist para dejar operativo el flujo de release y deploy en un proyecto
nuevo. Requiere que el setup único de acceso de `release-toolkit` ya esté
hecho (ver su README).

## 1. Copiar estos archivos al proyecto

`.github/` completo (workflows + ISSUE_TEMPLATE), `CHANGELOG.md`,
`CHANGELOG-DB.md` (bórralo si el proyecto no tiene BD versionada), y el
campo `"version": "0.0.0"` de `package.json` (fusiónalo con tu
`package.json` real, no lo sobreescribas).

Si el proyecto no tiene base de datos: borra `CHANGELOG-DB.md`,
`.github/workflows/migrate.yml`, `.github/ISSUE_TEMPLATE/migrate-db.md`, y
quita `db_paths_regex` de `release.yml`/`release-preview.yml`.

## 2. Revisar los `code_paths_regex` / `db_paths_regex`

En `.github/workflows/release.yml` y `release-preview.yml`: ajusta las
regex a la estructura real del proyecto (nombres de carpetas, si usa
`render.yaml`, etc.). En `deploy-version.yml`: reemplaza `prod_url`.

## 3. Ramas

- `develop` como rama por defecto del repo (los triggers de
  `issue_comment`/`issues` solo son operativos en la rama por defecto).
- `main` protegida — solo recibe merges desde `develop` o `hotfix/*`.

## 4. Labels (crear una vez con `gh label create`)

```bash
gh label create "release-type/patch" --color 0e8a16
gh label create "release-type/minor" --color fbca04
gh label create "release-type/major" --color d93f0b
gh label create "db-release-type/patch" --color 0e8a16
gh label create "db-release-type/minor" --color fbca04
gh label create "db-release-type/major" --color d93f0b
gh label create "deploy" --color 1d76db
gh label create "migrate" --color 5319e7
```

## 5. Secrets del repo

- `RENDER_API_KEY` — API key de Render con acceso al servicio.

## 6. Variables del repo (`gh variable set`)

- `RENDER_SERVICE_ID_PROD`, `RENDER_SERVICE_ID_PRE`, `RENDER_SERVICE_ID_PRE_TEST`
- `URL_PRE`, `URL_PRE_TEST` — URLs de los servicios de los slots (para el
  mensaje de resultado del deploy)

## 7. GitHub Environments

Crea `production`, `pre`, `pre-test` (Settings → Environments). Cada uno
con su propio secret `DATABASE_URL`. `production` es además el gate de
`deploy-render.yml` para el deploy a producción — puedes añadirle reviewers
requeridos si quieres un paso de aprobación manual.

## 8. Probar

1. Abre un PR `feature/x → develop`, mergéalo.
2. Abre un PR `develop → main` con label `release-type/patch` — comprueba
   que el título cambie a "Prepare Release vX.Y.Z" y aparezca el comentario
   de vista previa.
3. Mergéalo — comprueba el tag, el GitHub Release (con link al CHANGELOG) y
   el PR de sync "Sync release vX.Y.Z to develop".
4. Abre un issue con label `deploy` y cuerpo `/deploy vX.Y.Z` — comprueba el
   deploy a Render.
