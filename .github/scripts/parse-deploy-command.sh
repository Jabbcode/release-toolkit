#!/usr/bin/env bash
# parse-deploy-command.sh — extrae la versión de una orden `/deploy vX.Y.Z`
# en el cuerpo de un issue o comentario. Pensado para volcar su salida tal
# cual en $GITHUB_OUTPUT.
#
# Uso:
#   parse-deploy-command.sh < texto
#
# Salida (stdout) y código:
#   version=X.Y.Z          exit 0  orden válida
#   reason=version_required exit 1  `/deploy` sin nada más
#   reason=malformed       exit 1  sin orden, o versión que no es vX.Y.Z
#
# Reglas: la orden es la PRIMERA línea que empieza por `/deploy` (como
# palabra completa, sin sangría); las demás líneas se ignoran. Tras la
# versión solo se admiten espacios: texto extra (`/deploy v1.2.3 por favor`)
# es `malformed`, nunca una versión parcial. CR finales (CRLF) se ignoran.

set -euo pipefail

command_line=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  if [[ "$line" =~ ^/deploy([[:space:]]|$) ]]; then
    command_line="$line"
    break
  fi
done

args="${command_line#/deploy}"
args="${args#"${args%%[![:space:]]*}"}"
args="${args%"${args##*[![:space:]]}"}"

if [[ -z "$command_line" ]]; then
  echo "reason=malformed"
  exit 1
elif [[ -z "$args" ]]; then
  echo "reason=version_required"
  exit 1
elif [[ "$args" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "version=${BASH_REMATCH[1]}"
else
  echo "reason=malformed"
  exit 1
fi
