#!/usr/bin/env bash
# 템플릿을 실제 프로젝트에 얹을 때 쓰는 부트스트랩.
#
#   ./tools/init-template.sh --check          # 남은 플레이스홀더와 할 일만 보고 (기본값)
#   ./tools/init-template.sh --set KEY=VALUE  # {{KEY}} 를 VALUE 로 일괄 치환 (반복 가능)
#   ./tools/init-template.sh --fix-perms      # 스크립트 실행 권한 복구
#
# 파일을 지우거나 옮기지 않는다. 치환은 요청한 키만 건드린다.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1

TARGETS=(AGENTS.md CLAUDE.local.md.example .worktreeinclude .mcp.json.example
         .claude .codex .agents docs tools example-module .github)

scan_paths() {
  find "${TARGETS[@]}" -type f \( -name '*.md' -o -name '*.json' -o -name '*.toml' \
       -o -name '*.js' -o -name '*.sh' -o -name '*.yml' -o -name '*.example' \) 2>/dev/null
}

mode=check
declare -a assignments=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode=check ;;
    --fix-perms) mode=perms ;;
    --set) shift; assignments+=("${1:-}"); mode=set ;;
    *) echo "알 수 없는 옵션: $1"; exit 2 ;;
  esac
  shift
done

if [ "$mode" = "perms" ]; then
  chmod +x tools/*.sh .claude/hooks/*.sh 2>/dev/null
  ls -l tools/*.sh .claude/hooks/*.sh | awk '{print $1, $NF}'
  exit 0
fi

if [ "$mode" = "set" ]; then
  for a in "${assignments[@]}"; do
    key="${a%%=*}"; val="${a#*=}"
    [ "$key" = "$a" ] && { echo "형식 오류(KEY=VALUE): $a"; exit 2; }
    count=0
    while IFS= read -r f; do
      grep -qF "{{${key}}}" "$f" || continue
      ### macOS/GNU sed 호환을 위해 임시 파일 경유
      tmp="${f}.tmpl.$$"
      KEY="$key" VAL="$val" perl -pe 's/\Q{{$ENV{KEY}}}\E/$ENV{VAL}/g' "$f" > "$tmp" && mv "$tmp" "$f"
      count=$((count+1))
    done < <(scan_paths)
    echo "치환: {{${key}}} → ${val}  (${count}개 파일)"
  done
fi

echo
echo "=== 남은 플레이스홀더 ==="
### LC_ALL=C 필수 — UTF-8 로케일에서는 sort/uniq 가 한글 문자열을 collation 으로 묶어
### 서로 다른 플레이스홀더를 한 덩어리로 오집계한다 (개수가 몇 배로 부풀어 오른다)
remaining=$(scan_paths | xargs grep -ohE '\{\{[^}]+\}\}' 2>/dev/null \
  | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C sort -rn)
if [ -z "$remaining" ]; then
  echo "없음"
else
  echo "$remaining" | head -40
  total=$(echo "$remaining" | wc -l | tr -d ' ')
  echo "... 고유 플레이스홀더 ${total}종"
fi

echo
echo "=== 남은 할 일 ==="
[ -f CLAUDE.local.md ]              || echo "- CLAUDE.local.md.example → CLAUDE.local.md 복사 (개인 메모)"
[ -f .claude/settings.local.json ]  || echo "- .claude/settings.local.json.example → 필요 시 복사"
[ -f .mcp.json ]                    || echo "- 팀 공유 MCP 서버가 있으면 .mcp.json.example → .mcp.json"
grep -q 'CLAUDE.local.md' .gitignore 2>/dev/null || echo "- .gitignore 에 AI 개인 파일 섹션 병합"
[ -d example-module ] && echo "- example-module/ 을 실제 모듈로 옮기거나 삭제"
grep -q '{{' AGENTS.md 2>/dev/null && echo "- AGENTS.md 플레이스홀더 기입 (가장 먼저)"

echo
echo "=== 구조 검증 ==="
./tools/verify-instructions.sh
