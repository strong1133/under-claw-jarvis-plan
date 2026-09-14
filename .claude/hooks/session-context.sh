#!/usr/bin/env bash
# SessionStart — 세션 시작 시 "이 작업트리가 작업 가능한 상태인가"만 빠르게 점검해 모델에 주입한다.
#
# 여기서 잡으려는 것은 매번 같은 삽질을 반복하게 만드는 환경 문제다:
#   submodule 미초기화 · 개인 설정 부재 · 지침 구조 깨짐 · 템플릿 미기입.
# 빌드/테스트는 돌리지 않는다 (세션 시작이 느려지면 아무도 안 쓴다).
set -uo pipefail

cat >/dev/null 2>&1 || true   ### stdin 소비

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

notes=()

### submodule 이 선언돼 있는데 체크아웃되지 않으면 빌드도 지침 검증도 헛돈다
if [ -f .gitmodules ]; then
  while IFS= read -r line; do
    case "$line" in
      -*) notes+=("submodule 미초기화: ${line#-} → git submodule update --init") ;;
    esac
  done < <(git submodule status 2>/dev/null)
fi

[ -f CLAUDE.local.md ] || notes+=("CLAUDE.local.md 없음 — 개인 메모는 이 파일에 (공용 AGENTS.md 에 쓰지 말 것)")

if grep -q '{{' AGENTS.md 2>/dev/null; then
  notes+=("AGENTS.md 에 템플릿 플레이스홀더가 남아 있음 — ./tools/init-template.sh --check")
fi

if [ -x tools/verify-instructions.sh ]; then
  if ! out=$(./tools/verify-instructions.sh 2>&1); then
    notes+=("지침 구조 검증 실패: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-300)")
  fi
fi

[ ${#notes[@]} -eq 0 ] && exit 0

msg="작업트리 상태 점검:"
for n in "${notes[@]}"; do msg="${msg}
- ${n}"; done

if command -v jq >/dev/null 2>&1; then
  jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  printf '%s\n' "$msg"
fi

exit 0
