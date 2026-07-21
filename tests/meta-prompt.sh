#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
SAVE="$ROOT/skills/under-claw-meta-prompt/scripts/save-prompt.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT HUP INT TERM

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  PASS %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

echo "▶ meta-prompt deterministic file handling"
out="$(printf 'first prompt\n' | "$SAVE" "$TEST_ROOT/new-project")"
[[ "$out" == $'created\t'"$TEST_ROOT/new-project/PROMPT.md" ]] && ok "directory creates PROMPT.md" || bad "directory creates PROMPT.md"
grep -q '^first prompt$' "$TEST_ROOT/new-project/PROMPT.md" && ok "created content preserved" || bad "created content preserved"

out="$(printf 'second prompt\n' | "$SAVE" "$TEST_ROOT/new-project")"
[[ "$out" == $'updated\t'"$TEST_ROOT/new-project/PROMPT.md" ]] && ok "existing PROMPT.md updated" || bad "existing PROMPT.md updated"
grep -q '^second prompt$' "$TEST_ROOT/new-project/PROMPT.md" && ok "updated content replaced" || bad "updated content replaced"

out="$(printf 'named prompt\n' | "$SAVE" "$TEST_ROOT/custom.md")"
[[ "$out" == $'created\t'"$TEST_ROOT/custom.md" && -f "$TEST_ROOT/custom.md" ]] && ok "missing .md treated as file" || bad "missing .md treated as file"

mkdir -p "$TEST_ROOT/unique"
printf 'old\n' > "$TEST_ROOT/unique/team-prompt.md"
out="$(printf 'unique prompt\n' | "$SAVE" "$TEST_ROOT/unique")"
[[ "$out" == $'updated\t'"$TEST_ROOT/unique/team-prompt.md" ]] && ok "single candidate selected" || bad "single candidate selected"

mkdir -p "$TEST_ROOT/multiple"
printf 'a\n' > "$TEST_ROOT/multiple/a-prompt.md"
printf 'b\n' > "$TEST_ROOT/multiple/b-prompt.md"
printf 'new\n' | "$SAVE" "$TEST_ROOT/multiple" >/dev/null 2>&1
rc=$?
[[ "$rc" == 3 ]] && ok "multiple candidates rejected" || bad "multiple candidates rejected"
grep -q '^a$' "$TEST_ROOT/multiple/a-prompt.md" && grep -q '^b$' "$TEST_ROOT/multiple/b-prompt.md" \
  && ok "multiple candidates unchanged" || bad "multiple candidates unchanged"

ln -s "$TEST_ROOT/custom.md" "$TEST_ROOT/link.md"
printf 'blocked\n' | "$SAVE" "$TEST_ROOT/link.md" >/dev/null 2>&1
rc=$?
[[ "$rc" == 4 ]] && ok "symlink rejected" || bad "symlink rejected"

printf '' | "$SAVE" "$TEST_ROOT/empty.md" >/dev/null 2>&1
rc=$?
[[ "$rc" == 2 && ! -e "$TEST_ROOT/empty.md" ]] && ok "empty prompt rejected" || bad "empty prompt rejected"

echo "── meta-prompt result: PASS=$PASS FAIL=$FAIL ──"
[[ "$FAIL" == 0 ]]
