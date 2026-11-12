#!/usr/bin/env bash
# Tests the "Seeding Herdr desktop Actions" step of setup.sh (seed_herdr_actions).
# Only the step's functions are extracted and run (never setup.sh itself), against
# fixture files in a temp dir (never ~/.config/herdr-app), with a stub `pgrep`.
# SETUP_SH overrides the file to extract from (used to mutation-check this test).
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
setup="${SETUP_SH:-$repo_root/setup.sh}"
command -v jq >/dev/null 2>&1 || { echo "seed test needs jq" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0
pass() { echo "PASS $1"; }
bad() { echo "FAIL $1"; fail=1; }

# The extracted step. step/ok/skip print tagged lines the cases grep for.
# It runs under the same shell options as setup.sh (set -euo pipefail), and prints
# DONE after the step so a case can tell "skipped" from "aborted the whole setup".
{
  cat <<'EOF'
set -euo pipefail
step() { :; }
ok() { echo "OK $1"; }
skip() { echo "SKIP $1"; }
EOF
  sed -n '/^herdr_app_stopped() {/,/^}/p' "$setup"
  sed -n '/^seed_herdr_actions() {/,/^}/p' "$setup"
  echo 'seed_herdr_actions'
  echo 'echo DONE'
} >"$tmp/step.sh"
grep -q '^seed_herdr_actions() {' "$tmp/step.sh" || { echo "FAIL: seed_herdr_actions not found in $setup"; exit 1; }

# pgrep stub: PGREP_PLAN is a space-separated list of exit codes, one per call;
# the last one repeats.
mkdir "$tmp/bin"
cat >"$tmp/bin/pgrep" <<'EOF'
#!/bin/sh
n=$(cat "$PGREP_COUNT" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" >"$PGREP_COUNT"
set -- $PGREP_PLAN
[ "$n" -gt "$#" ] && n=$#
eval "exit \${$n}"
EOF
chmod +x "$tmp/bin/pgrep"

dotfiles="$tmp/dotfiles with space & quote'"
mkdir -p "$dotfiles/herdr-app"
cat >"$dotfiles/herdr-app/actions.json" <<'EOF'
{"t3-actions":{"list":[
 {"id":"a","name":"A","command":"true","icon":"play","place":"tab","cwd":"__DOTFILES__"},
 {"id":"b","name":"B","command":"true","icon":"play","place":"tab","cwd":"__DOTFILES__/sub"},
 {"id":"c","name":"C","command":"true","icon":"play","place":"tab"}]}}
EOF
fixture='{"layout":"herdr-t3","sidebar.width":268,"space.colors":{"sp1":"#4b5563"}}'

# case <name>: fresh app dir, shared.json = $fixture. Sets $app, $shared.
case_dir() { app="$tmp/$1"; shared="$app/shared.json"; rm -rf "$app"; mkdir -p "$app"; echo "$fixture" >"$shared"; }
# seed [pgrep plan]: run the step; output in $out.
seed() {
  rm -f "$tmp/count"
  # A step that aborts under set -e exits non-zero; the cases read that from the missing DONE line.
  out="$(PGREP_PLAN="${1:-1}" PGREP_COUNT="$tmp/count" PATH="$tmp/bin:$PATH" HERDR_APP_DIR="$app" DOTFILES_DIR="$dotfiles" bash "$tmp/step.sh" 2>&1)" || true
}
backups() { find "$app" -maxdepth 1 -name 'shared.json.bak-before-actions*' | wc -l | tr -d ' '; }
same() { cmp -s "$1" "$2"; }
others() { jq -S 'del(.["t3-actions"])' "$1"; }

# 1. Seeds: 3 actions, placeholder replaced (also in a path with space/&/quote),
#    other keys untouched, no `last`, backup equals the original.
case_dir seeds; cp "$shared" "$tmp/orig.json"; seed
if grep -q '^OK .*3' <<<"$out" \
  && jq -e --arg d "$dotfiles" '.["t3-actions"] | (has("last") | not) and (.list | length == 3 and .[0].cwd == $d and .[1].cwd == ($d + "/sub") and (.[2] | has("cwd") | not))' "$shared" >/dev/null \
  && diff <(others "$tmp/orig.json") <(others "$shared") >/dev/null \
  && [[ "$(backups)" == 1 ]] && same "$tmp/orig.json" "$(find "$app" -name 'shared.json.bak-before-actions*')"; then
  pass "seeds, keeps other keys, replaces placeholder, backs up"; else bad "seeds"; echo "$out"; fi

# 2. Idempotent: a second run changes nothing.
cp "$shared" "$tmp/seeded.json"; seed
if grep -q '^SKIP.*already set' <<<"$out" && same "$tmp/seeded.json" "$shared"; then pass "re-run does nothing"; else bad "re-run"; echo "$out"; fi

# 3. Re-seeding after clearing the key keeps the earlier backup (finding 5).
jq 'del(.["t3-actions"])' "$shared" >"$shared.new" && mv "$shared.new" "$shared"; sleep 1; seed
if grep -q '^OK' <<<"$out" && [[ "$(backups)" == 2 ]] \
  && find "$app" -name 'shared.json.bak-before-actions*' -exec cmp -s "$tmp/orig.json" {} \; -print | grep -q .; then
  pass "re-seed keeps the earlier backup"; else bad "re-seed overwrote the earlier backup (backups: $(backups))"; echo "$out"; fi

# 4. Herdr.app running: skip and leave the file alone.
case_dir running; seed 0
if grep -q '^SKIP' <<<"$out" && ! grep -q '^OK' <<<"$out" && echo "$fixture" | same - "$shared" && [[ "$(backups)" == 0 ]]; then
  pass "app running: skipped, file unchanged"; else bad "app running"; echo "$out"; fi

# 5. pgrep itself failing (exit 2) is not "not running": skip.
case_dir pgreperr; seed 2
if grep -q '^SKIP' <<<"$out" && echo "$fixture" | same - "$shared"; then pass "pgrep error: skipped"; else bad "pgrep error"; echo "$out"; fi

# 6. App starts after the first check, before the write (finding 7): skip, no change, no temp file.
case_dir race; seed "1 0"
if grep -q '^SKIP' <<<"$out" && ! grep -q '^OK' <<<"$out" && echo "$fixture" | same - "$shared" \
  && [[ -z "$(find "$app" -name '.shared-actions.*')" ]]; then
  pass "app started mid-step: skipped, file unchanged, no temp file"; else bad "app started mid-step"; echo "$out"; fi

# 7. Missing shared.json, invalid shared.json, invalid seed: skip, nothing written.
case_dir missing; rm "$shared"; seed
if grep -q '^SKIP' <<<"$out" && [[ ! -e "$shared" ]]; then pass "missing shared.json: skipped"; else bad "missing shared.json"; echo "$out"; fi
case_dir invalid; echo '{not json' >"$shared"; seed
if grep -q '^SKIP' <<<"$out" && [[ "$(cat "$shared")" == '{not json' ]]; then pass "invalid shared.json: skipped, unchanged"; else bad "invalid shared.json"; echo "$out"; fi
case_dir oddstate; echo '{"t3-actions":"oops"}' >"$shared"; seed
if grep -q '^SKIP' <<<"$out" && [[ "$(cat "$shared")" == '{"t3-actions":"oops"}' ]]; then pass "unexpected t3-actions type: skipped, unchanged"; else bad "unexpected t3-actions type"; echo "$out"; fi
case_dir badseed; cp "$dotfiles/herdr-app/actions.json" "$tmp/seed.good"; echo '{"t3-actions":{"list":"nope"}}' >"$dotfiles/herdr-app/actions.json"; seed
if grep -q '^SKIP' <<<"$out" && echo "$fixture" | same - "$shared" && [[ -z "$(find "$app" -name '.shared-actions.*')" ]]; then pass "invalid seed: skipped, unchanged"; else bad "invalid seed"; echo "$out"; fi
cp "$tmp/seed.good" "$dotfiles/herdr-app/actions.json"

# 8. Other shared.json shapes: absent list is seeded without `last`.
case_dir nolist; echo '{"t3-actions":{"keep":1},"layout":"x"}' >"$shared"; seed
if grep -q '^OK' <<<"$out" && jq -e '.["t3-actions"].keep == 1 and (.["t3-actions"].list | length == 3) and .layout == "x"' "$shared" >/dev/null; then pass "absent list: seeded, siblings kept"; else bad "absent list"; echo "$out"; fi

# 9. Failure paths never abort setup.sh (set -e) and never leave shared.json changed
#    or a temp file behind. A stub on PATH makes one command fail.
real_jq="$(command -v jq)"
stub() { # stub <name> <script body>
  printf '#!/bin/sh\n%s\n' "$2" >"$tmp/bin/$1"; chmod +x "$tmp/bin/$1"
}
unstub() { rm -f "$tmp/bin/$1"; }
failure_case() { # failure_case <label> <command to break>
  case_dir "fail-$1"; stub "$2" 'exit 1'; seed; unstub "$2"
  if grep -q '^SKIP' <<<"$out" && ! grep -q '^OK' <<<"$out" && grep -q '^DONE' <<<"$out" \
    && echo "$fixture" | same - "$shared" && [[ -z "$(find "$app" -name '.shared-actions.*')" ]]; then
    pass "$1 fails: skipped, setup not aborted, file unchanged, no temp file"; else bad "$1 fails"; echo "$out"; fi
}
failure_case mktemp mktemp
failure_case backup cp
failure_case rename mv

# The merge jq failing is a skip too. Only the first jq call after the state check
# builds the file; a stub that fails on the merge program (it mentions --slurpfile's $seed).
case_dir fail-merge
stub jq "case \"\$*\" in *'\$seed'*) exit 5;; esac; exec $real_jq \"\$@\""
seed; unstub jq
if grep -q '^SKIP' <<<"$out" && ! grep -q '^OK' <<<"$out" && grep -q '^DONE' <<<"$out" \
  && echo "$fixture" | same - "$shared" && [[ -z "$(find "$app" -name '.shared-actions.*')" ]]; then
  pass "merge jq fails: skipped, setup not aborted, file unchanged"; else bad "merge jq fails"; echo "$out"; fi

# Counting the actions afterwards is cosmetic: if that jq fails, the step must still
# finish (not abort setup.sh) rather than be skipped half-way. Unlike the cases above
# this one passes whether or not the failure happens (it expects the seed to succeed
# either way), so the stub drops a marker when it fires and the case requires it:
# a reworded count program must not turn this into a silent no-op.
case_dir fail-count; rm -f "$tmp/count-stub-hit"
stub jq "[ \"\$1\" = '.[\"t3-actions\"].list | length' ] && { : >'$tmp/count-stub-hit'; exit 5; }; exec $real_jq \"\$@\""
seed; unstub jq
if [[ ! -e "$tmp/count-stub-hit" ]]; then
  bad "count jq fails: the stub never fired (the step's count program changed; update this stub)"
elif grep -q '^DONE' <<<"$out" && jq -e '.["t3-actions"].list | length == 3' "$shared" >/dev/null; then
  pass "count jq fails: setup not aborted, actions still seeded"; else bad "count jq fails"; echo "$out"; fi

exit "$fail"
