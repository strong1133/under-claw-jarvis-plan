---
name: under-claw-meta-prompt
description: 명시적으로 호출해 질의를 일관된 실행 프롬프트로 만들고 복사하거나 -d 경로에 저장한다.
license: MIT
---

# under-claw-meta-prompt — 명시적 호출 전용

이 명령이 직접 호출된 경우에만 `skills/under-claw-meta-prompt/SKILL.md`를 읽고 그대로 수행한다.
일반 질의나 다른 명령에서는 자동 활성화하지 않는다.

입력 형식:

- `/under-claw-meta-prompt <질의>`: 결과 프롬프트를 응답하고 클립보드에 복사
- `/under-claw-meta-prompt -d <PATH> <질의>`: 대상의 기존 프롬프트를 수정하거나 `PROMPT.md`를 생성하고 상태·경로·요약만 응답

다른 under-claw 스킬을 호출하지 않는다.
