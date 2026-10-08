#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
settings="$repo_root/pi/settings.json"

# Keep the default model on Cekat Luna without turning off startup reasoning
# globally; Luna's unsupported effort is clamped by Pi for that model.
jq -e '
  .defaultProvider == "cekat" and
  .defaultModel == "azure_ai/gpt-6-luna" and
  .defaultThinkingLevel == "high"
' "$settings"
