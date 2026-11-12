#!/usr/bin/env bash
# Tests herdr-app/actions.json (the Herdr desktop app's top-bar Actions seed).
# The app closes a pane when its program exits, so the one-shot actions
# (Shellcheck, Herdr config check) must hold the pane open until Enter or their
# output is never seen. Each one is run the way the app runs it (`sh -c`, in the
# repo folder) with stdin held open. ACTIONS_FILE overrides the seed (used to
# mutation-check this test).
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
seed="${ACTIONS_FILE:-$repo_root/herdr-app/actions.json}"
one_shot=(shellcheck herdr-config)
fail=0
tmp="$(mktemp -d)"
trap 'exec 3>&- 2>/dev/null || true; rm -rf "$tmp"' EXIT

for cmd in jq shellcheck herdr zsh; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "actions test needs $cmd" >&2; exit 1; }
done

# Schema: valid JSON, unique ids, allowed icon/place, non-empty name/command.
jq -e '.["t3-actions"].list
  | length > 0 and (map(.id) | unique | length) == length
    and all(.[]; (.name | length) > 0 and (.command | length) > 0
      and (.icon | IN("play", "test", "lint", "configure", "build", "debug"))
      and (.place | IN("tab", "right", "down")))' "$seed" >/dev/null \
  || { echo "FAIL schema: $seed"; exit 1; }
echo "PASS schema"

for id in "${one_shot[@]}"; do
  command="$(jq -r --arg id "$id" '.["t3-actions"].list[] | select(.id == $id) | .command' "$seed")"
  [[ -n "$command" ]] || { echo "FAIL $id: action missing"; fail=1; continue; }
  rm -f "$tmp/in" "$tmp/out"; mkfifo "$tmp/in"
  exec 3<>"$tmp/in" # a writer end, so the action's stdin stays open
  (cd "$repo_root" && exec sh -c "$command") <"$tmp/in" >"$tmp/out" 2>&1 &
  pid=$!
  sleep 3
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "FAIL $id: exited before Enter, so the app would close the pane and drop the output"
    fail=1; exec 3>&-; continue
  fi
  printf '\n' >&3
  for _ in $(seq 25); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
  if kill -0 "$pid" 2>/dev/null; then
    echo "FAIL $id: still running after Enter"; kill "$pid" 2>/dev/null || true; fail=1; exec 3>&-; continue
  fi
  wait "$pid" 2>/dev/null || true
  exec 3>&-
  echo "PASS $id holds the pane until Enter"
  if [[ "$id" == shellcheck ]] && ! grep -qF '[exit 0]' "$tmp/out"; then
    echo "FAIL shellcheck: expected '[exit 0]' on a clean run, got:"; sed 's/^/    /' "$tmp/out"; fail=1
  elif [[ "$id" == shellcheck ]]; then
    echo "PASS shellcheck reports [exit 0]"
  fi
done
exit "$fail"
