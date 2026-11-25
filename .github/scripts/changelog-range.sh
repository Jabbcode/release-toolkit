#!/usr/bin/env bash
# changelog-range.sh — notas del rango "versión previa → HEAD" en un fichero.
# Si existe el tag `v<previa>` parte de él; si no, del primer commit.
# Si el rango no tiene cambios categorizados, escribe el texto de reserva.
#
# Uso: changelog-range.sh <version-previa> <texto-reserva> <fichero-salida>
# Códigos de salida: 0 | 2 (argumentos).

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $# -eq 3 ]] || { echo "Uso: $0 <version-previa> <texto-reserva> <fichero-salida>" >&2; exit 2; }

prev_tag="v$1"
if git rev-parse "$prev_tag" >/dev/null 2>&1; then
  from_ref="$prev_tag"
else
  from_ref=$(git rev-list --max-parents=0 HEAD | tail -1)
fi

bash "$DIR/build-changelog.sh" "$from_ref" HEAD > "$3" || true
if [[ ! -s "$3" ]]; then
  echo "$2" > "$3"
fi
