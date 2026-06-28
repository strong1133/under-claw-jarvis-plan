<!-- 🌐 Language: **한국어** · [English](README.en.md) -->

# under-claw-jarvis-plan — 요구사항을 단계로 사고하는 스킬

"무엇을 만들지"를 받으면 **이해 → 계획 → 구현 → 검수** 네 단계로 나눠 사고하고,
**각 단계마다 알맞은 스킬·방법론을 불러 쓰는** Claude Code 스킬이다.
**단독(solo) 세션에서 바로 동작한다** — tmux·2-pane·외부 모델 없이.

> 한마디로: 요구사항을 받아 **혼자 단계를 밟아가며 생각하고 실행하는 사고(reasoning) 스킬**.
> 멀티에이전트·교차모델은 *더 깊이 생각하기 위한 선택적 증폭*일 뿐, 필수가 아니다.

### 외부 참조 스킬 (크레딧)
이 스킬은 아래 **3개 오픈소스 스킬의 방법론을 외부 참조로 차용(adapt)** 한다(재구현이 아니라 호출·적용). 모두 MIT.
| 외부 참조 스킬 | 출처(GitHub) | 적용 모듈 → 단계 |
|---|---|---|
| **Karpathy Guidelines** | https://github.com/multica-ai/andrej-karpathy-skills | `00-karpathy` → 전 단계 가드레일 |
| **Superpowers** | https://github.com/obra/superpowers | `20`/`30`/`40` → 계획·구현·검수 |
| **Understand-Anything** | https://github.com/Egonex-AI/Understand-Anything | `10-understand` → 이해(선택) |

전체 라이선스·귀속 고지는 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

---

## 설치 (한 줄 — 의존 스킬까지 전부)
### Claude Code
터미널에 이 한 줄이면 끝:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```
under-claw-jarvis-plan + **의존(외부 참조) 스킬**(Karpathy · Superpowers · Understand-Anything · skill-creator)까지
모두 `~/.claude`에 설치한다. 레포가 없으면 자동 임시 클론(부트스트랩), 기존 파일은 자동 백업(멱등·안전).
설치 후 아무 세션에서 `/under-claw-jarvis-plan`.

- ⚠️ **Understand-Anything**은 pnpm 플러그인이라 설치 끝에 안내되는 **수동 1스텝**이 필요(선택 — 없어도 under-claw-jarvis-plan은 동작).
- 스킬만(의존 제외): `… | bash -s -- --skill-only`
- 개발용 클론 설치: `git clone https://github.com/strong1133/under-claw-jarvis-plan && cd under-claw-jarvis-plan && ./install.sh`

### Codex
Codex 사용자 스킬로 설치:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --codex-only
```
설치 위치는 `${CODEX_HOME:-~/.codex}/skills/under-claw-jarvis-plan`이다. 설치 후 새 Codex 세션에서 `$under-claw-jarvis-plan`.

Claude와 Codex를 동시에 설치하려면 `--codex`를 붙인다:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --codex
```

### Gemini
Gemini 사용자 스킬로 설치:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --gemini-only
```
설치 위치는 `${GEMINI_HOME:-~/.gemini}/skills/under-claw-jarvis-plan`이고 진입점은 `GEMINI.md`다. Claude와 함께 설치하려면 `--gemini`.

### 그 외 에이전트 (범용)
방법론(`references/`)은 **에이전트 중립**이다. 호스트마다 다른 건 작업추적·스킬호출·멀티에이전트
**세 도구의 이름뿐**이고, 그 매핑과 fallback은 `references/05-host-map.md`에 데이터로 정리돼 있다.
전용 진입점이 없는 에이전트도 `SKILL.md`/`GEMINI.md` 중 가용한 것을 로드하면 generic LLM fallback으로 동일하게 구동된다.

---

## 설계 사상 (요약)
1. **요구사항을 단계로 분해해 사고한다.** 바로 코딩에 뛰어들지 않고 *이해→계획→구현→검수*로 끊어,
   한 단계의 산출물이 다음 단계의 입력이 된다.
2. **재구현하지 않고 불러 쓴다.** 각 단계에서 환경에 이미 있는 `/스킬`과 **3개 외부 참조 스킬**의 방법론
   ([Karpathy](https://github.com/multica-ai/andrej-karpathy-skills) ·
   [Superpowers](https://github.com/obra/superpowers) ·
   [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything))을 호출·적용한다. 스킬 자신은 "지휘자".
3. **단독 세션이 기본.** 깊은 사고가 필요한 단계는 *현재 세션의 서브에이전트*로 독립 병행 → 교차 검토 → 합의.
   추가 환경 불필요. (제2 모델 peer가 있으면 교차-모델로 확장 — 선택)
4. **환경에 종속되지 않는다.** 작업 경로는 프롬프트로 받고, 단계별 구체 스킬은 외부 `skill-map`으로 갈아끼운다.
5. **건너뛰지 않게 강제한다.** 단계 순서 · 완료 산출물(DoD) · 뒤로 회귀를 규약으로 박아 "대충 스킵"을 막는다.

> 단순 질의(조회·설명·단발 수정)는 단계를 생략하고 즉답한다 — 사고 비용은 복합 작업에만 쓴다.

## 진행 단계
```
/under-claw-jarvis-plan 또는 $under-claw-jarvis-plan
   0 Intake → 2 이해 → 3 계획 → 4 구현 → 5 검수·마감
   (00 / 50 / 60 / 70 은 전 단계 상시 · 단순 질의는 즉답)
```
| 단계 | 하는 일 | 방법론 모듈 (← 외부 참조 스킬) | 각 단계 사용 스킬 |
|------|---------|-------------------------------|--------------------|
| **0 Intake** | 경로·요구·정리문서·제약 파싱, 신규(greenfield)/수정(brownfield) 판정, 빠진 것만 질문 | commands 본체 | — |
| **2 이해** | 요구 정렬(소크라테스식) + 코드구조 매핑 + (brownfield) **3자 대조**(최초요구↔현재구현↔교정) | `10-understand` ← **[Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)** | 요구 명확화·계약 검증·프론트 패턴 검증 스킬·`deep-research`·(Understand-Anything) |
| **3 계획** | 접근법 비교 → 설계 합의 → **설계 doc(고정 스키마)** → 검증가능 task 분할 | `20-plan` ← **[Superpowers](https://github.com/obra/superpowers)** | `deep-research` |
| **4 구현** | task별 fresh 작업자 + **2단계 리뷰(스펙→품질)** | `30-implement` ← **[Superpowers](https://github.com/obra/superpowers)** | 스타일 규칙 조회·디자인→코드 퍼블리싱·API 컬렉션 동기화 스킬 |
| **5 검수·마감** | 종합 리뷰 + 실행 검증 + 정리 문서 | `40-review` ← **[Superpowers](https://github.com/obra/superpowers)** | 검수: 프론트 패턴·계약·스타일(Tailwind) 점검·`code-review`·`security-review`·`simplify`·`verify` / 마감: 문서화(ADR)·API 동기화·후속 작업 등록(todo) |
| **전 단계 상시** | 행동 가드레일(00) · council 협업(50) · 스킬 유형맵(60) · 구체 스킬 배선(70) | `00-karpathy` ← **[Karpathy](https://github.com/multica-ai/andrej-karpathy-skills)** · `50`·`60`·`70`(자체) | ※ Karpathy 4원칙(가정금지·단순·외과적·검증) 가드레일을 **전 단계 상시** 적용 |

> 단계는 **앞으로 건너뛰지 않지만**, 후행 단계가 선행 구멍을 드러내면 **뒤로 회귀**(`<회귀 N→M>`)는 의무다.
> 각 단계 task는 **완료 산출물(Definition of Done)**(설계doc 저장·2단계 리뷰 통과·실행 검증 등)이 실재할 때만 닫힌다.

## 사용
```
/under-claw-jarvis-plan        # Claude: 작업 경로(복수 가능) + 요구사항을 프롬프트로 전달
$under-claw-jarvis-plan        # Codex: 작업 경로(복수 가능) + 요구사항을 프롬프트로 전달
/under-claw-jarvis-plan test   # Claude 자가진단(읽기전용)
$under-claw-jarvis-plan test   # Codex 자가진단(읽기전용)
```
- **단독 Claude(기본)**: council = 현재 세션의 `Agent`/`Workflow` 서브에이전트. 추가 도구 없음.
- **제2 모델 peer(선택)**: 환경에 다른 모델(예: 2-pane Claude+Codex)이 있으면 교차-모델 동등 협업으로 확장.

## 루프 변형 — `under-claw-jarvis-plan-loop` (자기수렴)
베이스를 **한 회차**로 반복하고, 회차마다 **분리된 독립 검수 세션**이 원요구·소스패턴 준수를
**10점 만점**으로 채점한다. **9.5 초과 시에만 종료**(미달이면 gap을 다음 회차로 전달, Reflexion).
```
/under-claw-jarvis-plan-loop {요구사항}            # 9.5 게이트까지 자기수렴 (--max-rounds N, --target X.X)
$under-claw-jarvis-plan-loop {요구사항}            # Codex
/under-claw-jarvis-plan-loop test                 # 자가진단(읽기전용, 루프 미실행)
```
- **3 역할 = 3 분리 세션**(검수 분리 원칙):
  ① 루프 오케스트레이터(메인) — 회차 진행·검수 전달·종료 결정
  ② 검수담당(**구현·오케스트레이터와 별개 세션**) — 10점 채점, 적대적·회의적
  ③ 구현담당(**회차마다 fresh 세션**) — 베이스 under-claw-jarvis-plan 완주 후 오케스트레이터에 보고
- **채점**: D1 요구 충실도 4.0 / D2 정확성·타당성 3.0 / D3 관례·패턴(소스패턴 일반화) 2.0 / D4 품질·단순성 1.0.
- **안전장치**: MAX_ROUNDS cap(기본 5) + plateau(개선<0.2) → 무한 루프 금지, 미수렴 시 사용자 에스컬레이션.
- **도메인 무관**: 개발뿐 아니라 파일생성·분석·기획·경제계획 등에 동일 적용. 페르소나·시스템프롬프트는
  `skills/under-claw-jarvis-plan-loop/references/`(`10-orchestrator`/`20-implementer`/`30-reviewer`/`40-scoring`).

## 단계별 스킬 커스텀 (skill-map)
환경마다 실제 스킬명이 다르므로, 코어에는 **유형**만 적고 **구체 스킬은 외부 맵으로 바인딩**한다(→ `70-planning`).
1. `examples/skill-map.example.md` 를 복사해 아래 중 하나로 둔다:
   - 프로젝트: `<프로젝트>/docs/under-claw-jarvis-plan/skill-map.md`
   - Codex 전역: `~/.codex/under-claw-jarvis-plan.skillmap.md`
   - Claude 전역: `~/.claude/under-claw-jarvis-plan.skillmap.md`
2. 단계 키(`phase2_understand`/`phase3_plan`/`phase4_implement`/`phase5_review`/`closing`)에 자기 스킬을 적는다.
3. 시작 시 오케스트레이터가 로드해 단계마다 호출(70이 60 유형 맵보다 우선). 맵이 없으면 60 fallback.
- 맵은 설치 폴더 **밖**에 있어 재설치/업데이트해도 보존된다.

## 자가진단 / 검증
```bash
/under-claw-jarvis-plan test    # 단계·스킬·model 점검 매트릭스 (읽기전용, 무변경)
bash tests/validate.sh          # 구조·매니페스트·민감정보 자동 검증 (CI에서도 실행)
```
- `VERIFY-peer-collab.md`: (선택) 2-pane 동등 협업 검증 시나리오(6대 신호/채점표).

## 외부 참조 스킬 & 출처·귀속 (크레딧)
방법론 모듈은 아래 **외부 참조 오픈소스 스킬(MIT)의 방법론을 발췌·적응(adapt)** 한 것이다(원문 그대로 복사 아님).
전체 고지는 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 참조.

| 모듈 | 단계 | 외부 참조 스킬(출처 GitHub) | 라이선스 |
|------|------|------|------|
| `00-karpathy` | 전 단계 가드레일 | **Karpathy Guidelines** — [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | MIT |
| `10-understand` | 이해 | 자체 라우팅 + **Understand-Anything** — [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) | MIT |
| `20-plan`·`30-implement`·`40-review` | 계획·구현·검수 | **Superpowers** — [obra/superpowers](https://github.com/obra/superpowers) (brainstorming · subagent-driven-development · code-review/verification) | MIT |
| `50`·`60`·`70`·`90` | 협업·배선·자가진단 | 자체 작성 (본 레포) | MIT |
| (저작 도구) | — | [anthropics/skills](https://github.com/anthropics/skills) — skill-creator | 해당 레포 |

## 레포 구조
```
under-claw-jarvis-plan/
├── .claude-plugin/{plugin.json, marketplace.json}   # Claude Code 플러그인 + 마켓플레이스
├── .cursor-plugin/ · .copilot-plugin/               # Cursor / Copilot 매니페스트
├── install.sh                                       # 스크립트 설치(원격 부트스트랩 포함)
├── README.md · README.en.md                         # 한국어(기본) / 영문
├── LICENSE · THIRD_PARTY_NOTICES.md                 # MIT + 출처 귀속
├── CONTRIBUTING.md · SECURITY.md · CODE_OF_CONDUCT.md
├── examples/skill-map.example.md                    # 단계별 커스텀 스킬 맵 템플릿
├── tests/validate.sh · .github/workflows/ci.yml     # 테스트 + CI
├── commands/
│   ├── under-claw-jarvis-plan.md                    # /under-claw-jarvis-plan 진입점
│   └── under-claw-jarvis-plan-loop.md               # /under-claw-jarvis-plan-loop 진입점(루프)
└── skills/
    ├── under-claw-jarvis-plan/
    │   ├── SKILL.md · GEMINI.md                     # Codex / Gemini 진입점
    │   ├── agents/openai.yaml                       # Codex UI 메타데이터
    │   └── references/                              # 00 + 05-host-map + 10 … 70 + 90 (방법론 + 호스트 어댑터)
    └── under-claw-jarvis-plan-loop/                 # 루프 변형(베이스 = under-claw-jarvis-plan)
        ├── SKILL.md · GEMINI.md                     # Codex / Gemini 진입점
        ├── agents/openai.yaml
        └── references/                              # 00-loop-control + 10-orchestrator + 20-implementer + 30-reviewer + 40-scoring + 90-test
```

## 메모리 / 선택 의존
- 메모리: **파일기반 경량**(설계doc = `docs/under-claw-jarvis-plan/specs/`). 무거운 인프라 미사용.
- Understand-Anything: 설치 시 `/understand`·`/understand-diff`로 구조 매핑 강화, 미설치면 council fan-out.

## 라이선스
MIT — [`LICENSE`](LICENSE) 참조.
