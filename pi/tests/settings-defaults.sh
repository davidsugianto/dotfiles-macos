#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
settings="$repo_root/pi/settings.json"

# Keep the default model on Cekat GPT-6.1 Terra with startup reasoning at high.
jq -e '
  .defaultProvider == "cekat" and
  .defaultModel == "azure_ai/gpt-6.1-terra" and
  .defaultThinkingLevel == "high"
' "$settings"
