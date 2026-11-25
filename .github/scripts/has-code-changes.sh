#!/usr/bin/env bash
# has-code-changes.sh — envuelve changed-paths.sh y emite `has_changes=true|false`
# para $GITHUB_OUTPUT. Un fallo de changed-paths.sh (rc >= 2) se propaga: no se
# enmascara como "sin cambios".
#
# Uso: has-code-changes.sh <base-sha> <head-sha> <regex-ERE>
# Códigos de salida: 0 (imprimió el resultado) | 2 (error).

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $# -eq 3 ]] || { echo "Uso: $0 <base-sha> <head-sha> <regex-ERE>" >&2; exit 2; }

rc=0
bash "$DIR/changed-paths.sh" "$1" "$2" "$3" || rc=$?
case "$rc" in
  0) echo "has_changes=true" ;;
  1) echo "has_changes=false" ;;
  *) echo "changed-paths.sh fallo (rc=$rc)" >&2; exit 2 ;;
esac
