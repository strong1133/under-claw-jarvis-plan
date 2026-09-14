#!/bin/sh
# Codex PostToolUse 훅 래퍼.
#
# Codex 훅의 stdin 페이로드 스키마는 Claude Code 와 동일하다고 보장되지 않는다.
# 그래서 이 래퍼는 페이로드를 파싱하지 않고, 검증기를 그냥 돌린 뒤 결과를 stdout 에 남긴다.
# (편집 대상 파일로 필터링하고 싶다면, 먼저 아래 DEBUG 절차로 실제 필드명을 확인한 뒤 파싱을 추가할 것.)
#
# 페이로드 확인 방법:
#   .codex/hooks.json 의 command 를 임시로 `cat >> /tmp/codex-hook-payload.json` 으로 바꾸고
#   한 턴 실행한 뒤 /tmp/codex-hook-payload.json 을 읽는다. 확인 후 원복.
set -u

### stdin 을 소비하지 않으면 SIGPIPE 로 훅이 실패할 수 있다
cat >/dev/null 2>&1 || true

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
checker="$root/tools/verify-instructions.sh"
[ -x "$checker" ] || exit 0

output=$(cd "$root" && "$checker" 2>&1)
if [ $? -ne 0 ]; then
  echo "지침 구조 검증 실패:"
  echo "$output"
fi

exit 0
