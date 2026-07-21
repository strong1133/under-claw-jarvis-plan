# 05 · 호스트 실행 매핑 (Host Execution Map) — 에이전트 중립 어댑터

이 스킬의 **방법론**(00·10~70·90)은 어떤 에이전트에서도 동일하다(도구 중립).
호스트마다 다른 건 **딱 세 가지 능력의 "이름"뿐**이다. 이 파일은 그 세 가지를
추상 능력 → 각 호스트의 실제 도구로 매핑한다. **새 에이전트는 이 표만 읽으면 즉시 범용 구동**된다.

> 진입점(Claude `commands/`, Codex/Gemini `SKILL.md`/`GEMINI.md`)은 이 매핑을 가리킨다.
> 호스트 고유 도구명이 본문에 나오면(예: `TodoWrite`, `update_plan`) **이 표로 치환**해 해석한다.

## 호스트 의존 능력은 3개뿐
| # | 추상 능력 | 무엇에 쓰나 | 본문에서의 표기(예) |
|---|-----------|-------------|---------------------|
| **C1** | **작업 추적**(task tracking) | 이해/계획/구현/검수 4-task와 진행상태 관리 | `TodoWrite`, `update_plan` |
| **C2** | **스킬·명령 호출**(skill/command invocation) | 구성 스킬·환경 스킬·검증 스킬 불러오기 | `/skill-name`, `$skill-name` |
| **C3** | **멀티에이전트 fan-out**(subagent/peer) | council 독립 병행 → 교차 검토 → 합의(→`50`) | `Agent`/`Workflow`, subagent 도구 |

이 셋만 호스트별로 치환하면 나머지 방법론·게이트·DoD·회귀·합의 규칙은 **글자 그대로** 적용된다.

## 호스트별 매핑
| 호스트 | C1 작업 추적 | C2 스킬·명령 호출 | C3 멀티에이전트 | 진입점 파일 | references 경로(설치 시) |
|--------|--------------|-------------------|-----------------|-------------|--------------------------|
| **Claude Code** | `TodoWrite` | `/skill-name` (slash) | `Agent` / `Workflow` 서브에이전트 | `commands/under-claw-jarvis-plan.md` | `~/.claude/skills/under-claw-jarvis-plan/references/` |
| **Codex** | `update_plan` | `$skill-name` | multi-agent/subagent 도구 | `skills/.../SKILL.md` | `~/.codex/skills/under-claw-jarvis-plan/references/` |
| **Gemini CLI** | `GEMINI.md` 항목 또는 명시 체크리스트(C1-fallback) | TOML 커스텀 명령 또는 직접 도구 호출 | 병렬 도구 호출/세션 내 역할 분리(C3-fallback) | `skills/.../GEMINI.md` | `~/.gemini/skills/under-claw-jarvis-plan/references/` |
| **Cursor** | 내장 todo/플랜 패널 또는 C1-fallback | 등록된 command/skill | 세션 내 역할 분리(C3-fallback) | `commands/`+`skills/`(plugin) | `<plugin-root>/skills/.../references/` |
| **Copilot** | 내장 todo/플랜 또는 C1-fallback | 등록된 command/skill | 세션 내 역할 분리(C3-fallback) | `commands/`+`skills/`(plugin) | `<plugin-root>/skills/.../references/` |
| **generic LLM**(그 외 전부) | **C1-fallback** | **C2-fallback** | **C3-fallback** | 이 `SKILL.md`/`GEMINI.md` 중 가용한 것 | 로드된 `SKILL.md` 옆 `references/` |

## Fallback 규약 — 네이티브 도구가 없을 때(범용 보장의 핵심)
호스트가 위 능력의 **네이티브 도구를 제공하지 않아도** 스킬은 동일하게 동작한다.

- **C1-fallback(작업 추적 없음)**: 응답 본문에 `[이해]→[계획]→[구현]→[검수]` **명시 체크리스트**를 만들고,
  각 단계 전환 시 상태(`in_progress`/`done`)를 **직접 갱신해 출력**한다. "도구가 없으니 생략"은 금지 — DoD 표는 그대로 강제된다.
- **C2-fallback(스킬 호출 없음)**: 외부 스킬을 못 부르면 **해당 `references/` 모듈을 직접 읽어** 그 방법론을 수행한다.
  이 스킬은 외부 스킬 없이도 자체 reference로 완결되도록 설계됐다(원본 강화는 선택).
- **C3-fallback(서브에이전트 없음)**: 서브에이전트 도구가 없으면 **현재 세션 안에서 관점 A/B/C를 분리**해
  순차적 독립 패스로 수행하고, 오케스트레이터가 적대적으로 교차 검토 후 `50`의 합성 스키마로 합의한다.
  제2/제3 모델 peer가 환경에 있으면 교차-모델로 확장(없으면 신경 쓰지 않는다).

## 로깅·게이트는 호스트 불변 (치환 대상 아님)
호스트별로 바뀌는 건 C1~C3의 **도구 이름뿐**이다. 아래는 **모든 호스트에서 동일**하게 강제된다.
- 구성 스킬 호출 로깅 `<{태그} 호출>`(→`50`), 복합작업 HARD-GATE, 단계 회귀 `<회귀 N→M>`,
  단계 완료 검증(DoD) 산출물, 전원 동의·작업자/검수자 분리 원칙.
- 즉, **"무엇을 보장하는가"는 불변, "어떤 도구로 보장하는가"만 이 표로 치환**한다.

## 자가 점검(어댑터 무결성)
`test` 자가진단(→`90`)은 현재 호스트를 감지하고, 위 표에서 C1~C3가 **네이티브냐 fallback이냐**를
③ 에이전트별 매트릭스에 한 줄로 표기한다(예: "Gemini · C1=fallback체크리스트 · C3=세션내역할분리 · PASS").
