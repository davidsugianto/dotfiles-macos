#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$repo_root/pi/scripts/pi-worker-model"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

fail=0
check() { # name expected actual
  if [[ "$2" == "$3" ]]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1: expected [$2] got [$3]" >&2
    fail=1
  fi
}

cat >"$tmp/basic.yaml" <<'YAML'
version: 1
enabled: true
roles:
  default:
    model:
      provider: prov
      id: def-model
    effort: high
  fast:
    model:
      provider: prov
      id: vendor/slash-model
    effort: low
  noeffort:
    model:
      provider: prov
      id: plain-model
YAML

cat >"$tmp/disabled.yaml" <<'YAML'
version: 1
enabled: false
roles:
  default:
    model:
      provider: prov
      id: def-model
    effort: high
YAML

run() { PI_MODEL_ROLES_CONFIG="$1" "$script" "${@:2}" 2>"$tmp/stderr"; }

check "role found" "prov def-model high" "$(run "$tmp/basic.yaml" default)"
check "id with / intact" "prov vendor/slash-model low" "$(run "$tmp/basic.yaml" fast)"
check "effort absent -> -" "prov plain-model -" "$(run "$tmp/basic.yaml" noeffort)"
check "unknown role falls back to default" "prov def-model high" "$(run "$tmp/basic.yaml" nope)"
grep -q "nope" "$tmp/stderr" && echo "ok   - unknown role warns" || { echo "FAIL - unknown role warns" >&2; fail=1; }
check "enabled false prints nothing" "" "$(run "$tmp/disabled.yaml" default)"
check "missing file prints nothing" "" "$(run "$tmp/missing.yaml" default)"

rc=0
"$script" >/dev/null 2>&1 || rc=$?
check "no args exits 2" "2" "$rc"

work="$repo_root/pi/model-roles/work-cekataiofficial.yaml"
check "work task" "cekat azure_ai/gpt-6.1-sol off" "$(run "$work" task)"
check "work slow" "cekat azure_ai/gpt-6.1-sol high" "$(run "$work" slow)"

exit "$fail"
