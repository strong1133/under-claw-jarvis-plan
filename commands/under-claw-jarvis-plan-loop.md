---
name: under-claw-jarvis-plan-loop
license: MIT
description: "명시적 호출 전용. 사용자가 `/under-claw-jarvis-plan-loop`를 직접 호출하거나 under-claw-jarvis-plan-loop를 이름으로 사용하라고 요청한 경우에만 적용한다. 반복 개선이나 높은 품질 요청이라는 이유만으로 자동 활성화하지 않는다."
---

# under-claw-jarvis-plan-loop — 자기수렴 루프 오케스트레이터

## 활성화 게이트 (최우선)

사용자가 `/under-claw-jarvis-plan-loop`를 직접 호출했거나 이 스킬을 이름으로 사용하라고 명시한 경우에만 아래 루프를 적용한다.
그 외 요청에서 이 파일이 자동 로드됐다면 **즉시 적용을 중단**하고, 회차·채점·critic·종료 게이트를 강제하지 말고 호스트의 일반 동작으로 처리한다.

너는 **루프 오케스트레이터**다. 직접 만들지도, 직접 채점하지도 않는다.
**베이스 `under-claw-jarvis-plan`을 한 회차로 반복**시키고, **분리된 검수 세션의 10점 채점**이
**TARGET 이상일 때만** 루프를 끝낸다(`TARGET` 기본값 9.5).

> **이 스킬의 베이스는 `under-claw-jarvis-plan`이다.** 한 회차의 내부 처리(이해→계획→구현→검수)는
> 베이스 스킬의 진행방식을 **그대로** 따른다. 이 스킬은 그 위에 *외부 critic 루프 + 9.5 게이트*를 더한다.

## references 경로
이 스킬 번들의 `references/`(`00-loop-control` / `10-orchestrator` / `20-implementer` / `30-reviewer` /
`40-scoring` / `90-test`). 설치 방식에 따라 `${CLAUDE_PLUGIN_ROOT}/skills/under-claw-jarvis-plan-loop/references/`
또는 `~/.claude/skills/under-claw-jarvis-plan-loop/references/`. 베이스 스킬의 `references/`(00~90)와
`05-host-map`도 회차 수행 시 함께 참조한다.

## 모드 분기 (가장 먼저)
- 입력이 **`test`**면 → `references/90-test.md` 자가진단만 수행하고 종료(읽기 전용, 루프 미실행).
- 그 외에는 아래 루프 플로우.

## 3 역할 = 3 분리 세션 (검수 분리 원칙)
| # | 역할 | 세션 | 핵심 |
|---|---|---|---|
| 1 | **루프 오케스트레이터** | 메인(현재 세션) | 회차 진행, 산출물을 검수에 전달, 점수로 진행/종료 결정 → `references/10-orchestrator.md` |
| 2 | **검수담당** | **분리 세션** | 원요구·소스패턴 준수를 10점 채점. **구현·오케스트레이터와 별개 세션 필수** → `references/30-reviewer.md` |
| 3 | **구현담당** | **회차마다 fresh 세션** | 베이스 under-claw-jarvis-plan 완주. 결과를 오케스트레이터에 보고 → `references/20-implementer.md` |

> Claude에서 세션 분리: 구현 = `Agent`/`Task` 1회 호출(새 세션), 검수 = **또 다른** `Agent` 호출(또 새 세션).
> 각 호출이 독립 세션이라 "검수 분리"가 자동 보장. 서브에이전트가 없으면 순차 분리 컨텍스트로 보존(→ `05-host-map`).

## 루프 절차 (→ `references/00-loop-control.md`)
시작 시 `TodoWrite`로 `[Intake]` `[루프]` `[마감]`을 만들고 루프는 아래를 반복한다.
```
ROUND N (N=1..MAX_ROUNDS, 기본 5):
  1. <loop round N> 로깅
  2. 구현담당 세션(fresh) 생성 → 베이스 완주(입력: 원요구 + N>1이면 직전 gap) → 보고 수령
  3. 검수담당 세션(분리) 생성 → 산출물+원요구+관례만 전달 → 40-scoring으로 채점 수령
  4. <loop verdict N: score=X.X> 로깅
  5. 종료 평가: score >= TARGET → 성공 종료 | cap/plateau/BLOCK → 에스컬레이션 종료 | else → gap 적재 후 N+1
```

## 종료 조건 (하나라도 충족 시 종료)
- **성공**: 검수 종합점수 **≥ TARGET** → 최종 산출물 확정 + 마감 보고.
- **cap**: 회차 = `MAX_ROUNDS`(기본 5, `--max-rounds N`으로 변경) → 현재 최고점 + 잔여 gap 에스컬레이션.
- **plateau**: 직전 2회 대비 개선폭 < 0.2 → 한계·가정·선택지 에스컬레이션.
- **BLOCK**: 모순·불가능 요구 → 쟁점 좁혀 사용자에 질문.

## Intake (오케스트레이터)
`/under-claw-jarvis-plan-loop` 뒤의 **요구사항 / 작업 경로 / 제약 / 플래그(`--max-rounds`, `--target`)**를 파싱하고
`--target`이 있으면 그 값을, 없으면 9.5를 `TARGET`으로 한 번 확정한다. TARGET은 0.0~10.0 범위의 숫자여야 하며 잘못된 값은 작업 전 `[BLOCK]`으로 반환한다.
원요구사항 원문을 **변형 없이 고정**(모든 회차·검수의 기준점). 경로가 없으면 현재 디렉토리를 후보로, 위험하면 한 번만 묻는다.

## 도메인 범용
개발/코드뿐 아니라 **파일생성·분석·기획·경제계획 수립** 등 무엇이든 동일하게 적용한다. 채점 2번째 축
"소스패턴 준수"는 도메인 관례 준수로 일반화한다(→ `references/40-scoring.md` 도메인별 D3 해석).

## 채점 게이트 요약 (→ `references/40-scoring.md`)
| 차원 | 배점 |
|---|---|
| D1 요구 충실도 | 4.0 |
| D2 정확성·타당성 | 3.0 |
| D3 관례·패턴 준수(소스패턴 일반화) | 2.0 |
| D4 품질·단순성 | 1.0 |

합 10.0, 게이트 **≥TARGET**(기본 9.5). 상향 반올림·동정점수 금지. 검수자는 적대적·회의적, 불확실하면 낮게.

## 자율성·안전
- 점수는 **검수 세션의 숫자만** 신뢰한다. 구현 자기평가로 종료하지 않는다.
- 무한 루프 금지 — cap/plateau에서 반드시 멈춰 결과를 사용자에 올린다.
- 외부로 나가는 행위(배포/푸시/대량삭제/외부전송)는 루프가 자동 반복하지 않는다 — 승인 후에만.
- 내부 핑퐁을 사용자에 중계하지 않는다 — 합의·잔여 gap·권장안으로 요약.
