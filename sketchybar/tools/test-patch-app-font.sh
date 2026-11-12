#!/usr/bin/env bash
# Tests for the patched app font: the setup.sh step and patch-app-font.py.
# Needs the stock font (brew cask font-sketchybar-app-font) and the venv that
# setup.sh builds. Run:  sketchybar/tools/test-patch-app-font.sh
set -uo pipefail

TOOLS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DOTFILES_DIR="$(cd -- "$TOOLS_DIR/../.." &>/dev/null && pwd)"
STOCK_FONT="${STOCK_FONT:-$HOME/Library/Fonts/sketchybar-app-font.ttf}"
PY="${PY:-$HOME/.local/share/sketchybar/venv/bin/python}"

# Exit 77 (the automake convention) means "skipped", so a missing prerequisite
# can't be mistaken for a pass.
[[ -f "$STOCK_FONT" ]] || { echo "SKIP: stock font not found at $STOCK_FONT"; exit 77; }
[[ -x "$PY" ]] || { echo "SKIP: no venv python at $PY (run setup.sh first)"; exit 77; }

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
touch "$TMP/start" # marks the run's start; see test_no_bytecode_left_behind
fails=0
check() { # check <name> <command...>
  local name="$1"; shift
  if "$@"; then echo "ok   - $name"; else echo "FAIL - $name"; fails=$((fails + 1)); fi
}

# --- setup.sh step ---
# Runs the font step alone in a throwaway HOME. $1 = name of the scenario dir,
# $2 = optional setup command run inside that HOME first. Prints the output.
run_step() {
  local home="$TMP/$1/home" bin="$TMP/$1/bin"
  mkdir -p "$home/Library/Fonts" "$bin"
  cp "$STOCK_FONT" "$home/Library/Fonts/sketchybar-app-font.ttf"
  [[ -n "${2:-}" ]] && HOME="$home" BIN="$bin" eval "$2"
  {
    echo 'set -euo pipefail'
    echo 'step() { echo "==> $1"; }; ok() { echo "ok: $1"; }; skip() { echo "skip: $1"; }'
    echo "DOTFILES_DIR='$DOTFILES_DIR'"
    # The step runs from its `step` line up to the next banner comment.
    awk '/^step "Building patched sketchybar-app-font/{f=1} f&&/^# ---/{exit} f{print}' "$DOTFILES_DIR/setup.sh"
    echo 'echo REACHED_END'
  } >"$TMP/$1/step.sh"
  HOME="$home" PATH="$bin:$PATH" bash "$TMP/$1/step.sh" 2>&1
}
fake() { printf '#!/bin/sh\n%s\n' "$2" >"$1" && chmod +x "$1"; }
venv_with() { # venv_with <python-body> <pip-body>: a fake venv under $HOME
  mkdir -p "$HOME/.local/share/sketchybar/venv/bin"
  fake "$HOME/.local/share/sketchybar/venv/bin/python" "$1"
  fake "$HOME/.local/share/sketchybar/venv/bin/pip" "$2"
}

# A failing python3/venv must fall back, not abort setup.
test_setup_step_falls_back() {
  local out
  out="$(run_step nopy 'fake "$BIN/python3" "exit 1"')"
  [[ "$out" == *REACHED_END* && "$out" == *"couldn't build the patched font"* ]] || { echo "$out" | sed 's/^/    /'; return 1; }
}
# A broken toolchain in an existing venv (python and pip both fail) too.
test_setup_step_falls_back_broken_venv() {
  local out
  out="$(run_step brokenvenv 'venv_with "exit 1" "exit 1"')"
  [[ "$out" == *REACHED_END* && "$out" == *"couldn't build the patched font"* ]] || { echo "$out" | sed 's/^/    /'; return 1; }
}
# Offline re-run: fonttools is already in the venv but pip can't reach PyPI.
# The build must not depend on pip then.
test_setup_step_offline_rerun_builds() {
  local out
  out="$(run_step offline 'venv_with "exec \"'"$PY"'\" \"\$@\"" "exit 1"')"
  [[ "$out" == *"patched font installed"* && -f "$TMP/offline/home/Library/Fonts/sketchybar-app-font-custom.ttf" ]] || { echo "$out" | sed 's/^/    /'; return 1; }
}

# --- patch-app-font.py output ---
STOCK_SUM_BEFORE="$(shasum "$STOCK_FONT" | cut -d' ' -f1)"
build() {
  "$PY" "$TOOLS_DIR/patch-app-font.py" --base "$STOCK_FONT" --out "$TMP/out.ttf" \
    --family sketchybar-app-font-custom --glyph "herdr=$DOTFILES_DIR/sketchybar/assets/herdr.svg" \
    >/dev/null 2>&1
}

font_query() { # font_query <python-expr using f, g (the :herdr: glyph)>
  "$PY" - "$TMP/out.ttf" "$1" <<'EOF' 2>/dev/null
import sys
from fontTools.ttLib import TTFont
f = TTFont(sys.argv[1])
g = f["glyf"][":herdr:"]
sys.exit(0 if eval(sys.argv[2]) else 1)
EOF
}

test_side_bearing_matches_glyph() { font_query 'f["hmtx"][":herdr:"][1] == g.xMin'; }
test_ligature_registered() {
  font_query 'any(l.LigGlyph == ":herdr:" and l.CompCount == 7
                   for l in f["GSUB"].table.LookupList.Lookup[0].SubTable[0].ligatures[":"])'
}
test_family_renamed() {
  font_query 'all(str(n) == "sketchybar-app-font-custom" for n in f["name"].names if n.nameID in (1, 4))'
}
test_stock_font_untouched() {
  [[ "$(shasum "$STOCK_FONT" | cut -d' ' -f1)" == "$STOCK_SUM_BEFORE" ]] && ! cmp -s "$STOCK_FONT" "$TMP/out.ttf"
}

# A failed verify (or any failure after the build) must not leave a bad font
# at --out, and must keep a previously good one intact.
test_failed_verify_keeps_output() {
  cp "$TMP/out.ttf" "$TMP/good.ttf"
  local before after
  before="$(shasum "$TMP/good.ttf" | cut -d' ' -f1)"
  : >"$TMP/verify-calls"
  "$PY" -I - "$TOOLS_DIR/patch-app-font.py" "$STOCK_FONT" "$DOTFILES_DIR/sketchybar/assets/herdr.svg" "$TMP/good.ttf" "$TMP/never.ttf" "$TMP/verify-calls" <<'EOF2' >/dev/null 2>&1
import importlib.util, sys
sys.dont_write_bytecode = True  # importing the tool must not litter the repo
tool, base, svg, good, never, calls = sys.argv[1:7]
spec = importlib.util.spec_from_file_location("patch_app_font", tool)
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
def boom(path, names):
    # Record that the simulated failure really happened, so the assertions
    # below can't pass just because this snippet never ran.
    with open(calls, "a") as fh:
        fh.write(path + "\n")
    sys.exit("verify failed (simulated)")
mod.verify = boom
for out in (good, never):
    sys.argv = ["x", "--base", base, "--out", out, "--family", "f", "--glyph", f"herdr={svg}"]
    try:
        mod.main()
    except SystemExit:
        pass
EOF2
  after="$(shasum "$TMP/good.ttf" | cut -d' ' -f1)"
  # Both builds must have reached the (simulated) failing verify...
  [[ "$(grep -c . "$TMP/verify-calls")" == 2 ]] || { echo "    simulated verify failure didn't run for both builds"; return 1; }
  # ...and neither may have touched the destination.
  [[ "$before" == "$after" && ! -e "$TMP/never.ttf" && ! -e "$TMP/good.ttf.tmp" && ! -e "$TMP/never.ttf.tmp" ]]
}
# An unexpected font layout (e.g. after a major cask upgrade) gets a clear
# message, not a Python traceback.
test_unexpected_layout_message() {
  local out
  "$PY" -I - "$STOCK_FONT" "$TMP/odd.ttf" <<'EOF2' >/dev/null 2>&1
import sys
from fontTools.ttLib import TTFont
f = TTFont(sys.argv[1]); f["GSUB"].table.LookupList.Lookup[0].SubTable = []; f.save(sys.argv[2])
EOF2
  out="$("$PY" "$TOOLS_DIR/patch-app-font.py" --base "$TMP/odd.ttf" --out "$TMP/odd-out.ttf" \
    --family f --glyph "herdr=$DOTFILES_DIR/sketchybar/assets/herdr.svg" 2>&1)"
  [[ $? -ne 0 && "$out" == *"unexpected GSUB layout"* && "$out" != *Traceback* && ! -e "$TMP/odd-out.ttf" ]] || { echo "$out" | tail -3 | sed 's/^/    /'; return 1; }
}

check "setup.sh font step falls back when python3 fails" test_setup_step_falls_back
check "setup.sh font step falls back when the venv toolchain is broken" test_setup_step_falls_back_broken_venv
check "setup.sh font step builds offline when fonttools is already installed" test_setup_step_offline_rerun_builds
check "patch script builds the font" build
if [[ -f "$TMP/out.ttf" ]]; then
  check "left side bearing equals glyph xMin" test_side_bearing_matches_glyph
  check ":herdr: ligature registered (7 components)" test_ligature_registered
  check "family renamed" test_family_renamed
  check "stock font untouched, output is a new file" test_stock_font_untouched
  check "failed verify leaves no bad font at --out" test_failed_verify_keeps_output
  check "unexpected GSUB layout gives a clear error" test_unexpected_layout_message
fi

# Importing the script as a module must not drop bytecode into the repo. Only
# bytecode written during this run counts, so a stray .pyc from an earlier
# session doesn't fail the check for something this run didn't do.
test_no_bytecode_left_behind() {
  [[ -z "$(find "$TOOLS_DIR" -name '*.pyc' -newer "$TMP/start" 2>/dev/null)" ]]
}
check "tests leave no __pycache__ in the repo" test_no_bytecode_left_behind

((fails == 0)) && echo "all passed" || { echo "$fails failed"; exit 1; }
