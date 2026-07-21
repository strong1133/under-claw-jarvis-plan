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
  HOME="$HOME_DIR" CODEX_HOME="$CODEX_DIR" GEMINI_HOME="$GEMINI_DIR" \
    bash "$ROOT/install.sh" "$@" >/dev/null
}

echo "▶ Claude skill-only install"
run_install --skill-only
assert_file "$HOME_DIR/.claude/commands/under-claw-jarvis-plan.md" "Claude command installed"
assert_file "$HOME_DIR/.claude/skills/under-claw-jarvis-plan/SKILL.md" "Claude base skill installed"
assert_file "$HOME_DIR/.claude/skills/under-claw-jarvis-plan-loop/SKILL.md" "Claude loop skill installed"
assert_absent "$CODEX_DIR/skills/under-claw-jarvis-plan" "Codex untouched by --skill-only"
assert_absent "$GEMINI_DIR/skills/under-claw-jarvis-plan" "Gemini untouched by --skill-only"
assert_absent "$HOME_DIR/.claude/skills/.sources" "Externals omitted by --skill-only"

echo "▶ Reinstall backup"
printf 'command sentinel\n' > "$HOME_DIR/.claude/commands/under-claw-jarvis-plan.md"
printf 'skill sentinel\n' > "$HOME_DIR/.claude/skills/under-claw-jarvis-plan/sentinel.txt"
run_install --skill-only
BACKUP_DIR="$(find "$HOME_DIR" -maxdepth 1 -type d -name '.under-claw-jarvis-plan-backup-*' | head -1)"
assert_file "$BACKUP_DIR/claude/commands/under-claw-jarvis-plan.md" "Command backup preserved"
assert_file "$BACKUP_DIR/claude/skills/under-claw-jarvis-plan/sentinel.txt" "Skill tree backup preserved"
grep -q 'command sentinel' "$BACKUP_DIR/claude/commands/under-claw-jarvis-plan.md" \
  && ok "Backup content preserved" || bad "Backup content preserved"

echo "▶ Host-only installs"
CODEX_HOME_ONLY="$TEST_ROOT/codex-only-home"
CODEX_ONLY="$TEST_ROOT/codex-only"
CODEX_GEMINI="$TEST_ROOT/codex-only-gemini"
mkdir -p "$CODEX_HOME_ONLY" "$CODEX_ONLY" "$CODEX_GEMINI"
HOME="$CODEX_HOME_ONLY" CODEX_HOME="$CODEX_ONLY" GEMINI_HOME="$CODEX_GEMINI" bash "$ROOT/install.sh" --codex-only >/dev/null
assert_file "$CODEX_ONLY/skills/under-claw-jarvis-plan/SKILL.md" "Codex-only install"
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
