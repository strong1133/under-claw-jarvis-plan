---
name: under-claw-jarvis-plan-loop
description: 명시적 호출 전용. 사용자가 `$under-claw-jarvis-plan-loop`를 직접 호출하거나 under-claw-jarvis-plan-loop를 이름으로 사용하라고 요청한 경우에만 적용한다. 반복 개선이나 높은 품질 요청이라는 이유만으로 자동 선택하지 않는다.
---

# under-claw-jarvis-plan-loop — 증거 기반 반복 개선 (Codex)

## 활성화 게이트 (최우선)

사용자가 이 스킬을 이름이나 명령으로 직접 호출한 경우에만 실행한다.
다른 요청에는 자동 활성화하지 않는다. 입력이 `test`면 `references/90-test.md`를 읽고
그 지시에 따라 읽기 전용 자가진단만 수행한다. 실제 루프는 돌리지 않는다.

베이스 `under-claw-jarvis-plan`을 사용하되, 첫 회차는 이해→계획→구현→검수를 수행하고
이후 회차는 증거가 유효한 단계를 재사용한다. 검수 분리와 기존 호출 이름은 유지한다.
코드·문서·분석·기획·경제계획 모두 같은 명세와 증거 계약을 사용한다.

## Intake

원요구·경로·제약·기존 명세를 읽는다. `--target`이 있으면 그 값, 없으면 9.5를 `TARGET`으로
한 번 확정한다(0.0~10.0 범위의 숫자). `--max-rounds`는 양의 정수, 기본 5다.
선택 `--max-seconds`는 양의 정수이며 루프 전체 경과시간 한도다. 유효하지 않은 값은
시작 전 BLOCK으로 반환한다. 사용자가 지정한 예산과 이미 부여한 권한을 보존한다.
번들의 `shared/working-principles.md`, `shared/contract.md`, `shared/verification.md`를 읽는다.
결과를 바꾸는 질문은 이 Intake에서 한 번에 모아 묻고, 루프가 시작된 뒤에는 회차 중간에 묻지 않는다.
Claude 명령 설치에서도 `shared/`는 설치된 loop 스킬 폴더 안에 있다.

## 실행 순서

1. `references/00-loop-control.md`로 종료·재수행·기록 규칙을 읽는다.
2. `references/10-orchestrator.md`에 따라 구현·검수 역할을 분리한다.
3. 구현자는 `references/20-implementer.md`에 따라 첫 회차 또는 지정 단계부터 수행한다.
4. 검수자는 `references/30-reviewer.md`와 `references/40-scoring.md`로 실행 증거와 품질을 평가한다.
5. `hard_pass AND score >= TARGET`이면 성공한다. cap/시간/plateau/BLOCK이면 미달로 종료한다.
   나머지는 원인별 `resume_stage`로 다음 회차를 시작한다.

`shared/evidence.py judge contract.json report.json --root RUN_DIR --target TARGET`로
기록의 일관성과 게이트를 검사한다. 실제 검사 실행과 의미 검수는 별도 책임이다.
`shared/components/ouroboros.md`를 읽고 `<component:ouroboros 적용>`을 기록한다.
원본 Ouroboros 런타임을 내부에서 중첩 실행하지 않는다.

## 호스트와 검수 분리

작업추적·스킬호출·서브에이전트 도구는 베이스 `references/05-host-map.md`를 따른다.
독립 컨텍스트가 있으면 작업자와 검수자를 분리하고 구현자의 자기변론·점수는 검수에 넘기지 않는다.
없으면 베이스의 역할 패스 기록 + 결정적 실행 검증 + `[BLOCK]` 없음 규칙을 적용하고
`DEGRADED_REVIEW`로 보고한다. 독립 검수가 필수라는 사용자 조건은 임의 완화하지 않는다.
외부 전송·배포 등은 기존 사용자 권한 범위에서만 수행하며 루프가 자동 재시도하지 않는다.
