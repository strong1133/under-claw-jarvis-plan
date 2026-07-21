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

TEMP_PATHS=()
ROLLBACK_DESTS=()
ROLLBACK_PATHS=()
register_temp() { TEMP_PATHS+=("$1"); }
cleanup() {
  local status=$? i p dest
  for ((i=0; i<${#ROLLBACK_PATHS[@]}; i++)); do
    p="${ROLLBACK_PATHS[$i]}"; dest="${ROLLBACK_DESTS[$i]}"
    [[ -n "$p" && ( -e "$p" || -L "$p" ) ]] || continue
    if [[ ! -e "$dest" && ! -L "$dest" ]]; then mv "$p" "$dest"; else rm -rf -- "$p"; fi
  done
  if ((${#TEMP_PATHS[@]})); then
    for p in "${TEMP_PATHS[@]}"; do
      [[ -n "$p" && -e "$p" ]] && rm -rf -- "$p"
    done
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

# 원격 부트스트랩: 레포 파일 없이(curl ... | bash) 실행되면 임시 클론 후 재실행한다.
if [[ ! -f "$SRC_DIR/commands/under-claw-jarvis-plan.md" ]]; then
  command -v git >/dev/null || { echo "[실패] git 필요(원격 설치)"; exit 1; }
  TMP="$(mktemp -d)"; register_temp "$TMP"; echo "원격 설치 — 임시 클론: $TMP/repo"
  git clone --depth 1 -q "$REPO_URL" "$TMP/repo" || { echo "[실패] 클론"; exit 1; }
  bash "$TMP/repo/install.sh" "$@"
  exit $?
fi

CLAUDE_DEST="$HOME/.claude"
CODEX_DEST="${CODEX_HOME:-$HOME/.codex}/skills"
GEMINI_DEST="${GEMINI_HOME:-$HOME/.gemini}/skills"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT=""

MODE="default"
ADD_CODEX=0
ADD_GEMINI=0
WITH_EXTERNALS_OVERRIDE=""
for a in "$@"; do
  case "$a" in
    --skill-only|--externals-only|--codex-only|--gemini-only|--claude-only)
      [[ "$MODE" == "default" ]] || { echo "[실패] *-only 옵션은 하나만 사용할 수 있습니다." >&2; exit 2; }
      MODE="${a#--}"
      ;;
    --with-externals) WITH_EXTERNALS_OVERRIDE=1 ;;
    --codex)          ADD_CODEX=1 ;;
    --gemini)         ADD_GEMINI=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[실패] 알 수 없는 옵션: $a" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" != "default" && ( "$ADD_CODEX" == "1" || "$ADD_GEMINI" == "1" ) ]]; then
  echo "[실패] *-only 옵션은 --codex/--gemini와 함께 사용할 수 없습니다." >&2
  exit 2
fi
if [[ -n "$WITH_EXTERNALS_OVERRIDE" && ( "$MODE" == "skill-only" || "$MODE" == "codex-only" || "$MODE" == "gemini-only" ) ]]; then
  echo "[실패] 이 *-only 옵션은 --with-externals와 함께 사용할 수 없습니다." >&2
  exit 2
fi

INSTALL_CLAUDE=1
INSTALL_CODEX="$ADD_CODEX"
INSTALL_GEMINI="$ADD_GEMINI"
WITH_EXTERNALS=1
EXTERNALS_ONLY=0
case "$MODE" in
  default|claude-only) ;;
  skill-only) INSTALL_CLAUDE=1; WITH_EXTERNALS=0 ;;
  externals-only) INSTALL_CLAUDE=0; INSTALL_CODEX=0; INSTALL_GEMINI=0; WITH_EXTERNALS=1; EXTERNALS_ONLY=1 ;;
  codex-only) INSTALL_CLAUDE=0; INSTALL_CODEX=1; INSTALL_GEMINI=0; WITH_EXTERNALS=0 ;;
  gemini-only) INSTALL_CLAUDE=0; INSTALL_CODEX=0; INSTALL_GEMINI=1; WITH_EXTERNALS=0 ;;
esac
[[ -n "$WITH_EXTERNALS_OVERRIDE" ]] && WITH_EXTERNALS="$WITH_EXTERNALS_OVERRIDE"

backup() {
  local p="$1" namespace="$2" name
  [[ -e "$p" || -L "$p" ]] || return 0
  if [[ -z "$BACKUP_ROOT" ]]; then
    BACKUP_ROOT="$(mktemp -d "$HOME/.under-claw-jarvis-plan-backup-$TS.XXXXXX")"
  fi
  name="$(basename "$p")"
  mkdir -p "$BACKUP_ROOT/$namespace"
  cp -R "$p" "$BACKUP_ROOT/$namespace/$name" || return 1
  echo "  [백업] $p"
}

install_file() {
  local src="$1" dest="$2" namespace="$3" parent stage
  parent="$(dirname "$dest")"; mkdir -p "$parent"
  stage="$(mktemp "$parent/.under-claw-file.XXXXXX")"; register_temp "$stage"
  cp "$src" "$stage" || return 1
  backup "$dest" "$namespace" || return 1
  mv -f "$stage" "$dest" || return 1
}

install_tree() {
  local src="$1" dest="$2" namespace="$3" required="${4:-}" parent stage rollback idx
  [[ -d "$src" ]] || { echo "  [실패] 설치 원본 없음: $src" >&2; return 1; }
  parent="$(dirname "$dest")"; mkdir -p "$parent"
  stage="$(mktemp -d "$parent/.under-claw-stage.XXXXXX")"; register_temp "$stage"
  cp -R "$src" "$stage/new" || return 1
  [[ -d "$stage/new" ]] || { echo "  [실패] staging 검증: $src" >&2; return 1; }
  [[ -z "$required" || -e "$stage/new/$required" ]] || { echo "  [실패] 필수 파일 없음: $required" >&2; return 1; }
  backup "$dest" "$namespace" || return 1
  rollback="$stage/previous"
  if [[ -e "$dest" || -L "$dest" ]]; then
    ROLLBACK_DESTS+=("$dest"); ROLLBACK_PATHS+=("$rollback"); idx=$((${#ROLLBACK_PATHS[@]}-1))
    if ! mv "$dest" "$rollback"; then ROLLBACK_PATHS[$idx]=""; return 1; fi
  else
    idx=-1
  fi
  if ! mv "$stage/new" "$dest"; then
    [[ -e "$rollback" || -L "$rollback" ]] && mv "$rollback" "$dest"
    [[ "$idx" -ge 0 ]] && ROLLBACK_PATHS[$idx]=""
    return 1
  fi
  if [[ "$idx" -ge 0 ]]; then
    rm -rf -- "$rollback"
    ROLLBACK_PATHS[$idx]=""
  fi
}

# 베이스 + 루프 스킬을 한 묶음으로 설치한다.
SKILLS="under-claw-jarvis-plan under-claw-jarvis-plan-loop"

install_skill() {
  echo "▶ under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$CLAUDE_DEST/commands" "$CLAUDE_DEST/skills"
  for cmd in under-claw-jarvis-plan under-claw-jarvis-plan-loop; do
    install_file "$SRC_DIR/commands/$cmd.md" "$CLAUDE_DEST/commands/$cmd.md" "claude/commands" || return 1
    echo "  [설치] ~/.claude/commands/$cmd.md"
  done
  for s in $SKILLS; do
    install_tree "$SRC_DIR/skills/$s" "$CLAUDE_DEST/skills/$s" "claude/skills" "SKILL.md" || return 1
    echo "  [설치] ~/.claude/skills/$s/ ($(find "$CLAUDE_DEST/skills/$s" -name '*.md' | wc -l | tr -d ' ')개)"
  done
}

install_codex_skill() {
  echo "▶ Codex under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$CODEX_DEST"
  for s in $SKILLS; do
    install_tree "$SRC_DIR/skills/$s" "$CODEX_DEST/$s" "codex/skills" "SKILL.md" || return 1
    echo "  [설치] $CODEX_DEST/$s/ ($(find "$CODEX_DEST/$s" -name '*.md' | wc -l | tr -d ' ')개)"
  done
}

install_gemini_skill() {
  echo "▶ Gemini under-claw-jarvis-plan (+ loop) 스킬 설치"
  mkdir -p "$GEMINI_DEST"
  for s in $SKILLS; do
    install_tree "$SRC_DIR/skills/$s" "$GEMINI_DEST/$s" "gemini/skills" "GEMINI.md" || return 1
    echo "  [설치] $GEMINI_DEST/$s/ (진입점: GEMINI.md)"
  done
}

CACHE="$CLAUDE_DEST/skills/.sources"
KARPATHY_SHA="2c606141936f1eeef17fa3043a72095b4765b9c2"
SUPERPOWERS_SHA="d884ae04edebef577e82ff7c4e143debd0bbec99"
ANTHROPIC_SKILLS_SHA="fa0fa64bdc967915dc8399e803be67759e1e62b8"
UNDERSTAND_ANYTHING_SHA="2f24580ba076592a1a6d766e47590836436f30f6"

clone_pinned() {
  local url="$1" name="$2" sha="$3" tmp actual
  command -v git >/dev/null || { echo "  [실패] git 미설치"; return 1; }
  tmp="$(mktemp -d)"; register_temp "$tmp"
  git -C "$tmp" init -q || return 1
  git -C "$tmp" remote add origin "$url" || return 1
  git -C "$tmp" fetch --depth 1 -q origin "$sha" || { echo "  [실패] $name fetch"; return 1; }
  git -C "$tmp" checkout --detach -q FETCH_HEAD || return 1
  actual="$(git -C "$tmp" rev-parse HEAD)" || return 1
  [[ "$actual" == "$sha" ]] || { echo "  [실패] $name revision 불일치"; return 1; }
  install_tree "$tmp" "$CACHE/$name" "claude/sources" || return 1
  echo "  [클론] $name@$sha"
}

copy_skill() {
  [[ -f "$1/SKILL.md" ]] || { echo "  [건너뜀] $2 (SKILL.md 없음)"; return 1; }
  install_tree "$1" "$CLAUDE_DEST/skills/$2" "claude/skills" "SKILL.md" || return 1
  echo "  [설치] ~/.claude/skills/$2"
}

install_externals() {
  echo "▶ 원본 스킬 설치(best-effort)"
  clone_pinned https://github.com/multica-ai/andrej-karpathy-skills karpathy "$KARPATHY_SHA" && copy_skill "$CACHE/karpathy/skills/karpathy-guidelines" karpathy-guidelines || true
  if clone_pinned https://github.com/obra/superpowers superpowers "$SUPERPOWERS_SHA" && [[ -d "$CACHE/superpowers/skills" ]]; then
    local c=0; for d in "$CACHE/superpowers/skills"/*/; do [[ -f "${d}SKILL.md" ]] || continue; copy_skill "$d" "$(basename "$d")" || continue; c=$((c+1)); done
    echo "  [설치] Superpowers 스킬 ${c}개"
  fi
  clone_pinned https://github.com/anthropics/skills anthropic-skills "$ANTHROPIC_SKILLS_SHA" && copy_skill "$CACHE/anthropic-skills/skills/skill-creator" skill-creator || true
  if clone_pinned https://github.com/Egonex-AI/Understand-Anything understand-anything "$UNDERSTAND_ANYTHING_SHA"; then
    echo "  [안내] Understand-Anything 은 pnpm 플러그인. 수동: cd $CACHE/understand-anything && bash install.sh"
  fi
}

echo "under-claw-jarvis-plan 설치 (SSOT: $SRC_DIR)"
if [[ "$INSTALL_CLAUDE" == "1" && "$EXTERNALS_ONLY" != "1" ]]; then install_skill; fi
if [[ "$INSTALL_CODEX" == "1" ]]; then install_codex_skill; fi
if [[ "$INSTALL_GEMINI" == "1" ]]; then install_gemini_skill; fi
if [[ "$WITH_EXTERNALS" == "1" ]]; then install_externals; fi
[[ -n "$BACKUP_ROOT" && -d "$BACKUP_ROOT" ]] && echo "기존 파일 백업: $BACKUP_ROOT"
[[ "$WITH_EXTERNALS" == "1" ]] && echo "Claude 의존(외부 참조) 스킬 포함 설치 완료." || echo "의존 제외 설치."
[[ "$INSTALL_CODEX" == "1" ]] && echo 'Codex 설치 완료. 새 Codex 세션에서 $under-claw-jarvis-plan 사용 가능.'
[[ "$INSTALL_GEMINI" == "1" ]] && echo 'Gemini 설치 완료. 새 Gemini 세션에서 under-claw-jarvis-plan 진입점(GEMINI.md) 사용 가능.'
[[ "$INSTALL_CLAUDE" == "1" || "$WITH_EXTERNALS" == "1" ]] && echo "완료. 새 Claude 세션에서 /under-claw-jarvis-plan 사용 가능."
[[ "$INSTALL_CLAUDE" != "1" && "$WITH_EXTERNALS" != "1" ]] && echo "완료."
exit 0
