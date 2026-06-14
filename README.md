<!-- 🌐 Language: **한국어** · [English](README.en.md) -->

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
| **2 이해·분석** | 요구 정렬 + 코드구조 + (수정모드) 3자대조(최초요구↔현재구현↔교정) | `10-understand` | 요구 명확화·계약 검증·패턴 검증 스킬·`deep-research`·(Understand-Anything) |
| **3 설계·계획** | 접근법 비교 → 설계 합의 → 설계doc → 검증가능 task 분할 | `20-plan` | `deep-research` |
| **4 구현** | task별 작업 + 2단계 리뷰(스펙→품질), 영역 분담 | `30-implement` | 스타일 규칙 조회·디자인 퍼블리싱·API 동기화 스킬 |
| **5 검수·마감** | 종합 리뷰 + 실행 검증 + 정리문서/문서화 | `40-review` | 패턴·계약·스타일 검증 스킬·`code-review`·`security-review`·`simplify`·`verify` / 마감 문서화·todo 스킬 |
| **전 단계** | 행동 가드레일(가정금지·단순·외과적·검증가능) | `00-karpathy` | — |

> 단계별 **구체 스킬**은 `70-planning`의 커스텀 `skill-map`으로 바인딩(→ [커스텀](#단계별-스킬-커스텀-skill-map)).
> 단계는 앞으로 건너뛰지 않지만, 후행 단계가 선행 구멍을 드러내면 **뒤로 회귀**(`<회귀 N→M>`)는 의무다.
> 각 단계 task는 **완료 산출물(Definition of Done)**(설계doc 저장·2단계 리뷰 통과·실행 검증 등)이 실재할 때만 닫힌다.

## references 구성 (출처)
| 파일 | 단계 | 출처 |
|------|------|------|
| `00-karpathy` | 전 단계 가드레일 | multica-ai/andrej-karpathy-skills (MIT) |
| `10-understand` | 이해·분석 | 자체 + Egonex-AI/Understand-Anything 라우팅 + 로컬 요구 명확화 사상 |
| `20-plan` | 설계·계획 | obra/superpowers brainstorming·writing-plans (MIT) |
| `30-implement` | 구현 | obra/superpowers subagent-driven-development (MIT) |
| `40-review` | 검수·마감 | obra/superpowers code-review·verification (MIT) |
| `50-peer-collab` | 2-pane 전 단계 | 자체 — Claude↔Codex 동등 협업 |
| `60-skill-orchestration` | 전 단계 | 자체 — 단계별 `/스킬` 호출 **유형** 맵 |
| `70-planning` | 전 단계(스킬 배선) | 자체 — 단계별 **구체 스킬 커스텀 매핑**(skill-map) |
| (저작도구) | — | Anthropic skill-creator |

---

## 레포 구조 (설치 시 ~/.claude 로 매핑)
```
under-claw-jarvis-plan/                    # 레포 루트
├── .claude-plugin/
│   ├── plugin.json                        # Claude Code 플러그인 매니페스트
│   └── marketplace.json                   # 플러그인 마켓플레이스 (이 레포가 곧 마켓플레이스)
├── .cursor-plugin/ · .copilot-plugin/     # Cursor / Copilot 플러그인 매니페스트
├── install.sh                             # 한 방 설치(스크립트 방식)
├── README.md · README.en.md               # 한국어(기본) / 영문
├── LICENSE  ·  THIRD_PARTY_NOTICES.md     # MIT + 출처 귀속
├── CONTRIBUTING.md · SECURITY.md · CODE_OF_CONDUCT.md  # 커뮤니티 문서
├── VERIFY-peer-collab.md                  # 2-pane 동등 협업 검증 시나리오
├── examples/skill-map.example.md          # 단계별 커스텀 스킬 맵 템플릿
├── tests/validate.sh                      # 구조·매니페스트·민감정보 검증 테스트
├── .github/workflows/ci.yml               # CI (push/PR 시 tests 실행)
├── commands/
│   └── under-claw-jarvis-plan.md          # /under-claw-jarvis-plan 진입점
└── skills/
    └── under-claw-jarvis-plan/            # 번들 (진입점은 위 command)
        ├── README.md
        └── references/                    # 00-karpathy ~ 60 + 70-planning + 90-test (9개)
```

## 설치

### A. 플러그인 마켓플레이스 (가장 쉬움 · 권장)
Claude Code 세션에서 두 줄:
```
/plugin marketplace add strong1133/under-claw-jarvis-plan
/plugin install under-claw-jarvis-plan@under-claw-jarvis-plan
```
- 업데이트: `/plugin marketplace update under-claw-jarvis-plan` 후 재설치.

### B. 원격 한 줄 설치 (스크립트)
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```
레포가 없으면 자동으로 임시 클론 후 설치한다(부트스트랩).

### C. 클론 후 설치
```bash
git clone https://github.com/strong1133/under-claw-jarvis-plan && cd under-claw-jarvis-plan && ./install.sh
```

> **다른 하니스(Cursor / Copilot)**: `.cursor-plugin/`·`.copilot-plugin/`에 `.claude-plugin/`과 동일한
> 플러그인 매니페스트를 동봉해, Cursor·GitHub Copilot의 플러그인 설치 흐름에서도 인식된다(방법론은 하니스 중립).

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

## 단계별 스킬 커스텀 (skill-map)
환경마다 실제 스킬명이 다르므로, 코어에는 **유형**만 적고 **구체 스킬은 외부 맵으로 바인딩**한다(→ `70-planning`).
1. `examples/skill-map.example.md` 를 복사해 아래 중 하나로 둔다:
   - 프로젝트: `<프로젝트>/docs/under-claw-jarvis-plan/skill-map.md`
   - 유저 전역: `~/.claude/under-claw-jarvis-plan.skillmap.md`
2. 단계 키(`phase2_understand`/`phase3_plan`/`phase4_implement`/`phase5_review`/`closing`)에 자기 스킬을 적는다.
3. 시작 시 오케스트레이터가 로드해 단계마다 호출(70이 60 유형 맵보다 우선). 맵이 없으면 60 fallback.
- 맵은 설치 폴더 **밖**에 있어 재설치/업데이트해도 보존된다.

## 자가진단 / 검증
```bash
/under-claw-jarvis-plan test    # 단계·스킬·model 점검 매트릭스 (읽기전용, 무변경)
bash tests/validate.sh          # 구조·매니페스트·민감정보 자동 검증 (CI에서도 실행)
```
- `VERIFY-peer-collab.md`: 2-pane 동등 협업 검증 시나리오(6대 신호/채점표).

## 메모리 / 선택 의존
- 메모리: **파일기반 경량**(설계doc = `docs/under-claw-jarvis-plan/specs/`). agentmemory 등 무거운 인프라 미사용.
- Understand-Anything: 설치 시 `/understand`·`/understand-diff`로 구조 매핑 강화, 미설치면 council fan-out.

## 출처·귀속 (포함된 오픈소스 스킬)
이 스킬의 reference 모듈은 아래 **MIT 오픈소스 스킬의 방법론을 발췌·적응(adapt)** 한 것이다(원문 그대로 복사 아님).
전체 고지는 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 참조.

| 모듈 | 출처 | 라이선스 |
|------|------|------|
| `00-karpathy` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | MIT |
| `10-understand` | 자체 라우팅 + [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) | MIT |
| `20-plan` / `30-implement` / `40-review` | [obra/superpowers](https://github.com/obra/superpowers) (brainstorming · subagent-driven-development · code-review/verification) | MIT |
| (저작 도구) | [anthropics/skills](https://github.com/anthropics/skills) — skill-creator | 해당 레포 |
| `50` / `60` / `70` / `90` | 자체 작성 (본 레포) | MIT |

## 라이선스
MIT — [`LICENSE`](LICENSE) 참조.
