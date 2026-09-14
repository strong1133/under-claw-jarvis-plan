# 30 · 검수담당 — 증거와 원요구 대조

가능한 경우 구현·오케스트레이터와 분리된 세션에서 검수한다(검수 분리 원칙).
수단이 없으면 베이스 solo fallback을 적용하고 `review_mode=degraded`,
`DEGRADED_REVIEW`를 공개한다. 역할만 바꾼 동일 세션을 독립 검수로 표현하지 않는다.

1. 원요구·고정 명세·실제 산출물과 실행 로그를 읽는다. 구현자의 자기점수는 보지 않는다.
2. `shared/verification.md`에 따라 criterion별 실제 증거를 대조한다.
   로그가 읽기 어렵다면 다시 읽고, 대상 revision이 다르거나 검사가 빠졌을 때 관련 검사를 재실행한다.
3. fail/unknown을 구분하고 누락된 근거는 만들어내지 않는다. 원문 의미·수치·범위 위반과
   중대 결함은 blockers에 기록한다.
4. `40-scoring.md`로 점수를 매긴다. 필수 기준 실패를 높은 품질 점수로 상쇄하지 않는다.
5. 각 실패의 원인을 understand/plan/implement/review로 분류하고 수정해야 할 근거를 붙인다.
6. 명세 해시, 산출물·증거 해시, 모든 기준 결과, blockers, review_mode, D1~D4 점수를
   보고 JSON으로 제출한다. 검증기에 통과했다고 의미 검수가 자동 증명된 것은 아니다.

최종 판정은 hard_pass와 TARGET을 함께 만족할 때 PASS다.
