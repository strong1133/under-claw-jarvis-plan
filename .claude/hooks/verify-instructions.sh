#!/usr/bin/env bash
# PostToolUse(Edit|Write) — 지침 파일을 고친 직후에만 구조 검증을 돌린다.
# 커밋 시점이 아니라 편집 직후에 잡는 것이 목적이라 대상 파일을 좁게 건다.
#
# stdin: {"tool_response":{"filePath":"..."},"tool_input":{"file_path":"..."}}
# stdout: 실패 시 decision=block JSON — 모델이 그 자리에서 고치게 한다.
set -uo pipefail

payload="$(cat)"
file_path="$(printf '%s' "$payload" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)"

[ -z "$file_path" ] && exit 0

case "$file_path" in
  *AGENTS.md|*CLAUDE.md|*/.claude/*|*/.codex/*|*/.agents/*|*.gitignore) ;;
  *) exit 0 ;;
esac

repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null)"
[ -z "$repo_root" ] && exit 0

checker="$repo_root/tools/verify-instructions.sh"
[ -x "$checker" ] || exit 0

output="$(cd "$repo_root" && "$checker" 2>&1)"
status=$?

if [ $status -ne 0 ]; then
  jq -n --arg out "$output" '{
    decision: "block",
    reason: ("지침 구조 검증 실패 — 고친 뒤 진행하세요.\n" + $out)
  }'
fi

exit 0
