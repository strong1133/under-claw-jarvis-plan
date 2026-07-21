#!/usr/bin/env bash
# Isolated behavior tests for install.sh. No network access is used.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT HUP INT TERM

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  PASS %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
assert_file() { [[ -f "$1" ]] && ok "$2" || bad "$2"; }
assert_absent() { [[ ! -e "$1" ]] && ok "$2" || bad "$2"; }

HOME_DIR="$TEST_ROOT/home"
CODEX_DIR="$TEST_ROOT/codex"
GEMINI_DIR="$TEST_ROOT/gemini"
mkdir -p "$HOME_DIR" "$CODEX_DIR" "$GEMINI_DIR"

run_install() {
  LAST_OUTPUT="$(HOME="$HOME_DIR" CODEX_HOME="$CODEX_DIR" GEMINI_HOME="$GEMINI_DIR" \
    bash "$ROOT/install.sh" "$@")"
}

echo "▶ Default install: Claude + Codex, three skills"
run_install
assert_file "$HOME_DIR/.claude/commands/under-claw-jarvis-plan.md" "Claude command installed"
assert_file "$HOME_DIR/.claude/commands/under-claw-jarvis-plan-loop.md" "Claude loop command installed"
assert_file "$HOME_DIR/.claude/commands/under-claw-meta-prompt.md" "Claude meta-prompt command installed"
assert_file "$HOME_DIR/.claude/skills/under-claw-jarvis-plan/SKILL.md" "Claude base skill installed"
assert_file "$HOME_DIR/.claude/skills/under-claw-jarvis-plan-loop/SKILL.md" "Claude loop skill installed"
assert_file "$HOME_DIR/.claude/skills/under-claw-meta-prompt/SKILL.md" "Claude meta-prompt skill installed"
assert_file "$CODEX_DIR/skills/under-claw-jarvis-plan/SKILL.md" "Codex base skill installed"
assert_file "$CODEX_DIR/skills/under-claw-jarvis-plan-loop/SKILL.md" "Codex loop skill installed"
assert_file "$CODEX_DIR/skills/under-claw-meta-prompt/SKILL.md" "Codex meta-prompt skill installed"
assert_absent "$GEMINI_DIR/skills/under-claw-jarvis-plan" "Gemini untouched by default install"
assert_absent "$HOME_DIR/.claude/skills/.sources" "Externals omitted by default install"

SUMMARY="$(printf '%s\n' "$LAST_OUTPUT" | sed -n '/^under-claw-jarvis-plan$/,$p')"
EXPECTED_SUMMARY='under-claw-jarvis-plan
under-claw-jarvis-plan-loop
under-claw-meta-prompt

제공 스킬
- under-claw-jarvis-plan: 복합 작업을 이해→계획→구현→검수 단계로 수행합니다.
- under-claw-jarvis-plan-loop: 독립 검수 목표에 도달할 때까지 작업을 반복 개선합니다.
- under-claw-meta-prompt: 질의를 일관된 실행 프롬프트로 만들고 필요하면 파일에 저장합니다.'
[[ "$SUMMARY" == "$EXPECTED_SUMMARY" ]] && ok "Post-install skill summary order and descriptions" || bad "Post-install skill summary order and descriptions"
grep -q 'Codex 설치 완료.*\$under-claw-jarvis-plan-loop.*\$under-claw-meta-prompt' <<<"$LAST_OUTPUT" \
  && ok "Codex three invocation hints" || bad "Codex three invocation hints"
grep -q 'Claude 설치 완료.*/under-claw-jarvis-plan-loop.*/under-claw-meta-prompt' <<<"$LAST_OUTPUT" \
  && ok "Claude three invocation hints" || bad "Claude three invocation hints"

echo "▶ Default reinstall updates both hosts"
printf 'command sentinel\n' > "$HOME_DIR/.claude/commands/under-claw-jarvis-plan.md"
for s in under-claw-jarvis-plan under-claw-jarvis-plan-loop under-claw-meta-prompt; do
  printf 'claude sentinel %s\n' "$s" > "$HOME_DIR/.claude/skills/$s/sentinel.txt"
  printf 'codex sentinel %s\n' "$s" > "$CODEX_DIR/skills/$s/sentinel.txt"
done
run_install
BACKUP_DIR="$(find "$HOME_DIR" -maxdepth 1 -type d -name '.under-claw-jarvis-plan-backup-*' | head -1)"
assert_file "$BACKUP_DIR/claude/commands/under-claw-jarvis-plan.md" "Command backup preserved"
grep -q 'command sentinel' "$BACKUP_DIR/claude/commands/under-claw-jarvis-plan.md" \
  && ok "Backup content preserved" || bad "Backup content preserved"
for s in under-claw-jarvis-plan under-claw-jarvis-plan-loop under-claw-meta-prompt; do
  assert_file "$BACKUP_DIR/claude/skills/$s/sentinel.txt" "Claude backup preserved: $s"
  assert_file "$BACKUP_DIR/codex/skills/$s/sentinel.txt" "Codex backup preserved: $s"
  assert_absent "$HOME_DIR/.claude/skills/$s/sentinel.txt" "Claude repository version restored: $s"
  assert_absent "$CODEX_DIR/skills/$s/sentinel.txt" "Codex repository version restored: $s"
done
grep -q '\[업데이트\].*under-claw-jarvis-plan' <<<"$LAST_OUTPUT" \
  && ok "Reinstall reported as update" || bad "Reinstall reported as update"

echo "▶ Claude-only backward compatibility"
CLAUDE_ONLY_HOME="$TEST_ROOT/claude-only-home"
CLAUDE_ONLY_CODEX="$TEST_ROOT/claude-only-codex"
CLAUDE_ONLY_GEMINI="$TEST_ROOT/claude-only-gemini"
mkdir -p "$CLAUDE_ONLY_HOME" "$CLAUDE_ONLY_CODEX" "$CLAUDE_ONLY_GEMINI"
HOME="$CLAUDE_ONLY_HOME" CODEX_HOME="$CLAUDE_ONLY_CODEX" GEMINI_HOME="$CLAUDE_ONLY_GEMINI" bash "$ROOT/install.sh" --skill-only >/dev/null
for s in under-claw-jarvis-plan under-claw-jarvis-plan-loop under-claw-meta-prompt; do
  assert_file "$CLAUDE_ONLY_HOME/.claude/skills/$s/SKILL.md" "Claude-only installs $s"
done
assert_absent "$CLAUDE_ONLY_CODEX/skills" "Claude-only leaves Codex untouched"
assert_absent "$CLAUDE_ONLY_GEMINI/skills" "Claude-only leaves Gemini untouched"

echo "▶ Host-only installs"
CODEX_HOME_ONLY="$TEST_ROOT/codex-only-home"
CODEX_ONLY="$TEST_ROOT/codex-only"
CODEX_GEMINI="$TEST_ROOT/codex-only-gemini"
mkdir -p "$CODEX_HOME_ONLY" "$CODEX_ONLY" "$CODEX_GEMINI"
HOME="$CODEX_HOME_ONLY" CODEX_HOME="$CODEX_ONLY" GEMINI_HOME="$CODEX_GEMINI" bash "$ROOT/install.sh" --codex-only >/dev/null
assert_file "$CODEX_ONLY/skills/under-claw-jarvis-plan/SKILL.md" "Codex-only install"
assert_file "$CODEX_ONLY/skills/under-claw-jarvis-plan-loop/SKILL.md" "Codex-only loop install"
assert_file "$CODEX_ONLY/skills/under-claw-meta-prompt/SKILL.md" "Codex-only meta-prompt install"
assert_absent "$CODEX_HOME_ONLY/.claude" "Codex-only leaves Claude untouched"
assert_absent "$CODEX_GEMINI/skills" "Codex-only leaves Gemini untouched"
printf 'codex sentinel\n' > "$CODEX_ONLY/skills/under-claw-jarvis-plan/sentinel.txt"
HOME="$CODEX_HOME_ONLY" CODEX_HOME="$CODEX_ONLY" GEMINI_HOME="$CODEX_GEMINI" bash "$ROOT/install.sh" --codex-only >/dev/null
CODEX_BACKUP="$(find "$CODEX_HOME_ONLY" -maxdepth 1 -type d -name '.under-claw-jarvis-plan-backup-*' | head -1)"
assert_file "$CODEX_BACKUP/codex/skills/under-claw-jarvis-plan/sentinel.txt" "Codex backup preserved"

GEMINI_HOME_ONLY="$TEST_ROOT/gemini-only-home"
GEMINI_CODEX="$TEST_ROOT/gemini-only-codex"
GEMINI_ONLY="$TEST_ROOT/gemini-only"
mkdir -p "$GEMINI_HOME_ONLY" "$GEMINI_CODEX" "$GEMINI_ONLY"
HOME="$GEMINI_HOME_ONLY" CODEX_HOME="$GEMINI_CODEX" GEMINI_HOME="$GEMINI_ONLY" bash "$ROOT/install.sh" --gemini-only >/dev/null
assert_file "$GEMINI_ONLY/skills/under-claw-jarvis-plan/GEMINI.md" "Gemini-only install"
assert_file "$GEMINI_ONLY/skills/under-claw-jarvis-plan-loop/GEMINI.md" "Gemini-only loop install"
assert_file "$GEMINI_ONLY/skills/under-claw-meta-prompt/GEMINI.md" "Gemini-only meta-prompt install"
assert_absent "$GEMINI_HOME_ONLY/.claude" "Gemini-only leaves Claude untouched"
assert_absent "$GEMINI_CODEX/skills" "Gemini-only leaves Codex untouched"
printf 'gemini sentinel\n' > "$GEMINI_ONLY/skills/under-claw-jarvis-plan/sentinel.txt"
HOME="$GEMINI_HOME_ONLY" CODEX_HOME="$GEMINI_CODEX" GEMINI_HOME="$GEMINI_ONLY" bash "$ROOT/install.sh" --gemini-only >/dev/null
GEMINI_BACKUP="$(find "$GEMINI_HOME_ONLY" -maxdepth 1 -type d -name '.under-claw-jarvis-plan-backup-*' | head -1)"
assert_file "$GEMINI_BACKUP/gemini/skills/under-claw-jarvis-plan/sentinel.txt" "Gemini backup preserved"

echo "▶ Invalid options fail before mutation"
INVALID_HOME="$TEST_ROOT/invalid-home"
INVALID_CODEX="$INVALID_HOME/codex"; INVALID_GEMINI="$INVALID_HOME/gemini"
HOME="$INVALID_HOME" CODEX_HOME="$INVALID_CODEX" GEMINI_HOME="$INVALID_GEMINI" bash "$ROOT/install.sh" --does-not-exist >/dev/null 2>&1
INVALID_RC=$?
[[ "$INVALID_RC" == "2" ]] && ok "Unknown option rejected with exit 2" || bad "Unknown option rejected with exit 2"
[[ ! -e "$INVALID_HOME" ]] && ok "Unknown option makes no changes" || bad "Unknown option makes no changes"

CONFLICT_HOME="$TEST_ROOT/conflict-home"
CONFLICT_CODEX="$CONFLICT_HOME/codex"; CONFLICT_GEMINI="$CONFLICT_HOME/gemini"
HOME="$CONFLICT_HOME" CODEX_HOME="$CONFLICT_CODEX" GEMINI_HOME="$CONFLICT_GEMINI" bash "$ROOT/install.sh" --codex-only --gemini-only >/dev/null 2>&1
CONFLICT_RC=$?
[[ "$CONFLICT_RC" == "2" ]] && ok "Conflicting options rejected with exit 2" || bad "Conflicting options rejected with exit 2"
[[ ! -e "$CONFLICT_HOME" ]] && ok "Conflicting options make no changes" || bad "Conflicting options make no changes"

echo "── install result: PASS=$PASS FAIL=$FAIL ──"
[[ "$FAIL" == 0 ]]
