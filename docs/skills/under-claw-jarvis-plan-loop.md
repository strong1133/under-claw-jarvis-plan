# under-claw-jarvis-plan-loop — 프롬프트 구성

> 이 문서는 스킬이 에이전트에게 **무엇을 지시하는지**를 파일 단위로 설명한다. 규칙의 정본은 각 파일이다.

베이스 `under-claw-jarvis-plan`을 회차 단위로 반복해, 필수 기준의 실행 증거(hard_pass)와 품질 점수 목표(TARGET)를 함께 만족할 때까지 개선한다.
구현자와 검수자를 분리하고, 회차마다 결함의 원인에 따라 이해·계획·구현·검수 중 필요한 단계부터 재수행한다.

## 파일 구성

| 파일 | 역할 |
|---|---|
| `commands/under-claw-jarvis-plan-loop.md` | Claude Code 진입점 |
| `skills/under-claw-jarvis-plan-loop/SKILL.md` | Codex 진입점 |
| `skills/under-claw-jarvis-plan-loop/GEMINI.md` | Gemini 진입점 |
| `skills/under-claw-jarvis-plan-loop/references/*.md` | 루프 제어·역할별 모듈 |
| `skills/under-claw-jarvis-plan-loop/shared/*.md`, `evidence.py` | 공통 작업 원칙·명세·검증·판정 스크립트 (정본은 저장소 `shared/`) |

세 진입점은 본문이 같다. 작업 추적·스킬 호출·서브에이전트 도구는 베이스의 `references/05-host-map.md`를 따른다.

## 진입점이 지시하는 것

| 절 | 내용 |
|---|---|
| 활성화 게이트 | 직접 호출됐을 때만 실행한다. 입력이 `test`면 `references/90-test.md`에 따라 읽기 전용 자가진단만 한다. |
| 베이스 관계 | 첫 회차는 베이스의 이해→계획→구현→검수 전체를 수행하고, 이후 회차는 증거가 유효한 단계를 재사용한다. 코드·문서·분석·기획 모두 같은 명세와 증거 계약을 쓴다. |
| Intake | 원요구·경로·제약·기존 명세를 읽는다. `--target`(기본 9.5, 0.0~10.0), `--max-rounds`(기본 5), 선택 `--max-seconds`를 확정하고 잘못된 값은 시작 전 BLOCK으로 돌려준다. `shared/working-principles.md`, `contract.md`, `verification.md`를 읽는다. 결과를 바꾸는 질문은 이 Intake에서 한 번에 묻고 회차 중간에는 묻지 않는다. |
| 실행 순서 | `00` 종료·재수행 규칙 → `10` 역할 분리 → `20` 구현자 수행 → `30`·`40` 검수자 평가 → `hard_pass AND score >= TARGET`이면 성공, cap·시간·plateau·BLOCK이면 미달 종료, 그 밖에는 원인별 `resume_stage`로 다음 회차. `evidence.py judge`로 기록의 일관성과 게이트를 검사한다. |
| 검수 분리 | 독립 컨텍스트가 있으면 작업자와 검수자를 분리하고 구현자의 자기변론·점수는 검수에 넘기지 않는다. 없으면 `DEGRADED_REVIEW`로 보고한다. 외부 전송·배포는 기존 권한 범위에서만 하고 루프가 자동 재시도하지 않는다. |

## 모듈 (`references/`)

| 모듈 | 역할 | 지시 내용 |
|---|---|---|
| `00-loop-control.md` | 종료·재수행·기록 | 종료 조건 표: BLOCK, 시간 한도, 성공(`hard_pass AND score >= TARGET`), 회차 cap, plateau(3회 이상에서 최근 2회 연속 필수 미해결 수가 줄지 않고 점수 개선 0.2 미만). 회차 절차와 원인별 `resume_stage` 표(요구 해석 → understand, 설계 결함 → plan, 버그·문장 결함 → implement, 검증 누락 → review). 미결정 질문은 가정을 기록한 명세 새 버전으로 정렬하고 회차 중간에 묻지 않는다. 가정으로 대체할 수 없는 blocking question이 남으면 의존하지 않는 기준까지 끝낸 뒤 BLOCK으로 종료한다. 기준을 삭제하거나 평가를 완화해 점수를 올리지 않는다. 회차 기록(명세 해시·산출물 해시·기준별 상태·점수·review_mode·resume_stage)을 보존하고 재개한다. |
| `10-orchestrator.md` | 루프 진행 | 한도를 검증하고 명세를 고정한다. 직접 구현하거나 채점하지 않는다. 검수자에게 자기점수·자기변론을 넘기지 않는다. 위임 중에는 이전 회차 증거 확인·기록 정리·예산 점검 등 위임 결과에 의존하지 않는 일을 한다. 시작 전 한 줄, 회차마다 판정과 다음 단계, 종료 시 6항목 보고. 구현·검수 요청에 공통 원칙 적용을 명시한다. 로그: `<loop round N>` → `<loop verdict N: …>` → `<loop end: PASS|ESCALATE>`. |
| `20-implementer.md` | 구현자 | 베이스 plan을 수행한다. 이전 산출물의 해시·유효성을 확인하고 필요한 앞 단계까지 회귀한다. 미해결 criterion별로 가장 작은 수정을 한다. 점수를 올리려고 범위를 넓히지 않고, criterion과 관련 없는 결함은 범위 밖 발견으로 보고한다. 확인용 임시 코드는 남기지 않고 테스트 파일은 사용자 요청·프로젝트 관례가 있을 때만 추가한다. 일부가 막혀도 나머지를 끝낸다. 보고: 산출물 경로·해시, claim→evidence, 실행 로그, 재사용 단계, 미해결·가정, 범위 밖 발견. |
| `30-reviewer.md` | 검수자 | 분리된 세션에서 원요구·명세·산출물·실행 로그를 읽는다. criterion별 실제 증거를 대조하고 fail/unknown을 구분한다. 필요 사유 보고가 없는 요청 밖 수정, 남겨진 임시 코드, 근거 없는 테스트 파일은 범위 이탈로 본다. 실패 원인을 단계로 분류해 보고 JSON을 낸다. |
| `40-scoring.md` | 채점 | D1 요구 충실도 4.0, D2 정확성·타당성 3.0, D3 관례·패턴 2.0, D4 품질·단순성 1.0의 고정 루브릭과 보정 앵커. 도메인별 D3 해석. 반올림 전 값으로 비교하고 hard_pass가 먼저 참이어야 한다. 원요구 원문에 점수를 고정하고 회차마다 독립 재채점한다. |
| `90-test.md` | 자가진단 | 모듈·번들 존재, 공통 작업 원칙의 하위 선언, 한도·종료 의미, 점수 게이트, 재검증 조건, 독립 검수 가능 여부, 외부 어댑터 제한을 항목별 PASS/PARTIAL/FAIL로 점검한다. |

## 공통 문서 (`shared/`)

| 파일 | 지시 내용 |
|---|---|
| `working-principles.md` | plan과 같은 공통 작업 원칙. loop에서는 특히 회차 중간에 묻지 않기, 점수를 위한 범위 확대 금지, 임시 코드 미보존, 오케스트레이터의 위임 중 병행, 회차별·종료 보고에 적용된다. |
| `contract.md` | 명세 스키마와 CAS·해시 규칙. 미결정 질문의 가정 처리와 `blocking_questions` 잔존 시 PASS 보류. 작업 시스템이 연결돼 있으면 그 원장이 정본이고 로컬 evidence는 첨부다. |
| `verification.md` | 검수 보고 JSON, `evidence.py judge` 사용법과 종료 코드, 결함별 복귀 단계. |
| `components/ouroboros.md` | 명세 고정·회차 기록·재개 원리. 원본 `ooo` 엔진을 내부에서 돌리지 않는다. |

## 입력과 출력

```text
/under-claw-jarvis-plan-loop <요구사항> --max-rounds 5 --target 9.5 [--max-seconds N]
$under-claw-jarvis-plan-loop <요구사항>
/under-claw-jarvis-plan-loop test
```

출력은 회차별 `<loop round N>`·`<loop verdict N>` 로그, 회차 기록(명세·산출물·증거 해시와 기준별 상태), 검수 보고 JSON, 종료 보고(확인한 내용·완료한 작업·최종 검증 상태·못 한 부분과 이유·범위 밖 발견·채택한 가정)다. `--target`을 낮춰 실행했으면 9.5가 기본 권장임을 마감 보고에 한 줄 적는다.
