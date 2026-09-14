# Third-Party Notices

under-claw-jarvis-plan은 다음 오픈소스 스킬의 방법론을 **발췌·적응(adapt)** 하여 references로
구성한다. 각 원저작물은 MIT 라이선스이며, 아래 저작권·라이선스 고지를 보존한다.
(원문을 그대로 복사하지 않고 방법론을 요약·재서술했으나, 출처 귀속을 위해 명시한다.)

## 1. Karpathy Guidelines  →  references/00-karpathy.md
- 출처: https://github.com/multica-ai/andrej-karpathy-skills (skills/karpathy-guidelines)
- 원안: Andrej Karpathy의 LLM 코딩 관찰 기반
- 라이선스: MIT

## 2. Superpowers  →  references/20-plan.md, 30-implement.md, 40-review.md
- 출처: https://github.com/obra/superpowers
- 채택: brainstorming, writing-plans, subagent-driven-development, code-review, verification
- 라이선스: MIT

## 3. Understand-Anything  →  references/10-understand.md (구조 매핑 라우팅)
- 출처: https://github.com/Egonex-AI/Understand-Anything
- 라이선스: MIT

## 4. Anthropic Skills — skill-creator (저작 도구로만 사용)
- 출처: https://github.com/anthropics/skills (skills/skill-creator)
- 라이선스: 해당 레포 라이선스 참조

---
자체 작성: references/50-peer-collab.md, 60-skill-orchestration.md, 70-planning.md, 90-test.md,
commands/under-claw-jarvis-plan.md — 본 레포(MIT).

각 MIT 라이선스 전문은 해당 원본 레포의 LICENSE 파일을 참조한다.

## 외부 원본 버전 확인 (2026-09-14)

`install.sh --with-externals` / `--externals-only`가 사용하는 고정 커밋이다.
각 저장소 기본 브랜치의 HEAD를 조회해 확인했다. 설치 시에도 전체 SHA를 검증한다.

| 원본 | 고정 커밋 | 확인 결과 |
|---|---|---|
| [Karpathy Guidelines](https://github.com/multica-ai/andrej-karpathy-skills) | `2c606141936f1eeef17fa3043a72095b4765b9c2` | 기존 버전이 최신 |
| [Superpowers](https://github.com/obra/superpowers) | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` | v6.3.0으로 갱신 |
| [Anthropic Skills](https://github.com/anthropics/skills) | `34040c9c568585f6929bedeaad110ad08f079624` | 저장소 갱신; 설치 대상 `skill-creator` 내용은 이전 고정 버전과 동일 |
| [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) | `6df3065f1d8ddc2ce3615314d1d493f36d6b1c80` | 원본 캐시 갱신; 플러그인 설치는 기존처럼 수동 |

Superpowers 원본에는 작업 규모에 따른 설계 흐름, 계획별 작업 기록 격리,
기존 구현자를 재개하는 수정 리뷰, 작은 동종 작업의 묶음 실행 등이 반영되어 있다.
외부 설치는 원본 스킬 디렉터리 전체를 복사하므로 관련 보조 스크립트도 함께 갱신된다.
under-claw 내부 references는 자체 흐름에 맞춘 발췌·적응본으로, 원본의 모든 정책을
그대로 적용하는 사본은 아니다. 이번 갱신은 외부 설치 버전에 적용한다.

## 5. 선택 구성 모듈 (2026-09-14)

다음 프로젝트를 참고해 `shared/components/`의 연결 규칙을 독립적으로 작성했다.
원본 구현을 번들에 복사하지 않는다. 원본 캐시 옵션은 LICENSE를 포함한 저장소를
고정 revision 그대로 보존하며 자동으로 실행하지 않는다.

| 원본 | 라이선스 | 적용 |
|---|---|---|
| https://github.com/Q00/ouroboros | MIT | 명세·단계별 검증·재개 원리 |
| https://github.com/epoko77-ai/im-not-ai | MIT | 메타프롬프팅의 한국어 표현 개선·요구 보존 |

정확한 revision은 [shared/components.json](shared/components.json)이 소유한다.
공통 명세 스키마와 evidence.py는 이 저장소에서 자체 작성했다.
