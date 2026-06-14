#!/usr/bin/env bash
# under-claw-jarvis-plan structure / manifest / sensitive-data validator.
# Runs in CI and locally. No external deps beyond bash + python3 (JSON parsing).
#
#   bash tests/validate.sh
#
# Exit 0 = all checks pass, non-zero = at least one failure.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$ROOT"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

PY=python3; have python3 || PY=python
have "$PY" || { echo "python3 필요(JSON 검증)"; exit 2; }

echo "▶ 1. 필수 파일 존재"
for f in \
  LICENSE THIRD_PARTY_NOTICES.md README.md README.ko.md install.sh \
  CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md \
  commands/under-claw-jarvis-plan.md \
  skills/under-claw-jarvis-plan/README.md \
  .claude-plugin/plugin.json .claude-plugin/marketplace.json \
  .cursor-plugin/plugin.json .copilot-plugin/plugin.json \
  examples/skill-map.example.md ; do
  [[ -f "$f" ]] && ok "$f" || bad "$f 없음"
done

echo "▶ 2. reference 모듈 9개"
for n in 00-karpathy 10-understand 20-plan 30-implement 40-review 50-peer-collab 60-skill-orchestration 70-planning 90-test; do
  f="skills/under-claw-jarvis-plan/references/$n.md"
  [[ -f "$f" ]] && ok "$n" || bad "$f 없음"
done

echo "▶ 3. command frontmatter (name/description/license)"
fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' commands/under-claw-jarvis-plan.md)"
for k in name description license; do
  grep -q "^$k:" <<<"$fm" && ok "frontmatter.$k" || bad "frontmatter.$k 누락"
done

echo "▶ 4. JSON 매니페스트 유효성 (claude/cursor/copilot + marketplace)"
"$PY" - <<'PY' && ok "모든 매니페스트 유효" || bad "JSON 파싱/필드 오류"
import json, sys
for path in (".claude-plugin/plugin.json", ".cursor-plugin/plugin.json", ".copilot-plugin/plugin.json"):
    p = json.load(open(path))
    assert p.get("name") == "under-claw-jarvis-plan", f"{path} name"
    assert p.get("license") == "MIT", f"{path} license"
m = json.load(open(".claude-plugin/marketplace.json"))
assert isinstance(m.get("plugins"), list) and m["plugins"], "marketplace.plugins"
assert "under-claw-jarvis-plan" in [x.get("name") for x in m["plugins"]], "marketplace lists plugin"
sys.exit(0)
PY

echo "▶ 5. skill-map 예시 파싱 (단계 키)"
for key in phase2_understand phase3_plan phase4_implement phase5_review closing; do
  grep -q "^$key:" examples/skill-map.example.md && ok "key $key" || bad "key $key 없음"
done

echo "▶ 6. 양쪽 README 출처/귀속 표기 존재"
for doc in README.md README.ko.md; do
  for src in "andrej-karpathy-skills" "superpowers" "Understand-Anything" "THIRD_PARTY_NOTICES"; do
    grep -q "$src" "$doc" && ok "$doc 출처: $src" || bad "$doc 출처 누락: $src"
  done
done

echo "▶ 7. 민감정보/개인경로 누출 가드"
# 실제 값이 박히면 실패. (이 테스트 파일 자신은 패턴 정의이므로 제외)
LEAK=0
while IFS= read -r pat; do
  if grep -rIn --exclude-dir=.git --exclude="validate.sh" -e "$pat" . >/dev/null 2>&1; then
    bad "민감 패턴 발견: $pat"; LEAK=1
  fi
done <<'PATS'
/Users/jsj
seokjin
ff-genius
AI_ARCHIVE_REPORT
storageFileSeqList
PATS
[[ "$LEAK" == 0 ]] && ok "민감정보/개인경로 없음"

echo "▶ 8. 설계 보증 문서화 (회귀 / DoD / 합성·설계doc 스키마)"
CMD=commands/under-claw-jarvis-plan.md
grep -q "단계 회귀" "$CMD"            && ok "command: 단계 회귀(cross-stage feedback)" || bad "command: 단계 회귀 누락"
grep -q "회귀 N→M" "$CMD"             && ok "command: 회귀 로깅 태그 정의"            || bad "command: <회귀 N→M> 누락"
grep -q "Definition of Done" "$CMD"   && ok "command: 단계 완료 검증(DoD)"            || bad "command: DoD 누락"
grep -q "합성 산출 스키마" skills/under-claw-jarvis-plan/references/50-peer-collab.md \
  && ok "50: 합성 산출 스키마" || bad "50: 합성 산출 스키마 누락"
grep -q "고정 스키마" skills/under-claw-jarvis-plan/references/20-plan.md \
  && ok "20: 설계 doc 고정 스키마" || bad "20: 설계 doc 스키마 누락"

echo
echo "── 결과: PASS=$PASS  FAIL=$FAIL ──"
[[ "$FAIL" == 0 ]]
