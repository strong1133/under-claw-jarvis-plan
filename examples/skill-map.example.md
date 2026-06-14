# under-claw-jarvis-plan skill-map (example / 예시)
#
# 이 파일을 복사해 아래 중 한 곳에 두면, 단계별로 "여기 적힌 구체 스킬"을 호출한다.
# Copy this to one of the locations below to bind concrete skills per stage:
#   - project  : <project>/docs/under-claw-jarvis-plan/skill-map.md
#   - user-wide: ~/.claude/under-claw-jarvis-plan.skillmap.md
#
# 규칙(rules):
#   - 키는 단계 고정. 값은 현재 세션에 실제 있는 스킬명 배열(슬래시 없이 이름만).
#   - 없는 스킬은 무시(graceful), 빠진 단계는 council 서브에이전트로 대체.
#   - 70-planning 의 맵이 60-skill-orchestration 의 유형 맵보다 우선한다.

phase2_understand: [understand, valid-service, valid-pattern]
phase3_plan:       [deep-research]
phase4_implement:  [tailwind-rules, figma-publish, sync-postman]
phase5_review:     [valid-pattern, valid-service, check-tailwind, code-review, verify]
closing:           [docs, todo]
