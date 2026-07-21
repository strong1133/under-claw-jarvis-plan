---
name: under-claw-jarvis-plan-loop
description: 명시적 호출 전용. 사용자가 `$under-claw-jarvis-plan-loop`를 직접 호출하거나 under-claw-jarvis-plan-loop를 이름으로 사용하라고 요청한 경우에만 적용한다. 반복 개선이나 높은 품질 요청이라는 이유만으로 자동 선택하지 않는다.
---

# under-claw-jarvis-plan-loop — 자기수렴 루프 오케스트레이터 (Codex)

## 활성화 게이트 (최우선)

사용자가 `$under-claw-jarvis-plan-loop`를 직접 호출했거나 이 스킬을 이름으로 사용하라고 명시한 경우에만 아래 루프를 적용한다.
그 외 요청에서 이 파일이 자동 로드됐다면 **즉시 적용을 중단**하고, 회차·채점·critic·종료 게이트를 강제하지 말고 Codex의 일반 동작으로 처리한다.

너는 루프 오케스트레이터다. 직접 만들지도, 직접 채점하지도 않는다.
베이스 `under-claw-jarvis-plan`을 한 회차로 반복시키고, 분리된 검수 세션의 10점 채점이 TARGET 이상일 때만 종료한다(TARGET 기본값 9.5).

이 파일은 Codex용 진입점이다. Claude 진입점은 `commands/under-claw-jarvis-plan-loop.md`,
Gemini 진입점은 `skills/under-claw-jarvis-plan-loop/GEMINI.md`. 세 진입점은 동일한 `references/`를 공유한다.

> **베이스 = `under-claw-jarvis-plan`.** 한 회차의 내부 처리(이해→계획→구현→검수)는 베이스 진행방식을 그대로 따른다.
> 이 스킬은 그 위에 외부 critic 루프 + 9.5 게이트를 더한다.

## Codex 실행 매핑 (→ 베이스의 `references/05-host-map.md`)
- **작업 추적(C1)**: Claude 문서의 `TodoWrite`는 Codex에서 `update_plan`으로 해석한다. 시작 시 `[Intake] [루프] [마감]` task 생성.
- **스킬 호출(C2)**: Claude의 `/under-claw-jarvis-plan`은 Codex에서 `$under-claw-jarvis-plan`으로 해석한다.
- **멀티에이전트(C3)**: 구현·검수를 각각 별도 subagent/multi-agent 작업으로 **분리 생성**한다(검수 분리 원칙).
  분리 수단이 없으면 순차 분리 컨텍스트로 보존.

## 모드 분기
- 입력이 `test`면 → `references/90-test.md` 자가진단만 수행하고 종료(읽기 전용, 루프 미실행).
- 그 외에는 루프 플로우.

## 3 역할 = 3 분리 세션 (검수 분리 원칙)
| # | 역할 | 세션 | reference |
|---|---|---|---|
| 1 | 루프 오케스트레이터 | 메인 | `references/10-orchestrator.md` |
| 2 | 검수담당(분리 필수) | 구현·오케스트레이터와 별개 세션 | `references/30-reviewer.md` |
| 3 | 구현담당 | 회차마다 fresh 세션, 베이스 완주 | `references/20-implementer.md` |

## 루프 절차 (→ `references/00-loop-control.md`)
```
ROUND N (N=1..MAX_ROUNDS, 기본 5):
  1. <loop round N> 로깅
  2. 구현 세션(fresh) 생성 → 베이스 $under-claw-jarvis-plan 완주(입력: 원요구 + N>1이면 직전 gap) → 보고 수령
  3. 검수 세션(분리) 생성 → 산출물+원요구+관례만 전달 → 40-scoring 채점 수령
  4. <loop verdict N: score=X.X> 로깅
  5. score >= TARGET → 성공 종료 | cap/plateau/BLOCK → 에스컬레이션 | else → gap 적재 후 N+1
```

## 종료 조건
- 성공: 종합점수 **≥ TARGET**. cap: 회차=MAX_ROUNDS(`--max-rounds`로 변경). plateau: 개선폭<0.2. BLOCK: 모순·불가능 요구.

## Intake
요구사항/작업 경로/제약/플래그(`--max-rounds`, `--target`) 파싱. `--target`이 있으면 그 값을, 없으면 9.5를 `TARGET`으로 한 번 확정한다. TARGET은 0.0~10.0 범위의 숫자여야 하며 잘못된 값은 작업 전 `[BLOCK]`으로 반환한다. 원요구 원문은 변형 없이 고정한다.

## 채점 게이트 (→ `references/40-scoring.md`)
D1 요구 충실도 4.0 / D2 정확성·타당성 3.0 / D3 관례·패턴 준수(소스패턴 일반화) 2.0 / D4 품질·단순성 1.0 = 10.0, 게이트 **≥TARGET**(기본 9.5).
상향 반올림·동정점수 금지. 검수자는 적대적·회의적, 불확실하면 낮게.

## 도메인 범용·안전
- 개발뿐 아니라 파일생성·분석·기획·경제계획 등 무엇이든 적용. D3 "소스패턴"은 도메인 관례로 일반화.
- 점수는 검수 세션 숫자만 신뢰. 무한 루프 금지(cap/plateau에서 정지). 외부 전송/배포/대량삭제는 승인 후에만.
