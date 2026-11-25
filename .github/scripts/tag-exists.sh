#!/usr/bin/env bash
# tag-exists.sh — ¿existe el tag en el remoto `origin`? Emite `exists=true|false`
# para $GITHUB_OUTPUT. Un fallo de `git ls-remote` se propaga (exit 2).
#
# Uso: tag-exists.sh <tag>      (p. ej. v1.2.3)
# Códigos de salida: 0 (imprimió el resultado) | 2 (error).

set -uo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $0 <tag>" >&2; exit 2; }

rc=0
git ls-remote --exit-code --tags origin "refs/tags/$1" >/dev/null || rc=$?
case "$rc" in
  0) echo "exists=true" ;;
  2) echo "exists=false" ;;
  *) echo "git ls-remote fallo (rc=$rc)" >&2; exit 2 ;;
esac
