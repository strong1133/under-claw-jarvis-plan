#!/usr/bin/env bash
# 지침 문서 구조 검증 (instruction lint) — 빌드 도구에 의존하지 않는 이식 가능 버전.
#
# 검사 항목
#   1. CLAUDE.md 가 정확히 "@AGENTS.md" bridge 인가
#   2. AGENTS.md 크기 예산 (기본 120줄 / 8KiB)
#   3. 필독 라우팅 표가 가리키는 문서가 실제로 존재하는가
#   4. .claude/rules/*.md 에 paths frontmatter 가 있는가 (없으면 상시 로딩되어 컨텍스트를 잡아먹음)
#   5. skills 각 폴더에 SKILL.md + name/description frontmatter 가 있는가
#   6. commands/agents/output-styles 의 md 에 frontmatter 가 있는가
#   7. workflows/*.js 가 'export const meta' 로 시작하는가
#   8. settings.json 이 유효 JSON 이고, 배선된 훅 스크립트가 존재하며 실행 가능한가
#   9. .claude/skills 와 .agents/skills (Codex) 가 동기화되어 있는가
#  10. .gitignore 에 개인 파일 항목이 있는가
#  11. .codex/hooks.json 이 유효 JSON 이고 참조 스크립트가 존재하는가
#
# 사용: ./tools/verify-instructions.sh    (실패 시 exit 1)
set -uo pipefail

MAX_LINES=${MAX_LINES:-120}
MAX_BYTES=${MAX_BYTES:-8192}

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1

errors=()
warns=()
err() { errors+=("$1"); }
warn() { warns+=("$1"); }
has_jq() { command -v jq >/dev/null 2>&1; }

## 1. bridge
if [ ! -f CLAUDE.md ] || [ "$(tr -d '[:space:]' < CLAUDE.md)" != "@AGENTS.md" ]; then
  err 'CLAUDE.md 는 정확히 "@AGENTS.md" 한 줄이어야 함'
fi

## 2. 루트 지침 크기 예산
if [ ! -f AGENTS.md ]; then
  err 'AGENTS.md 없음'
else
  lines=$(wc -l < AGENTS.md | tr -d ' ')
  bytes=$(wc -c < AGENTS.md | tr -d ' ')
  [ "$lines" -gt "$MAX_LINES" ] && err "AGENTS.md ${lines}줄 — ${MAX_LINES}줄 예산 초과"
  [ "$bytes" -gt "$MAX_BYTES" ] && err "AGENTS.md ${bytes}B — ${MAX_BYTES}B 예산 초과"

  ## 2-1. 개인/공용 분리 지침이 상시 계층에 있는가
  ## docs 에만 있으면 에이전트는 라우팅이 걸릴 때만 본다 — "기억해둬" 요청이 공용 파일로 새는 원인
  grep -qF 'CLAUDE.local.md' AGENTS.md \
    || err 'AGENTS.md 에 개인 파일(CLAUDE.local.md) 안내 없음 — 개인 메모가 공용 지침에 섞인다'

  ## 3. 라우팅 표 대상 존재 — 표의 마지막 열에서 백틱 경로를 뽑아 검사
  targets=$(awk -F'|' '/^\|/ && NF>2 {print $(NF-1)}' AGENTS.md \
    | grep -oE '`[^`]+`' | tr -d '`' | grep -vE '\{\{|\*' | sort -u)
  for t in $targets; do
    [ -e "$t" ] || err "라우팅 대상 없음: ${t}"
  done
fi

## 3-2. 하위 디렉터리 지침 계층 — AGENTS.md 옆에는 CLAUDE.md bridge 가 있어야 한다
## (없으면 Codex 만 읽고 Claude 는 못 읽는 반쪽 지침이 된다)
while IFS= read -r nested; do
  dir=$(dirname "$nested")
  [ "$dir" = "." ] && continue
  if [ ! -f "$dir/CLAUDE.md" ]; then
    err "${nested}: 같은 폴더에 CLAUDE.md bridge 없음 (Claude 가 못 읽음)"
  elif [ "$(tr -d '[:space:]' < "$dir/CLAUDE.md")" != "@AGENTS.md" ]; then
    err "${dir}/CLAUDE.md: 정확히 \"@AGENTS.md\" 한 줄이어야 함"
  fi
  nlines=$(wc -l < "$nested" | tr -d ' ')
  [ "$nlines" -gt "${MAX_NESTED_LINES:-40}" ] \
    && err "${nested} ${nlines}줄 — 하위 지침 ${MAX_NESTED_LINES:-40}줄 예산 초과 (docs 로 내릴 것)"
done < <(find . -name AGENTS.md -not -path './.git/*' -not -path './node_modules/*' -not -path './build/*' 2>/dev/null | sed 's|^\./||' | grep -v '^AGENTS.md$')

## 4. Claude path-scoped rules
if [ -d .claude/rules ]; then
  found_rule=0
  for f in .claude/rules/*.md; do
    [ -e "$f" ] || continue
    found_rule=1
    grep -qE '^paths:' "$f" || err "$(basename "$f"): paths frontmatter 없음 (무조건 로딩 rule 금지)"
  done
  [ "$found_rule" -eq 0 ] && warn '.claude/rules/*.md 없음 — 조건부 라우팅 계층 미사용'
fi

## 5. skills (Claude + Codex 양쪽 같은 포맷)
for base in .claude/skills .agents/skills; do
  [ -d "$base" ] || continue
  for d in "$base"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    if [ ! -f "${d}SKILL.md" ]; then
      err "${base}/${name}: SKILL.md 없음 (파일명 고정)"
      continue
    fi
    grep -qE '^name:' "${d}SKILL.md" || err "${base}/${name}: frontmatter 에 name 없음"
    grep -qE '^description:' "${d}SKILL.md" || err "${base}/${name}: frontmatter 에 description 없음"
  done
done

## 6. frontmatter 필요한 md
for dir in commands agents output-styles; do
  [ -d ".claude/$dir" ] || continue
  for f in .claude/"$dir"/*.md; do
    [ -e "$f" ] || continue
    head -1 "$f" | grep -qE '^---$' || err "${dir}/$(basename "$f"): frontmatter 없음"
  done
done

## 7. workflows
if [ -d .claude/workflows ]; then
  for f in .claude/workflows/*.js; do
    [ -e "$f" ] || continue
    head -1 "$f" | grep -q 'export const meta' \
      || err "workflows/$(basename "$f"): 'export const meta' 로 시작해야 함"
  done
fi

## 8. settings.json 과 훅 배선
if [ -f .claude/settings.json ]; then
  if has_jq; then
    if ! jq -e . .claude/settings.json >/dev/null 2>&1; then
      err '.claude/settings.json JSON 파싱 실패'
    else
      jq -r '.hooks // {} | to_entries[] | .key as $e | .value[].hooks[] | select(.type=="command") | "\($e)\t\(.command)"' \
        .claude/settings.json 2>/dev/null | while IFS=$'\t' read -r event cmd; do
          script=$(printf '%s' "$cmd" | grep -oE '\.claude/hooks/[A-Za-z0-9._-]+' | head -1)
          [ -z "$script" ] && continue
          if [ ! -f "$script" ]; then echo "ERR|${event}: 훅 스크립트 없음 — ${script}"
          elif [ ! -x "$script" ]; then echo "ERR|${event}: 훅 스크립트 실행 권한 없음 — ${script} (chmod +x)"
          fi
        done > /tmp/.instr-hook-check.$$ 2>/dev/null
      while IFS= read -r line; do err "${line#ERR|}"; done < /tmp/.instr-hook-check.$$
      rm -f /tmp/.instr-hook-check.$$
    fi
  else
    warn 'jq 없음 — settings.json 훅 배선 검사 생략'
  fi
fi

## 9. Claude ↔ Codex 스킬 동기화
if [ -d .claude/skills ] && [ -d .agents/skills ]; then
  for d in .claude/skills/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    mirror=".agents/skills/${name}"
    if [ ! -d "$mirror" ]; then
      err "스킬 미러 없음 — ${mirror} (Codex 가 이 스킬을 못 받음)"
    elif ! diff -r -q "$d" "$mirror" >/dev/null 2>&1; then
      err "스킬 내용 불일치 — .claude/skills/${name} 와 ${mirror} (tools/sync-skills.sh 실행)"
    fi
  done
fi

## 10. 개인 파일 gitignore
if [ -f .gitignore ]; then
  for entry in 'CLAUDE.local.md' '.claude/settings.local.json' '.claude/agent-memory/'; do
    grep -qF "$entry" .gitignore || err ".gitignore 에 ${entry} 없음"
  done
else
  err '.gitignore 없음'
fi

## 11. Codex 훅
if [ -f .codex/hooks.json ]; then
  if has_jq; then
    jq -e . .codex/hooks.json >/dev/null 2>&1 || err '.codex/hooks.json JSON 파싱 실패'
    for script in $(jq -r '.hooks // {} | to_entries[] | .value[].hooks[]? | select(.type=="command") | .command' .codex/hooks.json 2>/dev/null | grep -oE '\./tools/[A-Za-z0-9._-]+'); do
      [ -f "$script" ] || err "codex 훅 스크립트 없음 — ${script}"
    done
  fi
fi

## 11-1. 낡은 표현 재유입 차단 (tools/stale-patterns.txt 가 목록을 소유)
## 리팩터링으로 사라진 경로·클래스명·수치가 문서로 되돌아오는 것을 막는다
if [ -f tools/stale-patterns.txt ]; then
  ## instruction-antipatterns.md 는 "틀린 표현"을 나쁜 예시로 인용하는 것이 임무라 검사에서 제외한다.
  ## 다른 문서에서 예외가 필요하면 해당 줄에 stale-ok 를 남긴다.
  stale_targets=$( { find AGENTS.md .claude/rules docs/architecture docs/conventions -name '*.md' 2>/dev/null;
                     find . -name AGENTS.md -not -path './.git/*' 2>/dev/null | sed 's|^\./||' | grep -v '^AGENTS.md$'; } \
                   | grep -v 'instruction-antipatterns.md' )
  while IFS= read -r pattern; do
    case "$pattern" in ''|'#'*) continue ;; esac
    for f in $stale_targets; do
      [ -f "$f" ] || continue
      ### stale-ok 가 달린 줄은 의도적 인용으로 보고 넘긴다
      grep -F "$pattern" "$f" | grep -qv 'stale-ok' \
        && err "${f}: 낡은 표현 '${pattern}' 잔존 (tools/stale-patterns.txt)"
    done
  done < tools/stale-patterns.txt
fi

## 11-2. 권위 docs 헤더 — Status / Last verified 가 없으면 신선도를 아무도 못 판단한다
for f in docs/architecture/*.md docs/conventions/*.md; do
  [ -e "$f" ] || continue
  head -5 "$f" | grep -q 'Status:' || err "${f}: 상태 헤더 없음 (> Status: ... · Last verified: ...)"
  head -5 "$f" | grep -q 'Last verified:' || err "${f}: Last verified 없음"
done

## 11-3. .worktreeinclude 항목은 실제로 gitignore 대상이어야 의미가 있다
if [ -f .worktreeinclude ] && git rev-parse --git-dir >/dev/null 2>&1; then
  while IFS= read -r entry; do
    case "$entry" in ''|'#'*) continue ;; esac
    git check-ignore -q "$entry" 2>/dev/null \
      || warn ".worktreeinclude: ${entry} 는 gitignore 대상이 아님 (이미 커밋되는 파일이면 불필요)"
  done < .worktreeinclude
fi

## 12. 마크다운 상대 링크 — 죽은 링크는 라우팅을 끊는다
while IFS= read -r md; do
  base=$(dirname "$md")
  for link in $(grep -oE '\]\([^)#]+\.md[^)]*\)' "$md" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//; s/#.*$//'); do
    case "$link" in
      http*|*'{{'*) continue ;;
    esac
    [ -e "$base/$link" ] || err "${md}: 죽은 링크 — ${link}"
  done
done < <(find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's|^\./||')

## 13. ADR 파일명 규칙
if [ -d docs/adr ]; then
  for f in docs/adr/*.md; do
    [ -e "$f" ] || continue
    n=$(basename "$f")
    case "$n" in
      README.md|TEMPLATE.md) continue ;;
      [0-9][0-9][0-9][0-9]-*.md) ;;
      *) err "docs/adr/${n}: 파일명은 NNNN-kebab-case.md 형식이어야 함" ;;
    esac
  done
fi

## 14. 템플릿 플레이스홀더 잔존 — 실사용 저장소에서는 채워야 한다 (경고)
placeholder_files=$(grep -rl '{{' --include='*.md' --include='*.json' --include='*.toml' --include='*.yml' \
  . 2>/dev/null | grep -v '^./.git/' | wc -l | tr -d ' ')
[ "${placeholder_files:-0}" -gt 0 ] \
  && warn "플레이스홀더가 남은 파일 ${placeholder_files}개 — ./tools/init-template.sh 로 확인"

for w in "${warns[@]:-}"; do [ -n "$w" ] && echo "warn: $w"; done

if [ "${#errors[@]}" -gt 0 ] && [ -n "${errors[0]:-}" ]; then
  echo "verify-instructions 실패:"
  for e in "${errors[@]}"; do echo " - $e"; done
  exit 1
fi

echo "verify-instructions 통과"
