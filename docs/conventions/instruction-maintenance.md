# 지침 문서 유지관리 (instruction-maintenance)

> Status: active · Last verified: {{YYYY-MM-DD}} · commit {{sha}} · anchor: `AGENTS.md`, `.claude/`, `.codex/`, `tools/verify-instructions.sh`
>
> 이 문서는 `AGENTS.md` / `CLAUDE.md` / `.claude/**` / `.codex/**` 변경 절차의 SSOT다.

## 4계층 구조

1. **루트 상시 계층** — `AGENTS.md` (120줄 / 8KiB). 모든 세션이 항상 읽는다. 여기 넣은 한 줄은 앞으로의 모든 대화에 비용을 청구한다
2. **조건부 라우팅 계층** — `.claude/rules/*.md` (경로가 맞을 때만 로딩) + 루트 라우팅 표 (Codex 는 이쪽만 있다)
3. **상세 기록 계층** — `docs/`. 예시·이유·예외·체크리스트를 소유한다
4. **강제 계층** — 컴파일러·린터·아키텍처 테스트·`tools/verify-instructions.sh`

**문서보다 강제가 우선이다.** 기계가 잡을 수 있는 규칙을 문장으로 적는 것은 가장 약한 수단이다.

## 하위 디렉터리 지침

모듈별로 다른 규칙은 루트에 쌓지 말고 `{{모듈}}/AGENTS.md` + `{{모듈}}/CLAUDE.md`(bridge) 쌍으로 둔다. **두 도구 공통으로 동작하는 유일한 조건부 수단**이다 (Codex 는 루트→CWD 체인, Claude 는 그 폴더 파일에 접근할 때 로딩).

- 예산 40줄. 넘으면 `docs/` 로 내리고 참조만 남긴다
- 루트 규칙을 재진술하지 않는다. **"이 모듈에서만 다른 것"** 만 적는다
- `CLAUDE.md` bridge 를 빠뜨리면 Codex 만 읽는 반쪽 지침이 된다 — 검증이 잡는다

## 파일별 성격

- `AGENTS.md` — 프로젝트 공통 지침의 단일 원본. Claude Code 와 Codex 가 함께 읽는다
- `CLAUDE.md` — 정확히 `@AGENTS.md` 한 줄 bridge. 다른 내용 추가 금지
- `.claude/**` — Claude 전용. Codex 는 읽지 않는다
- `.codex/**`, `.agents/skills/**` — Codex 전용. Claude 는 읽지 않는다
- 개인 파일 — `CLAUDE.local.md`, `.claude/settings.local.json`, `.claude/agent-memory/`, `~/.claude/`, `~/.codex/`. 커밋 금지

## 공용 문서 vs 개인 문서

| | 공용 (커밋) | 개인 (gitignore) |
|---|---|---|
| 지침 | `AGENTS.md`, `docs/**` | `CLAUDE.local.md` |
| 설정 | `.claude/settings.json`, `.codex/config.toml` | `.claude/settings.local.json`, `~/.codex/config.toml` |
| 스킬 | `.claude/skills/**`, `.agents/skills/**` | `~/.claude/skills/**`, `~/.codex/skills/**` |
| 판단 기준 | 팀 전원에게 참인가? 신규 입사자가 몰라서 사고를 내는가? | 내 머신·내 취향·내 진행 상황인가? |

개인 문서에 적은 규칙이 세 번 이상 팀에 유용했다면 승격 후보다. 반대로 공용 지침에 있는데 나만 쓰는 것은 내려보낸다.

## 규칙 후보 승격 절차

한 번의 실수를 곧바로 상시 지침에 추가하지 않는다.

1. 실제 실패·리뷰 근거와 재발 가능성을 해당 작업의 PR/issue 에 기록한다 (상시 로딩 문서·무기한 backlog 금지)
2. 기계로 강제할 수 있으면 문서보다 강제를 택한다
3. 코드만으로 알 수 없는 규칙인지 확인한다 — 타입·시그니처로 자명하면 적지 않는다
4. root / path-scoped rule / 하위 디렉터리 지침 / 상세 docs 중 **가장 좁은 유효 scope** 를 고른다
5. PR 에서 추가 이유·적용 범위·검증 방법·기존 규칙과의 충돌을 리뷰한다

## 수록 기준

- **포함**: 복사 가능한 빌드·테스트 명령 / 코드만으로 알기 어려운 경계·우선순위·gotcha / 반복 실패를 막는 구체적 불변식
- **제외**: 디렉터리 트리나 타입으로 자명한 사실 / 일반적 best practice / 추상적 표현 / 재발 가능성 낮은 일회성 수정

## 변경 PR 요건

- 추가·수정·삭제 이유(WHY)와 검증 방법 명시
- `./tools/verify-instructions.sh` 통과
- 상세 규칙은 `docs/` 를 먼저 고치고, 라우팅 경로나 짧은 불변식이 달라질 때만 루트/rule 을 함께 수정
- 스킬을 고쳤으면 `./tools/sync-skills.sh` 로 Codex 미러까지 갱신
- docs 와 코드가 충돌하면 현재 코드를 무조건 정답으로 단정하지 말고 ADR·테스트로 의도를 판정한 뒤 결정 기록을 남긴다

## Gardening (월 1회 또는 주요 구조 변경 후)

- [ ] 최근 추가 규칙의 근거·중복·scope·실효성 검토
- [ ] 코드로 자명해졌거나 기계 강제로 대체된 규칙 삭제
- [ ] 권위 docs 의 `Last verified`·commit·anchor 갱신 — 실제 코드 대조 필수
- [ ] 고정 수치가 다시 생기지 않았는지 확인 — 틀린 것으로 판명된 표현은 `tools/stale-patterns.txt` 에 등록
- [ ] 크기 예산(루트 120줄 / 8KiB, 하위 40줄) 준수 확인
- [ ] Claude ↔ Codex 미러 동기화 확인 (`./tools/sync-skills.sh --check`)
- [ ] 라우팅 표에서 이제 아무도 안 읽는 문서가 있는지 — 있으면 지우거나 합친다
