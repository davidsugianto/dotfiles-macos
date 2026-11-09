#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# Fake dotfiles tree (the script locates handlers relative to itself) and a
# fake skills repo with six cores. The fake checker fails silently for "aaa",
# passes "bbb", and reports only a description mismatch for the rest:
#   ccc  core too long for pi, handler shortened        -> NOTE
#   ddd  core fine, handler edited by hand              -> DRIFT
#   eee  core contains ": ", handler clean              -> NOTE
#   fff  core too long, handler still too long          -> DRIFT
#   ggg  checker passes, AGENT_SELECTION_FILE is missing -> DRIFT
#   hhh  checker passes, AGENT_SELECTION_FILE exists     -> clean
mkdir -p "$tmp/dot/pi/scripts" "$tmp/home"
cp "$repo_root/pi/scripts/core-ai-skills" "$tmp/dot/pi/scripts/"
repo="$tmp/skills"
mkdir -p "$repo/personal-skill-generator/scripts" "$repo/aaa" "$repo/bbb" "$repo/ccc" "$repo/ddd" "$repo/eee" "$repo/fff" "$repo/ggg" "$repo/hhh"
: >"$tmp/policy.md"
git -C "$repo" init -q -b main
cat >"$repo/personal-skill-generator/scripts/check-skill.sh" <<'CHK'
#!/usr/bin/env bash
[[ "$1" == */aaa ]] && exit 1
if [[ "$1" == */ccc || "$1" == */ddd || "$1" == */eee || "$1" == */fff ]]; then
  echo "ERROR: description differs between core and handler"
  echo "1 error(s) in x"
  exit 1
fi
exit 0
CHK
long="$(printf 'x%.0s' $(seq 1 1100))"
for c in aaa bbb ccc ddd eee fff ggg hhh; do
  d="short"
  [[ "$c" == ccc ]] && d="$long"                  # core too long for pi, handler shortened
  [[ "$c" == ddd ]] && d="fine core description"   # core fine, handler differs
  [[ "$c" == eee ]] && d="Use it: for incidents"    # core has ": ", invalid for pi
  [[ "$c" == fff ]] && d="$long"                    # core too long, handler stays too long
  printf -- '---\nname: %s\ndescription: %s\n---\n' "$c" "$d" >"$repo/$c/SKILL.md"
  for rt in claude pi; do
    mkdir -p "$tmp/dot/$rt/skills/$c"
    cp "$repo/$c/SKILL.md" "$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == ccc ]] && sed -i.bak 's/^description: .*/description: shortened/' "$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == ddd ]] && sed -i.bak 's/^description: .*/description: edited by hand/' "$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == eee ]] && sed -i.bak 's/^description: .*/description: Use it for incidents/' "$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == fff ]] && sed -i.bak "s/^description: .*/description: ${long}y/" "$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == ggg ]] && printf '| `AGENT_SELECTION_FILE` | `%s` | tiers |\n' "$tmp/missing.md" >>"$tmp/dot/$rt/skills/$c/SKILL.md"
    [[ "$c" == hhh ]] && printf '| `AGENT_SELECTION_FILE` | `%s` | tiers |\n' "$tmp/policy.md" >>"$tmp/dot/$rt/skills/$c/SKILL.md"
  done
done

run() { HOME="$tmp/home" CORE_AI_SKILLS_DIR="$repo" bash "$tmp/dot/pi/scripts/core-ai-skills" "$@" 2>&1 || true; }

# A checker failure with no ERROR/WARN line must not end the run early.
out="$(run --no-pull)"
check "silent checker failure is reported" 1 "$(grep -c 'DRIFT .*claude/aaa' <<<"$out")"
check "later cores are still checked" 2 "$(grep -c 'LINK .*skills/bbb' <<<"$out")"

# A description-only mismatch is tolerated only when the core's description is
# too long for pi (over 1024 characters) and the handler's was shortened.
check "shortened handler description is tolerated" 0 "$(grep -c 'DRIFT .*ccc' <<<"$out")"
check "tolerated shortening is noted" 2 "$(grep -c 'NOTE .*ccc' <<<"$out")"
check "other description drift still reported" 1 "$(grep -c 'DRIFT .*claude/ddd' <<<"$out")"
check "core with ': ' and clean handler is tolerated" 0 "$(grep -c 'DRIFT .*eee' <<<"$out")"
check "core with ': ' is noted" 2 "$(grep -c 'NOTE .*eee' <<<"$out")"
check "handler that is still too long stays drift" 2 "$(grep -c 'DRIFT .*fff' <<<"$out")"
check "too-long handler is not noted" 0 "$(grep -c 'NOTE .*fff' <<<"$out")"

# A handler's AGENT_SELECTION_FILE row must point at a file that exists; the
# checker only sees that the row is present.
check "missing AGENT_SELECTION_FILE is drift" 2 "$(grep -c 'DRIFT .*ggg' <<<"$out")"
check "missing file is named" 2 "$(grep -c 'AGENT_SELECTION_FILE.*missing.md' <<<"$out")"
check "existing AGENT_SELECTION_FILE is clean" 0 "$(grep -c 'DRIFT .*hhh' <<<"$out")"
check "handlers without the row are not checked" 0 "$(grep -c 'DRIFT .*bbb' <<<"$out")"

# An unreachable origin skips the pull instead of hanging or failing.
git -C "$repo" remote add origin "$tmp/nowhere"
out="$(run)"
check "failed fetch skips the pull" 1 "$(grep -c 'skip pull: fetch failed' <<<"$out")"

exit "$fail"
