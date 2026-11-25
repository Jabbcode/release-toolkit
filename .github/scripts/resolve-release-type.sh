#!/usr/bin/env bash
# resolve-release-type.sh — reduce una lista de etiquetas de PR al tipo de
# release. Única implementación: la comparten release-next.yml y
# release-preview-next.yml.
#
# Uso:
#   resolve-release-type.sh < etiquetas.txt     (una etiqueta por línea)
#
# Salida (stdout, una palabra):
#   patch | minor | major   exactamente una etiqueta release-type/* válida
#   none                    ninguna etiqueta release-type/* válida
#   multiple                dos o más etiquetas release-type/* distintas
#
# Solo cuentan las etiquetas exactas release-type/patch|minor|major; el resto
# (incluida una release-type/otra) se ignora. Se toleran CR finales (CRLF).

set -euo pipefail

found=()
while IFS= read -r label || [[ -n "$label" ]]; do
  label="${label%$'\r'}"
  case "$label" in
    release-type/patch | release-type/minor | release-type/major)
      kind="${label#release-type/}"
      if [[ ! " ${found[*]-} " =~ " ${kind} " ]]; then
        found+=("$kind")
      fi
      ;;
  esac
done

case "${#found[@]}" in
  0) echo none ;;
  1) echo "${found[0]}" ;;
  *) echo multiple ;;
esac
