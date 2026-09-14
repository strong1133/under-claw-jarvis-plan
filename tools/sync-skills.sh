#!/usr/bin/env bash
# .claude/skills → .agents/skills 미러링.
# Claude Code 는 .claude/skills, Codex 는 .agents/skills 를 읽는다. 포맷(SKILL.md + name/description
# frontmatter)이 동일하므로 한쪽을 정본으로 두고 복사한다. 정본은 .claude/skills.
#
# 사용: ./tools/sync-skills.sh          # 미러 갱신
#      ./tools/sync-skills.sh --check   # 차이만 보고 (CI 용, 변경 없음)
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"

SRC=.claude/skills
DST=.agents/skills

[ -d "$SRC" ] || { echo "$SRC 없음 — 미러할 스킬이 없다"; exit 0; }

if [ "${1:-}" = "--check" ]; then
  status=0
  for d in "$SRC"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    if ! diff -r -q "$d" "$DST/$name" >/dev/null 2>&1; then
      echo "차이: $name"
      status=1
    fi
  done
  [ $status -eq 0 ] && echo "동기화 상태 정상"
  exit $status
fi

mkdir -p "$DST"

### 미러 쪽을 직접 고친 경우 덮어쓰면 그 수정이 사라진다 — 먼저 경고한다
for d in "$SRC"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  [ -d "$DST/$name" ] || continue
  if [ -n "$(find "$DST/$name" -newer "$d" -type f 2>/dev/null)" ]; then
    echo "경고: $DST/$name 이 정본보다 최신입니다 — 미러를 직접 고쳤다면 그 수정이 사라집니다."
    printf '  계속할까요? [y/N] '
    read -r ans </dev/tty 2>/dev/null || ans=n
    case "$ans" in [yY]*) ;; *) echo "중단."; exit 1 ;; esac
  fi
done

### 정본에서 사라진 스킬은 미러에서도 제거한다
for d in "$DST"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  [ -d "$SRC/$name" ] || { echo "삭제: $name"; rm -rf "$d"; }
done

for d in "$SRC"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  rm -rf "${DST:?}/$name"
  cp -R "$d" "$DST/$name"
  echo "동기화: $name"
done

echo "완료 — $DST 갱신됨. 커밋에 함께 포함할 것."
