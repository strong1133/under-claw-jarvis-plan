# 90 · 읽기 전용 자가진단

입력이 `test`면 실제 루프·설치·외부 쓰기를 수행하지 않는다.

- 베이스 진입점·references와 loop의 00/10/20/30/40 모듈을 찾는다.
- 번들의 shared/contract.md, verification.md, evidence.py, components.json과 네 어댑터를 확인한다.
- TARGET 기본 9.5, MAX_ROUNDS 기본 5, 선택 MAX_SECONDS, plateau/BLOCK 의미를 설명한다.
- 필수 기준 실패 + 10점은 FAIL, hard_pass + 9.5는 PASS, 9.49는 반올림해 통과시키지 않음을 확인한다.
- 명세 해시 변경·증거 누락·산출물 변경은 재검증 대상임을 확인한다.
- 첫 회차 전체 실행, 이후 결함별 resume_stage, 유효한 단계 증거 재사용을 설명한다.
- 현재 도구 목록으로 독립 검수 가능 여부를 확인한다. 검증 목적으로 agent를 실제 생성하지 않는다.
  없으면 DEGRADED_REVIEW fallback과 그 제한을 보고한다.
- 외부 어댑터가 원본 실행 엔진 중첩·자동 인증·재전송을 유발하지 않는지 확인한다.

출력은 항목별 PASS/PARTIAL/FAIL과 근거 한 줄, 종합 판정이다.
독립 검수를 실제로 수행하지 않았으면 수행했다고 주장하지 않는다.
