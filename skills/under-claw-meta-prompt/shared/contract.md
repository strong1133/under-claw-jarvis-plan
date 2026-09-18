# 공통 작업 명세 v1

plan의 Intake와 meta-prompt의 `--spec` 모드에서 읽는다. 입력에 명세가 있으면 재사용하고,
없으면 원요구·확인한 자료로 작성한다. 다른 스킬 호출을 전제로 하지 않는다.

명세는 JSON이다. 최소 예시:

```json
{
  "schema_version": 1,
  "goal": "고객 안내문 작성",
  "scope": ["안내문 파일"],
  "constraints": ["원문의 요금과 날짜 유지"],
  "blocking_questions": [],
  "criteria": [
    {"id": "C1", "description": "요금과 날짜가 원문과 일치", "required": true,
     "verification": "원문과 최종 문서의 수치 대조", "stage": "implement"}
  ]
}
```

- `schema_version`은 1. `goal`과 `criteria`는 비어 있을 수 없다. `scope`는 변경 대상,
  `constraints`는 유지 조건과 채택한 가정(`가정:` 접두)이다. 범위 밖 기능을 명세에 추가하지 않는다.
- 기준 ID는 명세 안에서 고유하다. 각 기준의 `required`는 boolean,
  `verification`은 실제 확인 방법, `stage`는 `understand|plan|implement|review` 중
  그 기준이 실패했을 때의 기본 복귀 단계다. 실제 원인에 따라 검수자가 더 앞 단계로 조정한다.
- `blocking_questions`에는 실행 결과를 바꾸며 스스로 확인할 수 없는 질문만 넣는다.
  기존 자료에서 확인 가능한 것은 먼저 찾고, 사용자가 이미 준 답은 다시 묻지 않는다.
- 명세 파일의 바이트 SHA-256을 실행·검수 기록에 묶는다. 실행 중 원요구를 낮춰 통과시키지 않는다.
  사용자가 요구를 바꾸면 기존 명세를 보존하고 새 버전을 작성해 변경 이유를 기록한다.
  질문은 Intake에서 한 번에 묻는다. 답을 받지 못했거나 시작한 뒤 생긴 질문은 채택한 가정을 `constraints`에
  기록한 명세 새 버전으로 진행한다. 틀린 가정이 위험하거나 결과를 쓸 수 없게 만드는 질문만
  `blocking_questions`에 남긴다. 남아 있는 동안 PASS는 보류하되, 그 질문에 의존하지 않는 기준은 끝까지 수행한다.
- 단순 조회·단발 수정은 별도 명세 파일을 강제하지 않는다. 복합 작업과 loop는
  작업별 기록 디렉터리에 `contract.json`과 회차별 evidence를 둔다.

검사: `python3 shared/evidence.py contract contract.json`
(명령의 `shared/`는 현재 설치된 스킬 번들 안 경로로 해석한다.)

## 기록 저장소 선택

작업 시스템이 연결돼 있으면 그 시스템의 기존 Task/Execution/Work Log/Graph run이 정본이다.
명세와 검증 파일은 해당 실행에 연결하는 증거이며, 별도의 progress 원장을 만들지 않는다.
CAS version·서버가 계산하는 상태·append-only 이력을 지키고 직접 DB 변경으로 우회하지 않는다.
작업 시스템이 없는 환경만 로컬 작업별 디렉터리를 사용한다.
재개 시 원요구·명세 해시·최신 회차·미해결 기준·산출물 해시를 다시 확인한다.
예전 PASS는 해시가 달라진 산출물에 승계하지 않는다.
