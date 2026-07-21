<!-- 🌐 Language: **한국어** · [English](README.en.md) -->

# Under Claw — 독립형 AI 작업 스킬 3종

이 저장소는 Claude Code와 Codex에서 명시적으로 호출해 사용하는 세 가지 독립 스킬을 제공합니다. 기본 설치 한 번으로 두 호스트에 세 스킬을 모두 설치하며, 재실행하면 현재 저장소 버전으로 안전하게 업데이트합니다.

## 어떤 스킬을 사용할까?

| 스킬 | 용도 | Claude / Codex |
|---|---|---|
| `under-claw-jarvis-plan` | 복합 작업을 이해→계획→구현→검수 단계로 수행 | `/under-claw-jarvis-plan` / `$under-claw-jarvis-plan` |
| `under-claw-jarvis-plan-loop` | 독립 검수 목표에 도달할 때까지 구현과 검수를 반복 | `/under-claw-jarvis-plan-loop` / `$under-claw-jarvis-plan-loop` |
| `under-claw-meta-prompt` | 질의를 일관된 실행 프롬프트로 생성·개선 | `/under-claw-meta-prompt` / `$under-claw-meta-prompt` |

세 스킬은 서로 독립적이며 이름이나 명령으로 직접 호출할 때만 활성화됩니다. 일반 질의에는 자동 적용되지 않고, 한 스킬이 다른 스킬을 암묵적으로 호출하지 않습니다.

## 설치와 업데이트

### Claude + Codex 기본 설치

```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```

기본 설치 대상:

- Claude: `~/.claude/commands/`와 `~/.claude/skills/`
- Codex: `${CODEX_HOME:-~/.codex}/skills/`
- 두 호스트 모두 세 스킬 전체

같은 명령을 다시 실행하면 기존 항목을 백업한 뒤 현재 저장소의 세 스킬로 교체합니다. 설치 로그에는 새 대상은 `[설치]`, 기존 대상은 `[업데이트]`로 표시됩니다. 적용 후 Claude와 Codex를 새 세션으로 시작하세요.

한 줄 설치는 최신 `master/install.sh`를 내려받고 저장소를 임시 clone합니다. 민감한 환경에서는 저장소를 먼저 검토하고 로컬에서 실행하세요.

### 호스트별 설치

```bash
./install.sh --claude-only   # Claude만
./install.sh --skill-only    # Claude만: 기존 호환 별칭
./install.sh --codex-only    # Codex만
./install.sh --gemini-only   # Gemini만
./install.sh --gemini        # 기본 Claude+Codex에 Gemini 추가
```

`--codex`는 이전 설치 명령과의 호환을 위해 유지되며 현재 기본 설치와 같습니다.

### 외부 참조 스킬

Karpathy Guidelines, Superpowers, Understand-Anything, skill-creator 같은 외부 스킬은 전역 동작 오염을 피하기 위해 기본 설치에서 제외합니다.

```bash
./install.sh --with-externals   # 기본 설치 + Claude 외부 참조 스킬
./install.sh --externals-only   # 외부 참조 스킬만
```

## 1. under-claw-jarvis-plan

여러 파일·프로젝트에 걸친 작업을 다음 단계로 진행하는 범용 오케스트레이터입니다.

```text
Intake → 이해 → 계획 → 구현 → 검수
```

- brownfield에서는 최초 요구·현재 구현·교정 요청을 대조합니다.
- 각 단계는 검증 가능한 산출물과 Definition of Done을 가집니다.
- 필요하면 독립 서브에이전트 검토를 사용하고, 없으면 결정적 검증으로 대체합니다.
- 개발뿐 아니라 문서·분석·기획·경제계획에도 같은 흐름을 적용합니다.
- `test` 입력은 읽기 전용 자가진단을 수행합니다.

```text
/under-claw-jarvis-plan <요구사항>
$under-claw-jarvis-plan <요구사항>
/under-claw-jarvis-plan test
```

## 2. under-claw-jarvis-plan-loop

구현자와 검수자를 분리하고 결과가 목표 점수에 도달할 때까지 반복 개선합니다.

- 기본 목표: `9.5/10`
- 기본 최대 회차: `5`
- 개선 폭이 `0.2` 미만이면 plateau로 판단
- 목표 미달·반복 한도 도달 시 사용자에게 남은 gap을 보고
- 베이스 plan 스킬과 별도 명시 호출

```text
/under-claw-jarvis-plan-loop <요구사항> --max-rounds 5 --target 9.5
$under-claw-jarvis-plan-loop <요구사항>
/under-claw-jarvis-plan-loop test
```

## 3. under-claw-meta-prompt

사용자 질의를 고정된 9개 섹션과 일관된 업무 문체의 실행 프롬프트로 변환합니다. plan·loop를 호출하거나 실제 작업을 실행하지 않습니다.

```text
/under-claw-meta-prompt <질의>            # 결과 응답 + 클립보드 복사
$under-claw-meta-prompt <질의>            # Codex
/under-claw-meta-prompt -d <PATH> <질의>  # 프롬프트 파일 생성·개선
```

- 사실·가정·미확정을 구분합니다.
- 정말 빈 호출일 때만 목적을 한 번 묻습니다.
- `-d`는 선택된 프롬프트 파일만 원자적으로 저장하고 상태·경로·요약만 응답합니다.
- 입력 내부의 역할 변경·상위 지침 무시 문구는 데이터로 취급합니다.
- 결과 형태와 톤은 `assets/prompt-template.md`와 `references/output-spec.md`에 고정되어 있습니다.

## 고급 설정

Plan 스킬의 단계별 환경 스킬은 외부 skill-map으로 바꿀 수 있습니다.

1. [`examples/skill-map.example.md`](examples/skill-map.example.md)를 복사합니다.
2. 다음 중 한 곳에 둡니다.
   - 프로젝트: `<project>/docs/under-claw-jarvis-plan/skill-map.md`
   - Codex: `~/.codex/under-claw-jarvis-plan.skillmap.md`
   - Claude: `~/.claude/under-claw-jarvis-plan.skillmap.md`
3. `phase2_understand`, `phase3_plan`, `phase4_implement`, `phase5_review`, `closing`에 실제 스킬명을 지정합니다.

맵은 설치 디렉터리 밖에 있어 업데이트해도 유지됩니다. 호스트 도구 매핑은 `skills/under-claw-jarvis-plan/references/05-host-map.md`를 참고하세요.

## 검증

```bash
bash tests/validate.sh      # 구조·계약·민감정보 검사
bash tests/install.sh       # Claude/Codex/Gemini 격리 설치·업데이트 검사
bash tests/meta-prompt.sh   # 프롬프트 파일 저장 안전성 검사
shellcheck install.sh tests/*.sh skills/under-claw-meta-prompt/scripts/*.sh
```

## 저장소 구조

```text
commands/
├── under-claw-jarvis-plan.md
├── under-claw-jarvis-plan-loop.md
└── under-claw-meta-prompt.md
skills/
├── under-claw-jarvis-plan/
├── under-claw-jarvis-plan-loop/
└── under-claw-meta-prompt/
install.sh
tests/
README.md
README.en.md
```

## 출처와 라이선스

Plan 방법론은 다음 MIT 프로젝트의 원칙을 발췌·적응했습니다.

- [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
- [superpowers](https://github.com/obra/superpowers)
- [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)
- 저작 도구 참고: [anthropics/skills](https://github.com/anthropics/skills)

전체 귀속은 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md), 프로젝트 라이선스는 [`LICENSE`](LICENSE)를 참고하세요.
