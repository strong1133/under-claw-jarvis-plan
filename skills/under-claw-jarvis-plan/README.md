# under-claw-jarvis-plan 스킬 — 번들 방법론 출처

`/under-claw-jarvis-plan` (진입점: `commands/under-claw-jarvis-plan.md`)이 참조하는 방법론 모음.
프로젝트 초월 멀티에이전트 오케스트레이션을 이해→계획→구현→검수로 수행한다.
현재 세션의 서브에이전트로 멀티에이전트 동작(기본). 제2모델 peer가 있으면 교차-모델 동등 협업.

> **진입점은 슬래시 커맨드** `commands/under-claw-jarvis-plan.md`(= `/under-claw-jarvis-plan`)이며,
> 이 폴더는 그 커맨드가 참조하는 **방법론 번들**이다. 별도 `SKILL.md`를 두지 않는다 —
> 커맨드와 동일 이름의 Agent Skill을 추가하면 스킬 목록이 **중복 등록**되므로, 커맨드 1개를 단일 진입점으로 유지한다.

## references/
| 파일 | 단계 | 출처(발췌·적응) |
|------|------|------|
| `00-karpathy.md` | 전 단계 가드레일 | multica-ai/andrej-karpathy-skills (MIT) |
| `10-understand.md` | Phase2 이해 | 자체 + Understand-Anything(Egonex-AI, MIT) 라우팅 + 로컬 요구 명확화 사상 |
| `20-plan.md` | Phase3 계획 | obra/superpowers brainstorming·writing-plans (MIT) |
| `30-implement.md` | Phase4 구현 | obra/superpowers subagent-driven-development (MIT) |
| `40-review.md` | Phase5 검수 | obra/superpowers code-review·verification (MIT) |
| `50-peer-collab.md` | 전 단계 | 자체 — 멀티에이전트 협업(독립 병행→교차 검토→합의), 기본=서브에이전트 |
| `60-skill-orchestration.md` | 전 단계 | 자체 — 단계별 기존 `/스킬` 능동 호출 **유형** 맵(재구현 금지, 호출 우선) |
| `70-planning.md` | 전 단계(스킬 배선) | 자체 — 단계별 **구체 스킬 커스텀 매핑**(skill-map, 60 유형 맵보다 우선) |
| `90-test.md` | 자가진단 | 자체 — `/under-claw-jarvis-plan test` 단계·스킬·model별 점검 매트릭스 |

## 설치
SSOT는 레포 `under-claw-jarvis-plan`. 레포 루트의 `install.sh` 한 방으로 `~/.claude/`에 설치된다.
이 스킬은 특정 프로젝트/환경에 종속되지 않는다 — 작업 경로는 실행 시 프롬프트로 받는다.

## 선택 의존(미설치 시 graceful degrade)
- Understand-Anything: 설치 시 `/understand`·`/understand-diff`로 코드 구조 매핑 강화.
  미설치면 council fan-out으로 대체.
- 메모리: 파일기반 경량(설계 doc = `docs/under-claw-jarvis-plan/specs/`). agentmemory 등 무거운 인프라 미사용.
