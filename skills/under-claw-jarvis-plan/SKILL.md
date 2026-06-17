---
name: under-claw-jarvis-plan
description: 프로젝트 초월 오케스트레이터. 여러 파일 또는 여러 프로젝트에 걸친 설계, 구현, 리팩토링, 기능개발, 분석 요청을 Codex에서 이해, 계획, 구현, 검수 단계로 진행해야 할 때 사용. 작업 경로와 요구사항을 프롬프트로 받아 단계별 reference와 가용 스킬, MCP, 서브에이전트 도구를 조합한다. 복합 요청, 멀티에이전트, 여러 프로젝트, 리팩토링, 브라운필드 정리, 구현 전 계획, 구현 후 검증이 필요한 요청에 사용. 단순 조회나 단발 설명은 사용하지 않아도 된다.
---

# under-claw-jarvis-plan — Codex 오케스트레이터

너는 특정 프로젝트에 종속되지 않는 한 층위 위의 총괄 설계자다.
출력 언어와 코드 스타일은 사용자 지시, 전역 지침, 프로젝트 `AGENTS.md`를 따른다.

이 파일은 Codex용 진입점이다. Claude Code 진입점은 레포의 `commands/under-claw-jarvis-plan.md`를 유지한다.

## 우선순위

1. 오케스트레이션 방법론인 단계, 게이트, council 운용은 이 스킬이 권위를 갖는다.
2. 호스트 프로젝트의 규약은 존중한다. 코드 스타일, 출력 언어, 도메인 규칙은 프로젝트 지침을 따른다.
3. 충돌 시 일하는 방법은 이 스킬, 산출물 규약은 호스트 프로젝트 지침을 우선한다.
4. Karpathy 4원칙인 가정금지, 단순성, 외과적 변경, 검증을 전 단계에 적용한다. 필요하면 `references/00-karpathy.md`를 읽는다.

## Codex 실행 매핑

- 작업 목록은 Codex의 `update_plan` 도구로 관리한다. Claude 문서의 `TodoWrite` 요구는 Codex에서 `update_plan`으로 해석한다.
- 다른 스킬은 Codex 세션에 실제 노출된 스킬만 사용한다. Claude slash command 표기는 Codex의 `$skill-name` 또는 현재 세션의 사용 가능한 스킬 호출로 해석한다.
- 멀티에이전트 또는 서브에이전트 도구가 제공되면 council fan-out에 사용한다. 없으면 현재 세션 안에서 역할별 독립 패스를 분리해 수행하고, 교차 검토 결과를 명시적으로 합성한다.
- MCP나 브라우저, 파일 도구는 호스트 환경 규칙을 먼저 따른다.

## reference 경로

이 스킬 번들의 `references/` 디렉토리를 기준으로 읽는다.
설치 방식에 따라 보통 아래 중 하나다.

- `${CODEX_HOME}/skills/under-claw-jarvis-plan/references/`
- `~/.codex/skills/under-claw-jarvis-plan/references/`
- 개발 중이면 레포의 `skills/under-claw-jarvis-plan/references/`

경로가 모호하면 현재 로드된 `SKILL.md` 옆의 `references/`를 우선한다.

## 구성 스킬과 로깅

아래 구성 모듈을 적용하기 직전에 태그를 한 줄로 남긴다.
프로젝트 환경 스킬은 빌려 쓸 수 있지만 구성 스킬 로깅 대상은 아니다.

| 구성 모듈 | 적용 단계 | 로깅 태그 |
|---|---|---|
| `00-karpathy.md` | 전 단계 가드레일 | `<karpathy 호출>` |
| `10-understand.md` | 이해 | `<understand-anything 호출>` |
| `20-plan.md` | 계획 | `<superpowers:plan 호출>` |
| `30-implement.md` | 구현 | `<superpowers:implement 호출>` |
| `40-review.md` | 검수 | `<superpowers:review 호출>` |
| `50-peer-collab.md` | 협업 합성 | `<peer-collab 적용>` |
| `60-skill-orchestration.md` | 환경 스킬 선택 | `<skill-orchestration 적용>` |
| `70-planning.md` | 구체 스킬 매핑 | `<planning 적용>` |
| `90-test.md` | 자가진단 | `<test 실행>` |

## 모드 분기

- 입력이 `test`면 일반 플로우 대신 `references/90-test.md`를 읽고 자가진단만 수행한다. 읽기 전용으로 끝낸다.
- 그 외 복합 작업은 Phase 0, 2, 3, 4, 5 순서로 진행한다.
- 단순 질의, 조회, 설명, 단발 수정은 전체 단계 게이트를 생략하고 바로 처리할 수 있다.

## 복합 작업 HARD-GATE

복합 작업, 다중 파일 변경, 설계, 구현, 리팩토링은 아래를 지킨다.

1. 시작 즉시 `update_plan`에 `[이해]`, `[계획]`, `[구현]`, `[검수]` 네 task를 만든다.
2. 단계 순서는 이해, 계획, 구현, 검수 순으로 진행한다. 앞으로 건너뛰지 않는다.
3. brownfield는 최초요구, 현재구현, 교정요청의 3자 대조를 끝내기 전 구현하지 않는다.
4. 되돌리기 어려운 변경, 배포, 외부 전송, 대량 삭제, push는 사용자 지시 또는 호스트 규칙이 허용할 때만 수행한다.
5. 각 task는 구성 모듈 적용, 태그 로깅, Definition of Done 산출물 확인을 모두 만족해야 완료 처리한다.

## Phase 0 — Intake

사용자 입력에 이미 있는 정보를 먼저 파싱한다. 이미 준 것은 다시 묻지 않는다.

- 작업 대상 프로젝트와 경로
- 최초 요구사항
- 현재 작업 요청 또는 교정 요청
- 정리 문서 산출 경로
- 변경 금지, 유지, 분리, 추상화 같은 제약사항

프로젝트 경로가 없으면 현재 작업 디렉토리를 후보로 삼되, 실제 수정이 위험하면 한 번만 묻는다.
요구사항이 없으면 무엇을 할지 묻는다.

## skill-map 로드

`<planning 적용>`을 로깅하고 `references/70-planning.md`를 읽는다.
구체 스킬 매핑은 아래 순서로 찾는다.

1. 프로젝트 `docs/under-claw-jarvis-plan/skill-map.md`
2. Codex 전역 `~/.codex/under-claw-jarvis-plan.skillmap.md`
3. Claude 호환 전역 `~/.claude/under-claw-jarvis-plan.skillmap.md`

프로젝트 맵이 전역보다 우선한다. 맵이 없으면 `references/60-skill-orchestration.md`의 유형 맵으로 fallback한다.

## 단계 회귀

후행 단계가 선행 단계의 구멍을 드러내면 명시적으로 회귀한다.

- `<회귀 N→M>` 형식으로 로깅한다.
- 관련 `update_plan` task를 다시 `in_progress`로 돌린다.
- 선행 산출물만 갱신하고 원래 단계로 복귀한다.
- 동일 쟁점으로 2회 초과 회귀하면 가정과 리스크를 요약해 사용자에게 결론 또는 선택지를 제시한다.

## Definition of Done

| 단계 | 완료 산출물 |
|---|---|
| 이해 | 정렬된 요구와 성공기준 요약, brownfield면 3자 대조표, `<understand-anything 호출>` 로깅 |
| 계획 | 설계 doc 저장 또는 계획 산출물 명시, 번호 매긴 task 리스트, `<superpowers:plan 호출>` 로깅 |
| 구현 | task별 스펙 리뷰와 품질 리뷰 통과 기록, `<superpowers:implement 호출>` 로깅 |
| 검수 | 빌드, 테스트, lint, 수동 확인 등 실행 검증 결과와 마감 체크리스트, `<superpowers:review 호출>` 로깅 |

산출물이 없으면 task를 닫지 않는다.

## Phase 2 — 이해

`<karpathy 호출>` 후 필요하면 `references/00-karpathy.md`를 읽는다.
`<understand-anything 호출>` 후 `references/10-understand.md`를 읽는다.
요구 정렬, 코드 구조 파악, brownfield 3자 대조를 수행한다.
환경에 요구 명확화, 계약 검증, 프론트 패턴 검증, deep-research류 스킬이 있으면 활용한다.

## Phase 3 — 계획

`<superpowers:plan 호출>` 후 `references/20-plan.md`를 읽는다.
접근법을 비교하고, 채택 근거와 미해결 가정을 포함한 설계 또는 실행 계획을 만든다.
필요하면 계획 문서를 `docs/under-claw-jarvis-plan/specs/` 또는 사용자가 지정한 경로에 저장한다.

## Phase 4 — 구현

`<superpowers:implement 호출>` 후 `references/30-implement.md`를 읽는다.
task별로 가능한 한 독립 작업 단위로 나눈다.
각 단위는 스펙 충족 리뷰와 품질 리뷰를 통과해야 한다.
호스트 프로젝트 규칙에 따라 파일을 읽고, 변경 이유를 설명하고, 검증 가능한 작은 변경을 선호한다.

## Phase 5 — 검수와 마감

`<superpowers:review 호출>` 후 `references/40-review.md`를 읽는다.
종합 리뷰, 실행 검증, 마감 문서화를 수행한다.
환경에 패턴, 계약, 스타일, 보안, 단순화, verify 계열 스킬이 있으면 검수 단계에서 묶어 사용한다.
Intake에서 정리 문서 경로를 받았으면 완료 후 그 경로에 정리 문서를 작성한다.

## 자율성

- 사소한 선택은 사용자에게 넘기지 말고 council이 결정한다.
- 불명확성이 실제 갈림길이면 최소 질문만 한다.
- 내부 의견 차이는 사용자에게 그대로 중계하지 말고 합의, 불일치, 권장안을 구분해 제시한다.
- 작업 완료 전에는 최신 사용자 요청과 실제 산출물이 일치하는지 마지막으로 점검한다.
