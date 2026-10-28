#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# The selector classifies every prompt under an 8 s selectorTimeoutMs; keep it on
# Terra at the lowest effort Terra accepts so classification stays fast.
for set in work-cekatai-default work-cekatai-superpower; do
  f="$repo_root/pi/model-roles/$set.yaml"
  if yq -e '
    .selector.model.provider == "cekat" and
    .selector.model.id == "azure_ai/gpt-6.1-terra" and
    .selector.effort == "low"
  ' "$f" >/dev/null 2>&1; then
    echo "ok   - $set selector"
  else
    echo "FAIL - $set selector: $(yq -o=json -I=0 '.selector' "$f")" >&2
    exit 1
  fi
done
