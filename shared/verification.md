# 증거 기반 검증 v1

plan 검수와 loop 종료 판정에서 읽는다. 성공은 필수 기준·실행 증거·중대 결함 여부로
먼저 판정하고, loop만 여기에 품질 점수 TARGET을 더한다.

1. **실행 검증**: 코드 테스트, 원문 수치 대조, 화면 렌더링, 외부 변경 후 재조회처럼
   명세에 맞는 검사를 실제 수행한다. 실행하지 않은 검사는 `unknown`이며 통과가 아니다.
2. **의미 검수**: 실행 로그가 정말 해당 요구를 입증하는지, 누락·범위 이탈·중대 결함이
   없는지 검수한다. 산출물과 명세·증거를 읽고 판단하며 구현자의 자기점수를 근거로 쓰지 않는다.
3. **합의**: 가능한 독립 검수 컨텍스트를 사용한다. 없으면 역할 패스와 실행 증거로
   `degraded` 검수를 수행하고 최종 결과에 `DEGRADED_REVIEW`를 공개한다.
   같은 세션을 독립 검수라고 부르지 않는다. 분리가 필수인 사용자 지시는 임의 완화하지 않는다.

## 검수 보고 JSON

```json
{
  "schema_version": 1,
  "contract_sha256": "명세 파일의 SHA-256",
  "review_mode": "independent",
  "artifacts": [
    {"path": "output.md", "sha256": "최종 산출물의 SHA-256", "kind": "deliverable"},
    {"path": "checks.txt", "sha256": "검증 기록의 SHA-256", "kind": "evidence"}
  ],
  "results": [
    {"id": "C1", "status": "pass", "evidence": ["checks.txt"],
     "note": "원문의 요금과 날짜를 최종 문서와 대조해 일치 확인", "stage": "implement"}
  ],
  "blockers": [],
  "scores": {"D1": 4.0, "D2": 3.0, "D3": 2.0, "D4": 0.8}
}
```

모든 기준의 결과를 기록한다. `status`는 `pass|fail|unknown`.
필수 기준은 `pass`와 하나 이상의 evidence 파일이 있어야 한다. 선택 기준의 실패는
보고하되 단독 차단하지 않는다. 중대 결함과 범위 위반은 `blockers`에 기록한다.
`artifacts`에는 검수한 최종 산출물과 실제 검사 기록을 함께 담고 각 파일 해시를 계산한다.
파일 경로는 `--root` 안 상대 경로다. 외부 문서·웹 결과는 ID/URL, 조회 시각, revision과
판정 근거를 로컬 증거 파일에 기록하고 민감정보를 제거한다. 코드 파일만으로 테스트 실행을
입증할 수 없다. 테스트 로그는 실행 명령·대상 revision·종료 코드·핵심 출력을 포함한다.

```bash
python3 shared/evidence.py judge contract.json report.json --root ./run
# loop에서만 점수도 검사:
python3 shared/evidence.py judge contract.json report.json --root ./run --target 9.5
```

종료 코드: 0=PASS, 1=기준/해시/증거/점수 미달, 2=잘못된 입력.
출력은 JSON이며 `passed`, `hard_pass`, `score`, `resume_stage`, `issues`를 포함한다.
기준별 실패는 가장 앞선 관련 단계로 복귀한다. 산출물 해시·증거 누락·보고 구조 문제는
먼저 review로 돌아가 재검증한다. hard_pass 실패 시 품질 점수 미달만으로 추가 구현을
지시하지 않는다. 명세 해시 불일치와 질문 미해결은 understand로 복귀한다.

이 스크립트는 **보고의 일관성·해시·게이트만 검사**한다. 테스트를 대신 실행하거나
LLM 판정의 진실성·의미 보존·독립성 자체를 증명하지 않는다. 실행 로그와 실물 검수는
앞의 단계에서 수행해야 한다. Python이 없으면 같은 항목을 수동 대조하고 자동 검사
미실행 사실을 밝힌다. 누락 증거를 추측해 채우거나 낮은 점수를 반올림해 통과시키지 않는다.
