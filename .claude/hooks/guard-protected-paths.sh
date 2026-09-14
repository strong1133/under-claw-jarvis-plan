#!/usr/bin/env bash
# PreToolUse(Edit|Write) — 보호 경로 수정 시 사용자 확인을 강제한다.
# 용도 예: 별도 저장소인 submodule, 생성 코드, 마이그레이션 이력처럼 "함부로 고치면 안 되는" 경로.
#
# stdin: {"tool_name":"Edit","tool_input":{"file_path":"..."}}
# stdout: permissionDecision=ask JSON (해당할 때만). 해당 없으면 아무것도 출력하지 않는다.
set -uo pipefail

### 보호할 경로 조각 — 프로젝트에 맞게 수정
PROTECTED_GLOBS=(
  "*/{{SUBMODULE_DIR}}/*"
  "*/generated/*"
  "*/db/migration/*"
)
PROTECTED_REASON="{{이 경로는 별도 커밋/PR 로 다뤄야 합니다 — AGENTS.md 구조 절 참조}}"

payload="$(cat)"
file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[ -z "$file_path" ] && exit 0

for glob in "${PROTECTED_GLOBS[@]}"; do
  # shellcheck disable=SC2254
  case "$file_path" in
    $glob)
      jq -n --arg f "$file_path" --arg why "$PROTECTED_REASON" '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "ask",
          permissionDecisionReason: ($f + " — " + $why)
        }
      }'
      exit 0
      ;;
  esac
done

exit 0
