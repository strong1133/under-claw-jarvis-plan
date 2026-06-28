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
  LICENSE THIRD_PARTY_NOTICES.md README.md README.en.md install.sh \
  CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md \
  commands/under-claw-jarvis-plan.md \
  skills/under-claw-jarvis-plan/SKILL.md \
  skills/under-claw-jarvis-plan/GEMINI.md \
  skills/under-claw-jarvis-plan/references/05-host-map.md \
  skills/under-claw-jarvis-plan/agents/openai.yaml \
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

echo "▶ 2b. loop 스킬 진입점 + reference"
for f in \
  commands/under-claw-jarvis-plan-loop.md \
  skills/under-claw-jarvis-plan-loop/SKILL.md \
  skills/under-claw-jarvis-plan-loop/GEMINI.md \
  skills/under-claw-jarvis-plan-loop/agents/openai.yaml ; do
  [[ -f "$f" ]] && ok "$f" || bad "$f 없음"
done
for n in 00-loop-control 10-orchestrator 20-implementer 30-reviewer 40-scoring 90-test; do
  f="skills/under-claw-jarvis-plan-loop/references/$n.md"
  [[ -f "$f" ]] && ok "loop:$n" || bad "$f 없음"
done
loop_cmd="commands/under-claw-jarvis-plan-loop.md"
grep -q "9.5" "$loop_cmd" && ok "loop: 9.5 게이트 명시" || bad "loop: 9.5 게이트 누락"
grep -q "검수 분리" "$loop_cmd" && ok "loop: 검수 분리 원칙" || bad "loop: 검수 분리 원칙 누락"
grep -q "under-claw-jarvis-plan" skills/under-claw-jarvis-plan-loop/references/20-implementer.md \
  && ok "loop: 베이스 스킬 연동" || bad "loop: 베이스 연동 누락"
loop_fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' "$loop_cmd")"
for k in name license description; do
  grep -q "^$k:" <<<"$loop_fm" && ok "loop.frontmatter.$k" || bad "loop.frontmatter.$k 누락"
done

echo "▶ 3. command / Codex skill frontmatter"
fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' commands/under-claw-jarvis-plan.md)"
for k in name description license; do
  grep -q "^$k:" <<<"$fm" && ok "frontmatter.$k" || bad "frontmatter.$k 누락"
done
skill_fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' skills/under-claw-jarvis-plan/SKILL.md)"
for k in name description; do
  grep -q "^$k:" <<<"$skill_fm" && ok "codex.frontmatter.$k" || bad "codex.frontmatter.$k 누락"
done
grep -q 'display_name:' skills/under-claw-jarvis-plan/agents/openai.yaml \
  && ok "codex.openai.display_name" || bad "codex.openai.display_name 누락"
grep -q 'default_prompt: "Use \$under-claw-jarvis-plan' skills/under-claw-jarvis-plan/agents/openai.yaml \
  && ok "codex.openai.default_prompt" || bad "codex.openai.default_prompt 누락"
gemini_fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' skills/under-claw-jarvis-plan/GEMINI.md)"
for k in name description; do
  grep -q "^$k:" <<<"$gemini_fm" && ok "gemini.frontmatter.$k" || bad "gemini.frontmatter.$k 누락"
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
grep -q "~/.codex/under-claw-jarvis-plan.skillmap.md" examples/skill-map.example.md \
  && ok "skill-map Codex 전역 경로" || bad "skill-map Codex 전역 경로 누락"

echo "▶ 6. README·스킬문서 외부 참조 스킬 출처/링크 표기 존재"
for doc in README.md README.en.md skills/under-claw-jarvis-plan/README.md; do
  for src in "andrej-karpathy-skills" "superpowers" "Understand-Anything"; do
    grep -q "$src" "$doc" && ok "$doc 출처: $src" || bad "$doc 출처 누락: $src"
  done
done
for doc in README.md README.en.md; do
  grep -q "THIRD_PARTY_NOTICES" "$doc" && ok "$doc: THIRD_PARTY_NOTICES" || bad "$doc: THIRD_PARTY_NOTICES 누락"
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
SKILL=skills/under-claw-jarvis-plan/SKILL.md
grep -q "단계 회귀" "$CMD"            && ok "command: 단계 회귀(cross-stage feedback)" || bad "command: 단계 회귀 누락"
grep -q "회귀 N→M" "$CMD"             && ok "command: 회귀 로깅 태그 정의"            || bad "command: <회귀 N→M> 누락"
grep -q "Definition of Done" "$CMD"   && ok "command: 단계 완료 검증(DoD)"            || bad "command: DoD 누락"
grep -q "단계 회귀" "$SKILL"          && ok "codex skill: 단계 회귀(cross-stage feedback)" || bad "codex skill: 단계 회귀 누락"
grep -q "회귀 N→M" "$SKILL"           && ok "codex skill: 회귀 로깅 태그 정의"            || bad "codex skill: <회귀 N→M> 누락"
grep -q "Definition of Done" "$SKILL" && ok "codex skill: 단계 완료 검증(DoD)"            || bad "codex skill: DoD 누락"
grep -q "합성 산출 스키마" skills/under-claw-jarvis-plan/references/50-peer-collab.md \
  && ok "50: 합성 산출 스키마" || bad "50: 합성 산출 스키마 누락"
grep -q "고정 스키마" skills/under-claw-jarvis-plan/references/20-plan.md \
  && ok "20: 설계 doc 고정 스키마" || bad "20: 설계 doc 스키마 누락"

echo "▶ 9. Codex 설치 문서화"
grep -q -- "--codex-only" install.sh && ok "install.sh: --codex-only" || bad "install.sh: --codex-only 누락"
grep -q -- "--codex-only" README.md  && ok "README.md: Codex 설치" || bad "README.md: Codex 설치 누락"
grep -q -- "--codex-only" README.en.md && ok "README.en.md: Codex install" || bad "README.en.md: Codex install 누락"

echo "▶ 10. Gemini / 범용 호스트 설치 문서화"
grep -q -- "--gemini-only" install.sh  && ok "install.sh: --gemini-only" || bad "install.sh: --gemini-only 누락"
grep -q -- "--gemini-only" README.md   && ok "README.md: Gemini 설치" || bad "README.md: Gemini 설치 누락"
grep -q -- "--gemini-only" README.en.md && ok "README.en.md: Gemini install" || bad "README.en.md: Gemini install 누락"
grep -q "05-host-map" skills/under-claw-jarvis-plan/SKILL.md && ok "SKILL.md: host-map 포인터" || bad "SKILL.md: host-map 포인터 누락"
grep -q "05-host-map" commands/under-claw-jarvis-plan.md && ok "command: host-map 포인터" || bad "command: host-map 포인터 누락"

echo "▶ 11. 도메인 범용(개발 외 — 기획/분석/경제계획) 명시"
for f in commands/under-claw-jarvis-plan.md skills/under-claw-jarvis-plan/SKILL.md skills/under-claw-jarvis-plan/GEMINI.md \
         commands/under-claw-jarvis-plan-loop.md skills/under-claw-jarvis-plan-loop/SKILL.md skills/under-claw-jarvis-plan-loop/GEMINI.md; do
  grep -q "경제계획" "$f" && grep -q "기획" "$f" && ok "domain-general: $f" || bad "$f: 비개발 도메인(기획/경제계획) 미명시"
done

echo
echo "── 결과: PASS=$PASS  FAIL=$FAIL ──"
[[ "$FAIL" == 0 ]]
