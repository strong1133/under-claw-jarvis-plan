# docs — 상세 규칙의 SSOT

루트 `AGENTS.md` 는 지도이고, **규칙의 정본은 이 폴더다.** 루트나 `.claude/rules` 에 상세 규칙을 복사하지 않는다.

## 구성

| 경로 | 소유 범위 |
|---|---|
| `architecture/project-structure.md` | 패키지·모듈 경계, 배치 판정 |
| `architecture/patterns.md` | 핵심 패턴 카탈로그 + 자동 검증 룰 대응표 |
| `conventions/test-structure.md` | 테스트 배치·명명·실행 |
| `conventions/instruction-maintenance.md` | 지침 문서 자체의 변경 절차 |
| `adr/` | 되돌리기 어려운 결정과 그 배경 |
| `skills/` | 세 스킬이 에이전트에게 지시하는 내용의 파일별 설명 (정본은 `commands/`·`skills/`·`shared/`) |

## 문서 헤더 규약

권위 문서는 첫 줄에 상태 헤더를 둔다. 코드와 대조한 날짜와 근거 위치를 남기는 것이 목적이다.

```markdown
> Status: active · Last verified: {{YYYY-MM-DD}} · commit {{sha}} · anchor: `{{대조한 코드 경로}}`
```

`Last verified` 는 **실제로 코드를 대조했을 때만** 갱신한다. 날짜만 바꾸는 형식적 갱신은 문서를 더 위험하게 만든다 — 틀린 내용에 최신 도장을 찍는 셈이기 때문이다.

이 헤더는 `tools/verify-instructions.sh` 가 `architecture/`·`conventions/` 하위 문서에 대해 존재를 강제한다. (`adr/` 는 자체 상태 표기를 쓰므로 대상이 아니다.)

## 고정 수치 금지

개수를 못 박는 표현은 쓰지 않는다. 반드시 틀어지고, 틀어진 문서는 나머지 내용까지 신뢰를 잃는다. 세고 싶으면 **세는 명령**을 적는다.

이미 틀린 것으로 판명된 표현은 `tools/stale-patterns.txt` 에 등록한다. 그 뒤로는 어느 문서에든 다시 나타나면 검증이 실패한다 — 사람이 리뷰로 잡기 가장 어려운 종류의 회귀다. 나쁜 예시로 일부러 인용해야 하면 그 줄에 `stale-ok` 를 남긴다.
