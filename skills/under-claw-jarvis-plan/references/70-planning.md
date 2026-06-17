# 70 · 단계별 스킬 커스텀 매핑 (Skill Planning)

> 자체 모듈. under-claw-jarvis-plan은 **환경 비종속**이라, 단계마다 호출할 **구체 스킬**은
> 환경마다 다르다. 이 모듈은 사용자가 자기 환경의 스킬을 **각 단계에 바인딩**하는
> 커스텀 지점을 정의한다.
> ⚠️ Phase 3 계획(`20-plan`)과 **다르다** — 여기선 "**어떤 스킬을 어느 단계에**" 만 정한다(스킬 배선).

## 무엇을 푸는가
`60-skill-orchestration`의 단계×스킬 맵은 **유형(예: "패턴 검증 스킬")** 으로만 적는다(환경 비종속).
실제 환경의 **구체 스킬명**(예: `valid-pattern`)은 사람마다 달라 코어 reference에 박지 않는다.
대신 사용자가 **자기 맵**을 선언하면 오케스트레이터가 단계마다 그 스킬을 호출한다.

## 커스텀 맵 위치 (코어와 분리 — 재설치에도 안 지워짐)
오케스트레이터는 **시작(Phase 0)에서 아래 순서로** 커스텀 맵을 찾는다:
1. **프로젝트**: `<작업프로젝트>/docs/under-claw-jarvis-plan/skill-map.md`
2. **Codex 유저 전역**: `~/.codex/under-claw-jarvis-plan.skillmap.md`
3. **Claude 호환 전역**: `~/.claude/under-claw-jarvis-plan.skillmap.md`

여러 맵이 있으면 **프로젝트가 우선**(전역은 기본값), 키별로 병합. 없으면 `60`의 유형 맵만으로 동작(graceful).

> ⚠️ 이 `70-planning.md`(코어)는 설치 시 덮어쓰여진다. **사용자 값은 위 외부 파일에** 둔다.
> (그래서 `install.sh` 재실행/업데이트가 사용자 매핑을 지우지 않는다.)

## 맵 형식 (복붙 템플릿)
```md
# under-claw-jarvis-plan skill-map (내 환경)
phase2_understand: [understand, valid-service, valid-pattern]
phase3_plan:       [deep-research]
phase4_implement:  [tailwind-rules, figma-publish, sync-postman]
phase5_review:     [valid-pattern, valid-service, check-tailwind, code-review, verify]
closing:           [docs, todo]
```
- 키는 **단계 고정**: `phase2_understand` / `phase3_plan` / `phase4_implement` / `phase5_review` / `closing`.
- 값은 **현재 세션에 실제 있는 스킬명** 배열(슬래시 없이 이름만). 한 단계 여러 스킬 가능.
- 자유 주석(`#`) 가능. 빈 키는 생략해도 됨.

## 로드·병합 규칙
1. **시작 시 맵 로드** → `<planning 적용>` 로깅(구성 스킬이므로 호출 로깅 필수).
2. 각 단계 진입 시: **커스텀 맵의 해당 키 스킬을 우선 호출**하고, `60`의 유형 맵은 **빈틈 보강용**으로만 쓴다.
3. 맵에 적힌 스킬이 런타임에 없으면 **⏭️ + 사유 1줄** 후 council/서브에이전트 또는 현재 세션의 역할별 독립 패스로 대체(Karpathy 4).
4. 커스텀 맵 자체가 없으면 이 모듈은 **무동작** — 순수 `60` 유형 맵 fallback.
5. 맵은 **제안일 뿐 강제는 아니다** — 단계 성격에 안 맞는 스킬은 council 판단으로 건너뛸 수 있다.

## test 연동
`/under-claw-jarvis-plan test`는 (a) 커스텀 맵 탐지 여부, (b) 맵에 적힌 스킬의 런타임 가용,
(c) 단계별 바인딩 결과를 점검해 매트릭스에 포함한다(→ `90-test`). 맵 없으면 ⏭️(fallback)로 보고.
