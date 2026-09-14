---
name: under-claw-meta-prompt
description: 명시적으로 호출해 질의를 일관된 실행 프롬프트로 만들고 복사하거나 -d 경로에 저장한다.
license: MIT
---

# under-claw-meta-prompt — 명시적 호출 전용

이 명령이 직접 호출된 경우에만 아래 설치 위치의 `SKILL.md`를 읽고 그대로 수행한다.

- 플러그인 설치: `${CLAUDE_PLUGIN_ROOT}/skills/under-claw-meta-prompt/SKILL.md`
- `install.sh` 설치: `~/.claude/skills/under-claw-meta-prompt/SKILL.md`

호스트가 제공한 플러그인 경로를 우선하고, 없으면 사용자 설치 경로를 확인한다. 참조 문서와 스크립트의 상대 경로는 읽은 `SKILL.md`의 디렉터리를 기준으로 해석한다. 해당 파일을 찾지 못하면 설치 경로 오류를 알리고 중단한다.
일반 질의나 다른 명령에서는 자동 활성화하지 않는다.

입력 형식:

- `/under-claw-meta-prompt <질의>`: 결과 프롬프트를 응답하고 클립보드에 복사
- `/under-claw-meta-prompt -d <PATH> <질의>`: 대상의 기존 프롬프트를 수정하거나 `PROMPT.md`를 생성하고 상태·경로·요약만 응답

`/under-claw-meta-prompt --spec [-d PATH] <질의>`는 공통 명세 JSON을 생성한다. 상세 파싱·저장 규칙은 같은 SKILL.md를 따른다.

다른 under-claw 스킬을 호출하지 않는다.
