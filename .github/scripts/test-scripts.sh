#!/usr/bin/env bash
# test-scripts.sh — aserciones de resolve-release-type.sh y
# parse-deploy-command.sh. Sin dependencias ni red.
#
# Uso: bash .github/scripts/test-scripts.sh   (exit 0 = todo en verde)
#
# Cada nombre empieza por el ID de su fila en test-plan.md (A1..A9).

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVE="$DIR/resolve-release-type.sh"
PARSE="$DIR/parse-deploy-command.sh"

pass=0
fail=0

# check <nombre> <esperado> <obtenido>
check() {
  if [[ "$2" == "$3" ]]; then
    pass=$((pass + 1))
    echo "ok   $1"
  else
    fail=$((fail + 1))
    echo "FAIL $1: esperado '$2', obtenido '$3'"
  fi
}

# resolve <etiquetas separadas por salto de línea>
resolve() { printf '%b' "$1" | bash "$RESOLVE"; }

# parse <texto con escapes printf> -> "<salida>|<exit>"
parse() {
  local out rc=0
  out=$(printf '%b' "$1" | bash "$PARSE") || rc=$?
  echo "${out}|${rc}"
}

check "A1 resolve: 0 etiquetas -> none" none "$(resolve '')"
check "A1 resolve: entrada vacía sin salto -> none" none "$(printf '' | bash "$RESOLVE")"

check "A2 resolve: patch" patch "$(resolve 'release-type/patch\n')"
check "A2 resolve: minor" minor "$(resolve 'release-type/minor\n')"
check "A2 resolve: major" major "$(resolve 'release-type/major\n')"
check "A2 resolve: sin salto final" major "$(resolve 'release-type/major')"
check "A2 resolve: la misma etiqueta repetida cuenta una vez" patch \
  "$(resolve 'release-type/patch\nrelease-type/patch\n')"

check "A3 resolve: patch + minor -> multiple" multiple \
  "$(resolve 'release-type/patch\nrelease-type/minor\n')"
check "A3 resolve: las tres -> multiple" multiple \
  "$(resolve 'release-type/major\nrelease-type/minor\nrelease-type/patch\n')"

check "A4 resolve: ajenas + minor -> minor" minor \
  "$(resolve 'bug\ndocs\nrelease-type/minor\n')"
check "A4 resolve: solo ajenas -> none" none "$(resolve 'bug\ndocs\n')"
check "A4 resolve: release-type/otra no cuenta -> none" none \
  "$(resolve 'release-type/otra\ndeploy\n')"
check "A4 resolve: CRLF" patch "$(resolve 'bug\r\nrelease-type/patch\r\n')"

check "A5 parse: /deploy v1.2.3" "version=1.2.3|0" "$(parse '/deploy v1.2.3\n')"
check "A5 parse: sin salto final" "version=1.2.3|0" "$(parse '/deploy v1.2.3')"
check "A5 parse: versión de varios dígitos" "version=10.20.30|0" "$(parse '/deploy v10.20.30')"
check "A5 parse: espacios finales" "version=1.2.3|0" "$(parse '/deploy v1.2.3   \n')"

check "A6 parse: /deploy solo" "reason=version_required|1" "$(parse '/deploy\n')"
check "A6 parse: /deploy con espacios" "reason=version_required|1" "$(parse '/deploy   \n')"

check "A7 parse: /deploy v1.2" "reason=malformed|1" "$(parse '/deploy v1.2\n')"
check "A7 parse: sin la v" "reason=malformed|1" "$(parse '/deploy 1.2.3\n')"
check "A7 parse: sin orden" "reason=malformed|1" "$(parse 'hola\n')"
check "A7 parse: texto vacío" "reason=malformed|1" "$(parse '')"
check "A7 parse: /deployed no es la orden" "reason=malformed|1" "$(parse '/deployed v1.2.3\n')"
check "A7 parse: orden con sangría no cuenta" "reason=malformed|1" "$(parse '  /deploy v1.2.3\n')"

check "A8 parse: CRLF" "version=1.2.3|0" "$(parse '/deploy v1.2.3\r\n')"
check "A8 parse: CRLF en /deploy solo" "reason=version_required|1" "$(parse '/deploy\r\n')"

# A9: texto extra tras la versión -> malformed (nunca versión parcial);
# líneas previas ajenas se ignoran; con varias órdenes gana la primera.
check "A9 parse: texto extra tras la versión -> malformed" "reason=malformed|1" \
  "$(parse '/deploy v1.2.3 por favor\n')"
check "A9 parse: texto previo en otras líneas" "version=1.2.3|0" \
  "$(parse 'Hola,\nquiero desplegar:\n/deploy v1.2.3\ngracias\n')"
check "A9 parse: texto previo + texto extra -> malformed" "reason=malformed|1" \
  "$(parse 'Hola\n/deploy v1.2.3 por favor\n')"
check "A9 parse: gana la primera orden" "version=1.0.0|0" \
  "$(parse '/deploy v1.0.0\n/deploy v2.0.0\n')"

echo "---"
echo "pasan: $pass, fallan: $fail"
[[ "$fail" -eq 0 ]]
