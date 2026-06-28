#!/usr/bin/env bash
# under-claw-jarvis-plan 설치 — Claude 스킬 + 의존(외부 참조) 스킬, 또는 Codex 스킬을 설치한다.
#
# 한 줄 설치(터미널):
#   curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
#   → Claude: under-claw-jarvis-plan + under-claw-jarvis-plan-loop + Karpathy / Superpowers / Understand-Anything / skill-creator 까지 모두 설치
#
# 옵션:
#   ./install.sh                  기본 = Claude 스킬 + 의존(외부 참조) 스킬 모두 설치
#   ./install.sh --skill-only     Claude under-claw-jarvis-plan 스킬만(의존 제외)
#   ./install.sh --externals-only Claude 의존(외부 참조) 스킬만
#   ./install.sh --codex          Claude 기본 설치 + Codex 스킬도 설치
#   ./install.sh --codex-only     Codex 스킬만 ${CODEX_HOME:-~/.codex}/skills 에 설치
#   ./install.sh --gemini         Claude 기본 설치 + Gemini 스킬도 설치
#   ./install.sh --gemini-only    Gemini 스킬만 ${GEMINI_HOME:-~/.gemini}/skills 에 설치
#
# under-claw-jarvis-plan 자체는 외부 스킬 없이도 동작(방법론을 자체 reference로 내장). 의존 설치는 원본 강화용.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"   # = 레포 루트
REPO_URL="https://github.com/strong1133/under-claw-jarvis-plan"

# 원격 부트스트랩: 레포 파일 없이(curl ... | bash) 실행되면 임시 클론 후 재실행한다.
if [[ ! -f "$SRC_DIR/commands/under-claw-jarvis-plan.md" ]]; then
  command -v git >/dev/null || { echo "[실패] git 필요(원격 설치)"; exit 1; }
  TMP="$(mktemp -d)"; echo "원격 설치 — 임시 클론: $TMP/repo"
  git clone --depth 1 -q "$REPO_URL" "$TMP/repo" || { echo "[실패] 클론"; exit 1; }
  exec bash "$TMP/repo/install.sh" "$@"
fi

CLAUDE_DEST="$HOME/.claude"
CODEX_DEST="${CODEX_HOME:-$HOME/.codex}/skills"
GEMINI_DEST="${GEMINI_HOME:-$HOME/.gemini}/skills"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.under-claw-jarvis-plan-backup-$TS"

INSTALL_CLAUDE=1
INSTALL_CODEX=0
INSTALL_GEMINI=0
WITH_EXTERNALS=1   # 기본: 의존(외부 참조) 스킬까지 설치
EXTERNALS_ONLY=0
for a in "$@"; do
  case "$a" in
    --skill-only)     WITH_EXTERNALS=0 ;;
    --with-externals) WITH_EXTERNALS=1 ;;   # 기본값(하위호환 no-op)
    --externals-only) WITH_EXTERNALS=1; EXTERNALS_ONLY=1; INSTALL_CLAUDE=0; INSTALL_CODEX=0; INSTALL_GEMINI=0 ;;
    --codex)          INSTALL_CODEX=1 ;;
    --codex-only)     INSTALL_CLAUDE=0; INSTALL_CODEX=1; WITH_EXTERNALS=0 ;;
    --gemini)         INSTALL_GEMINI=1 ;;
    --gemini-only)    INSTALL_CLAUDE=0; INSTALL_GEMINI=1; WITH_EXTERNALS=0 ;;
    --claude-only)    INSTALL_CLAUDE=1; INSTALL_CODEX=0; INSTALL_GEMINI=0 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[경고] 알 수 없는 옵션: $a" >&2 ;;
  esac
done

backup() { local p="$1"; [[ -e "$p" ]] || return 0; mkdir -p "$BACKUP_ROOT"; cp -R "$p" "$BACKUP_ROOT/" && echo "  [백업] $p"; }

# 베이스 + 루프 스킬을 한 묶음으로 설치한다.
SKILLS="under-claw-jarvis-plan under-claw-jarvis-plan-loop"

install_skill() {
  echo "▶ under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$CLAUDE_DEST/commands" "$CLAUDE_DEST/skills"
  for cmd in under-claw-jarvis-plan under-claw-jarvis-plan-loop; do
    backup "$CLAUDE_DEST/commands/$cmd.md"
    cp "$SRC_DIR/commands/$cmd.md" "$CLAUDE_DEST/commands/$cmd.md"
    echo "  [설치] ~/.claude/commands/$cmd.md"
  done
  for s in $SKILLS; do
    backup "$CLAUDE_DEST/skills/$s"
    rm -rf "$CLAUDE_DEST/skills/$s"
    cp -R "$SRC_DIR/skills/$s" "$CLAUDE_DEST/skills/$s"
    echo "  [설치] ~/.claude/skills/$s/ ($(find "$CLAUDE_DEST/skills/$s" -name '*.md' | wc -l | tr -d ' ')개)"
  done
}

install_codex_skill() {
  echo "▶ Codex under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$CODEX_DEST"
  for s in $SKILLS; do
    backup "$CODEX_DEST/$s"
    rm -rf "$CODEX_DEST/$s"
    cp -R "$SRC_DIR/skills/$s" "$CODEX_DEST/$s"
    echo "  [설치] ${CODEX_DEST/#$HOME/~}/$s/ ($(find "$CODEX_DEST/$s" -name '*.md' | wc -l | tr -d ' ')개)"
  done
}

install_gemini_skill() {
  echo "▶ Gemini under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$GEMINI_DEST"
  for s in $SKILLS; do
    backup "$GEMINI_DEST/$s"
    rm -rf "$GEMINI_DEST/$s"
    cp -R "$SRC_DIR/skills/$s" "$GEMINI_DEST/$s"
    echo "  [설치] ${GEMINI_DEST/#$HOME/~}/$s/ (진입점: GEMINI.md)"
  done
}

CACHE="$CLAUDE_DEST/skills/.sources"
clone() { command -v git >/dev/null || { echo "  [실패] git 미설치"; return 1; }; mkdir -p "$CACHE"; rm -rf "$CACHE/$2"; git clone --depth 1 -q "$1" "$CACHE/$2" 2>/dev/null && echo "  [클론] $2" || { echo "  [실패] $2"; return 1; }; }
copy_skill() { [[ -d "$1" ]] || { echo "  [건너뜀] $2"; return 1; }; rm -rf "$CLAUDE_DEST/skills/$2"; cp -R "$1" "$CLAUDE_DEST/skills/$2"; echo "  [설치] ~/.claude/skills/$2"; }

install_externals() {
  echo "▶ 원본 스킬 설치(best-effort)"
  clone https://github.com/multica-ai/andrej-karpathy-skills karpathy && copy_skill "$CACHE/karpathy/skills/karpathy-guidelines" karpathy-guidelines || true
  if clone https://github.com/obra/superpowers superpowers && [[ -d "$CACHE/superpowers/skills" ]]; then
    local c=0; for d in "$CACHE/superpowers/skills"/*/; do [[ -f "${d}SKILL.md" ]] || continue; rm -rf "$CLAUDE_DEST/skills/$(basename "$d")"; cp -R "$d" "$CLAUDE_DEST/skills/$(basename "$d")"; c=$((c+1)); done
    echo "  [설치] Superpowers 스킬 ${c}개"
  fi
  clone https://github.com/anthropics/skills anthropic-skills && copy_skill "$CACHE/anthropic-skills/skills/skill-creator" skill-creator || true
  if clone https://github.com/Egonex-AI/Understand-Anything understand-anything; then
    echo "  [안내] Understand-Anything 은 pnpm 플러그인. 수동: cd $CACHE/understand-anything && bash install.sh"
  fi
}

echo "under-claw-jarvis-plan 설치 (SSOT: $SRC_DIR)"
[[ "$INSTALL_CLAUDE" == "1" && "$EXTERNALS_ONLY" != "1" ]] && install_skill
[[ "$INSTALL_CODEX" == "1" ]] && install_codex_skill
[[ "$INSTALL_GEMINI" == "1" ]] && install_gemini_skill
[[ "$WITH_EXTERNALS" == "1" ]] && install_externals
[[ -d "$BACKUP_ROOT" ]] && echo "기존 파일 백업: $BACKUP_ROOT"
[[ "$WITH_EXTERNALS" == "1" ]] && echo "Claude 의존(외부 참조) 스킬 포함 설치 완료." || echo "의존 제외 설치."
[[ "$INSTALL_CODEX" == "1" ]] && echo 'Codex 설치 완료. 새 Codex 세션에서 $under-claw-jarvis-plan 사용 가능.'
[[ "$INSTALL_GEMINI" == "1" ]] && echo 'Gemini 설치 완료. 새 Gemini 세션에서 under-claw-jarvis-plan 진입점(GEMINI.md) 사용 가능.'
[[ "$INSTALL_CLAUDE" == "1" || "$WITH_EXTERNALS" == "1" ]] && echo "완료. 새 Claude 세션에서 /under-claw-jarvis-plan 사용 가능."
[[ "$INSTALL_CLAUDE" != "1" && "$WITH_EXTERNALS" != "1" ]] && echo "완료."
exit 0
