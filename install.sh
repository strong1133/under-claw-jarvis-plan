#!/usr/bin/env bash
# under-claw-jarvis-plan 스킬 설치 — ~/.claude 에 스킬만 설치한다.
#
# 사용법:
#   ./install.sh                  스킬 설치(commands + references) → ~/.claude
#   ./install.sh --with-externals + 원본 스킬(Karpathy/Superpowers/Skill-Creator/Understand-Anything) 설치
#   ./install.sh --externals-only 원본 스킬만
#
# 이 레포는 **스킬만** 담는다. 2-pane 런처/alias/persona 같은 실행 환경은 각자 환경에서 준비한다.
# (스킬은 단독 Claude 세션의 `/under-claw-jarvis-plan` 로도, 2-pane 환경에서도 동작한다.)

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"   # = 레포 루트
DEST="$HOME/.claude"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.under-claw-jarvis-plan-backup-$TS"

WITH_EXTERNALS=0
EXTERNALS_ONLY=0
for a in "$@"; do
  case "$a" in
    --with-externals) WITH_EXTERNALS=1 ;;
    --externals-only) WITH_EXTERNALS=1; EXTERNALS_ONLY=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[경고] 알 수 없는 옵션: $a" >&2 ;;
  esac
done

backup() { local p="$1"; [[ -e "$p" ]] || return 0; mkdir -p "$BACKUP_ROOT"; cp -R "$p" "$BACKUP_ROOT/" && echo "  [백업] $p"; }

install_skill() {
  echo "▶ under-claw-jarvis-plan 스킬 설치"
  mkdir -p "$DEST/commands" "$DEST/skills"
  backup "$DEST/commands/under-claw-jarvis-plan.md"
  cp "$SRC_DIR/commands/under-claw-jarvis-plan.md" "$DEST/commands/under-claw-jarvis-plan.md"
  echo "  [설치] ~/.claude/commands/under-claw-jarvis-plan.md"
  backup "$DEST/skills/under-claw-jarvis-plan"
  rm -rf "$DEST/skills/under-claw-jarvis-plan"
  cp -R "$SRC_DIR/skills/under-claw-jarvis-plan" "$DEST/skills/under-claw-jarvis-plan"
  echo "  [설치] ~/.claude/skills/under-claw-jarvis-plan/ ($(find "$DEST/skills/under-claw-jarvis-plan" -name '*.md' | wc -l | tr -d ' ')개)"
  echo "  구성: $(ls "$DEST/skills/under-claw-jarvis-plan/references" 2>/dev/null | sed 's/\.md$//' | paste -sd' ' -)"
}

CACHE="$DEST/skills/.sources"
clone() { command -v git >/dev/null || { echo "  [실패] git 미설치"; return 1; }; mkdir -p "$CACHE"; rm -rf "$CACHE/$2"; git clone --depth 1 -q "$1" "$CACHE/$2" 2>/dev/null && echo "  [클론] $2" || { echo "  [실패] $2"; return 1; }; }
copy_skill() { [[ -d "$1" ]] || { echo "  [건너뜀] $2"; return 1; }; rm -rf "$DEST/skills/$2"; cp -R "$1" "$DEST/skills/$2"; echo "  [설치] ~/.claude/skills/$2"; }

install_externals() {
  echo "▶ 원본 스킬 설치(best-effort)"
  clone https://github.com/multica-ai/andrej-karpathy-skills karpathy && copy_skill "$CACHE/karpathy/skills/karpathy-guidelines" karpathy-guidelines || true
  if clone https://github.com/obra/superpowers superpowers && [[ -d "$CACHE/superpowers/skills" ]]; then
    local c=0; for d in "$CACHE/superpowers/skills"/*/; do [[ -f "${d}SKILL.md" ]] || continue; rm -rf "$DEST/skills/$(basename "$d")"; cp -R "$d" "$DEST/skills/$(basename "$d")"; c=$((c+1)); done
    echo "  [설치] Superpowers 스킬 ${c}개"
  fi
  clone https://github.com/anthropics/skills anthropic-skills && copy_skill "$CACHE/anthropic-skills/skills/skill-creator" skill-creator || true
  if clone https://github.com/Egonex-AI/Understand-Anything understand-anything; then
    echo "  [안내] Understand-Anything 은 pnpm 플러그인. 수동: cd $CACHE/understand-anything && bash install.sh"
  fi
}

echo "under-claw-jarvis-plan 설치 (SSOT: $SRC_DIR)"
[[ "$EXTERNALS_ONLY" == "1" ]] || install_skill
[[ "$WITH_EXTERNALS" == "1" ]] && install_externals
[[ -d "$BACKUP_ROOT" ]] && echo "기존 파일 백업: $BACKUP_ROOT"
echo "완료. 새 세션에서 /under-claw-jarvis-plan 사용 가능."
exit 0
