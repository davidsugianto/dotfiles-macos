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
# fake skills repo with two cores; the checker fails silently for "aaa".
mkdir -p "$tmp/dot/pi/scripts" "$tmp/home"
cp "$repo_root/pi/scripts/sre-skills-sync" "$tmp/dot/pi/scripts/"
repo="$tmp/skills"
mkdir -p "$repo/personal-skill-generator/scripts" "$repo/aaa" "$repo/bbb"
git -C "$repo" init -q -b main
cat >"$repo/personal-skill-generator/scripts/check-skill.sh" <<'CHK'
#!/usr/bin/env bash
[[ "$1" == */aaa ]] && exit 1
exit 0
CHK
for c in aaa bbb; do
  printf -- '---\nname: %s\n---\n' "$c" >"$repo/$c/SKILL.md"
  for rt in claude pi; do
    mkdir -p "$tmp/dot/$rt/skills/$c"
    cp "$repo/$c/SKILL.md" "$tmp/dot/$rt/skills/$c/SKILL.md"
  done
done

run() { HOME="$tmp/home" SRE_SKILLS_DIR="$repo" bash "$tmp/dot/pi/scripts/sre-skills-sync" "$@" 2>&1 || true; }

# A checker failure with no ERROR/WARN line must not end the run early.
out="$(run --no-pull)"
check "silent checker failure is reported" 1 "$(grep -c 'DRIFT .*claude/aaa' <<<"$out")"
check "later cores are still checked" 2 "$(grep -c 'LINK .*skills/bbb' <<<"$out")"

# An unreachable origin skips the pull instead of hanging or failing.
git -C "$repo" remote add origin "$tmp/nowhere"
out="$(run)"
check "failed fetch skips the pull" 1 "$(grep -c 'skip pull: fetch failed' <<<"$out")"

exit "$fail"
