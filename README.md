# under-claw-jarvis-plan — 프로젝트 초월 멀티에이전트 오케스트레이터 (스킬 번들 SSOT)

특정 프로젝트에 종속되지 않고 **한 층위 위**에서, **Claude + Codex 동등 멀티에이전트**로
요구사항을 **이해 → 분석 → 설계 → 계획 → 구현 → 검수**까지 주도하는 고차 스킬.
지시는 주로 `/under-claw-jarvis-plan` 스킬로 전달하며, 각 단계에서 환경에 깔린 기존 `/스킬`을 능동 호출한다.

> **SSOT**: 이 레포(`under-claw-jarvis-plan`)가 under-claw-jarvis-plan 스킬의 단일 기준이다.
> 편집·푸시·설치는 모두 이 레포에서 한다(원하는 위치에 클론).

---

## 3축 설계
| 축 | 내용 | 파일 |
|----|------|------|
| **멀티에이전트 council** | 복합 작업을 fan-out·검증·합성 | (전 단계) |
| **Claude↔Codex 동등 협업** | 2-pane에서 독립 병행 → 교차 검토 → 합의 합성. 기능 위계 없음 | `50-peer-collab` |
| **스킬 오케스트레이션** | 단계마다 기존 `/스킬` 능동 호출(재구현 금지) | `60-skill-orchestration` |

> 이 레포는 **스킬만** 담는다(`commands` + `references`). 2-pane 런처·alias·persona 같은
> 실행 환경은 포함하지 않으며, 각자 환경에서 준비한다. 스킬은 **단독 Claude 세션**에서
> `/under-claw-jarvis-plan` 로 동작하고, Claude+Codex **2-pane 환경에선 동등 협업**으로 확장된다.

## 단계 × 사용 스킬
```
/under-claw-jarvis-plan  (단독 Claude 또는 Claude+Codex 2-pane)
   0 Intake → 2 이해·분석 → 3 설계·계획 → 4 구현 → 5 검수·마감
   (단순 질의는 council 없이 즉답)
```
| 단계 | 하는 일 | 방법론(reference) | 호출 `/스킬` |
|------|---------|-------------------|--------------|
| **0 Intake** | 프로젝트·요구·정리문서·제약 파싱, 신규/수정 모드 판정, 빠진 것만 질문 | commands 본체 | — |
| **2 이해·분석** | 요구 정렬 + 코드구조 + (수정모드) 3자대조(최초요구↔현재구현↔교정) | `10-understand` | `understand`·`valid-service`·`valid-pattern`·`deep-research`·(Understand-Anything) |
| **3 설계·계획** | 접근법 비교 → 설계 합의 → 설계doc → 검증가능 task 분할 | `20-plan` | `deep-research` |
| **4 구현** | task별 작업 + 2단계 리뷰(스펙→품질), 영역 분담 | `30-implement` | `tailwind-rules`·`figma-publish`·`sync-postman` |
| **5 검수·마감** | 종합 리뷰 + 실행 검증 + 정리문서/문서화 | `40-review` | `valid-pattern`·`valid-service`·`check-tailwind`·`code-review`·`security-review`·`simplify`·`verify` / 마감 `docs`·`todo` |
| **전 단계** | 행동 가드레일(가정금지·단순·외과적·검증가능) | `00-karpathy` | — |

## references 구성 (출처)
| 파일 | 단계 | 출처 |
|------|------|------|
| `00-karpathy` | 전 단계 가드레일 | multica-ai/andrej-karpathy-skills (MIT) |
| `10-understand` | 이해·분석 | 자체 + Egonex-AI/Understand-Anything 라우팅 + 로컬 `/understand` |
| `20-plan` | 설계·계획 | obra/superpowers brainstorming·writing-plans (MIT) |
| `30-implement` | 구현 | obra/superpowers subagent-driven-development (MIT) |
| `40-review` | 검수·마감 | obra/superpowers code-review·verification (MIT) |
| `50-peer-collab` | 2-pane 전 단계 | 자체 — Claude↔Codex 동등 협업 |
| `60-skill-orchestration` | 전 단계 | 자체 — 단계별 `/스킬` 호출 맵 |
| (저작도구) | — | Anthropic skill-creator |

---

## 폴더 구조 (~/.claude 미러)
```
skills/under-claw-jarvis-plan/
├── install.sh                 # 한 방 설치
├── README.md                  # (이 문서)
├── VERIFY-peer-collab.md      # 2-pane 동등 협업 검증 시나리오
├── commands/
│   └── under-claw-jarvis-plan.md         # → ~/.claude/commands/under-claw-jarvis-plan.md  (/under-claw-jarvis-plan 진입점)
└── skills/
    └── under-claw-jarvis-plan/           # → ~/.claude/skills/under-claw-jarvis-plan/
        ├── README.md
        └── references/        # 00-karpathy ~ 60-skill-orchestration + 90-test (8개)
```

## 자가진단
```bash
/under-claw-jarvis-plan test    # 단계별·스킬별·model별 점검 매트릭스 출력 (읽기전용, 무변경)
```
환경(solo/2-pane)·reference 로드·스킬 가용/호출/로깅·multi-agent 왕복을 점검하고
단계 N/N · 스킬 N/N · model N/N → PASS/PARTIAL/FAIL 로 보고. 프로토콜: `references/90-test.md`.

## 설치 (새 PC에서 한 방)
```bash
git clone https://github.com/strong1133/under-claw-jarvis-plan && cd under-claw-jarvis-plan && ./install.sh
```
| 옵션 | 동작 |
|------|------|
| (없음) | 스킬 설치(commands + references) → `~/.claude`. **네트워크 불필요** |
| `--with-externals` | + 원본 스킬(Karpathy/Superpowers/Skill-Creator/Understand-Anything) 설치 |
| `--externals-only` | 원본 스킬만 |
| `--help` | 사용법 |

- 기존 파일은 `~/.under-claw-jarvis-plan-backup-<시각>/`에 자동 백업 후 교체(멱등·안전).

## 사용
설치 후, 아무 Claude Code 세션에서:
```
/under-claw-jarvis-plan        # 작업 프로젝트 경로 + 요구사항을 프롬프트로 전달
/under-claw-jarvis-plan test   # 단계·스킬·model별 자가진단
```
- **단독 Claude**: council = Agent/Workflow 서브에이전트.
- **Claude+Codex 2-pane**: 동등 협업(독립 병행→교차 검토→합의). 2-pane 환경(런처·pane 통신)은
  사용자가 자신의 환경에서 준비한다 — 이 레포는 그 하니스를 포함하지 않는다.

## 검증
`VERIFY-peer-collab.md`에 2-pane 동등 협업 검증 시나리오(6대 신호/채점표) 수록.
시나리오 B(분석·설계) + C(구현·교차리뷰) **6/6 PASS** — Codex가 Claude의 설계·코드를
비판·개선 유도함을 실측(2-pane 환경에서 재현).

## 메모리 / 선택 의존
- 메모리: **파일기반 경량**(설계doc = `docs/under-claw-jarvis-plan/specs/`). agentmemory 등 무거운 인프라 미사용.
- Understand-Anything: 설치 시 `/understand`·`/understand-diff`로 구조 매핑 강화, 미설치면 council fan-out.

## 라이선스
MIT (`LICENSE`). references는 Karpathy Guidelines / Superpowers / Understand-Anything(모두 MIT)을
발췌·적응했으며, 출처 귀속은 `THIRD_PARTY_NOTICES.md` 참조.
