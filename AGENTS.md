# {{PROJECT_NAME}} — 작업 가이드 (Claude Code / Codex 공통)

> **{{STACK_ONE_LINE}}** · {{ARCH_ONE_LINE}} · {{ENFORCEMENT}} (위반 시 빌드 실패)

<!-- 이 파일은 프로젝트 공통 지침의 단일 원본이다.
     예산: 120줄 / 8KiB 이하. 상세 규칙은 docs/ 가 소유하고 여기서는 라우팅만 한다.
     변경 절차는 docs/conventions/instruction-maintenance.md 참조. -->

## 구조

- 소스 루트: `{{SRC_ROOT}}` — {{모듈/패키지 경계 한 줄}}
- {{하위 구조 한 줄 — 디렉터리 트리를 옮겨 적지 말 것. 코드로 자명한 건 생략}}
- {{서브모듈·별도 저장소가 있으면 그 경계와 커밋 분리 규칙}}

## 개인 vs 공용 (지침을 쓰기 전에 판정)

- 이 파일과 `docs/**` 는 **팀 전원에게 참인 규칙만** 담는다 — 커밋 대상
- 개인 메모·로컬 환경·진행 상황은 `CLAUDE.local.md` (Codex 는 `~/.codex/AGENTS.md`), 개인 설정은 `.claude/settings.local.json` — 모두 커밋 금지
- **"이거 기억해둬" 류 요청은 기본적으로 개인 파일에 쓴다.** 공용 지침 승격은 `docs/conventions/instruction-maintenance.md` 절차를 따른다
- 공용에 넣을지 애매하면 개인 파일에 두고, 세 번 이상 팀에 유용했을 때 승격을 제안한다

## 판단이 갈릴 때

- 우선순위: **기계 강제(테스트·린터) > `docs/` > 이 파일 > 개인 파일.** 낮은 쪽이 높은 쪽을 이기지 못한다
- 문서와 코드가 어긋나면 코드를 정답으로 단정하지 말고 **어긋남 자체를 보고**한다 (`docs/adr` 로 의도 판정)
- 확인하지 못한 것은 "확인 필요"로 남긴다. 추측을 검증된 사실처럼 쓰지 않는다
- 범위 밖 수정이 필요해 보이면 조용히 하지 말고 제안한다

## 핵심 불변식 {{N}}

<!-- 코드만 봐서는 알 수 없고, 어기면 실제로 사고가 났던 것만. 각 항목 한 줄. -->

1. {{불변식 1}}
2. {{불변식 2}}
3. {{불변식 3}}
4. {{불변식 4}}
5. {{불변식 5}}

## {{핵심 분류 규칙}} 판정 순서

<!-- 매번 헷갈리는 판정이 있으면 알고리즘으로 적는다. 없으면 이 절 삭제. -->

1. {{조건}} → `{{위치}}`
2. {{조건}} → `{{위치}}`
3. 그 외 → `{{위치}}`

## 금지 목록 (자동 검증 — 카탈로그: `docs/architecture/patterns.md`)

<!-- 기계가 잡아주는 것만 짧게. 잡아주지 못하는 규칙은 docs 로. -->

1. {{금지 1}}
2. {{금지 2}}
3. {{금지 3}}

## 코딩 컨벤션

- {{생성자 주입·트랜잭션 등 프레임워크 관행 한 줄}}
- 명명: {{조회/생성/수정/삭제 접두사 규칙}}
- {{응답·에러 표준 한 줄}}
- 주석: {{타입 레벨 / 내부 주석 스타일}} — 시그니처로 자명한 정보 생략, 비자명한 WHY만

## 검증 명령

```bash
{{BUILD_CMD}}              # 컴파일 검증
{{ARCH_TEST_CMD}}          # 아키텍처 규칙 검증
{{TEST_CMD}}               # 전체 테스트
./tools/verify-instructions.sh   # 지침 문서 구조 검증
{{RUN_CMD}}                # 로컬 실행
```

## 필독 라우팅

아래 trigger에 해당하는 작업은 **시작 전에 해당 문서를 실제로 읽는다**. 여러 trigger가 겹치면 모두 읽는다.

<!-- 이 표의 백틱 경로는 tools/verify-instructions.sh 가 존재 여부를 검사한다. -->

| 작업 trigger | 먼저 읽을 문서 |
|---|---|
| 구조·경계·신규 모듈 | `docs/architecture/project-structure.md` |
| 패턴·규칙 카탈로그 | `docs/architecture/patterns.md` |
| 테스트 생성·이동 | `docs/conventions/test-structure.md` |
| `AGENTS.md`/`CLAUDE.md`/`.claude/**`/`.codex/**` 변경 | `docs/conventions/instruction-maintenance.md` |
| 지침에 무엇을 넣지 말아야 하는지 | `docs/conventions/instruction-antipatterns.md` |
| 아키텍처 결정 배경 | `docs/adr` |

## 완료 조건

- [ ] 관련 테스트 + 아키텍처 검증 통과
- [ ] 라우팅 표에서 읽은 문서의 규칙 준수 확인
- [ ] 변경 diff self-review — 범위 밖 수정·불필요한 추가 없음
- [ ] 지침/문서 변경 시 `./tools/verify-instructions.sh` 통과
