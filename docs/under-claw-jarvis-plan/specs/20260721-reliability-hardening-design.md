# Reliability hardening design (2026-07-21)

## 1. 요구 & 성공기준

- Loop 종료 계약을 `TARGET=${사용자 값:-9.5}`와 `score >= TARGET`으로 통일한다.
  - verify: 제어 문서에 `score > TARGET`과 고정 `score >= 9.5` 판정이 없어야 한다.
- Solo와 multi-agent 모두 실제 참여자만 합의 게이트에 포함한다.
  - verify: 고정 3모델/고정 모델 행 계약이 없고 동적 참여자 규칙이 존재해야 한다.
- 기존 설치를 보존하고 검증된 외부 revision만 설치한다.
  - verify: 격리 설치·재설치 시 백업이 남고 잘못된 옵션은 무변경 실패해야 한다.
- 문서가 주장하는 CI를 실제로 제공한다.
  - verify: GitHub Actions에서 구조·설치 테스트와 ShellCheck를 실행해야 한다.

## 2. 채택 접근법 & 근거

- 계약을 호스트별로 새로 구현하지 않고 공통 reference의 canonical 표현을 각 진입점이 따르게 한다.
- 설치 대상은 같은 부모 디렉터리에 먼저 staging한 후 백업하고 교체한다. 직접 삭제 후 복사보다 실패 범위가 작다.
- 외부 저장소는 2026-07-21에 확인한 commit SHA로 고정한다. 최신 HEAD 자동 설치보다 재현 가능성을 우선한다.
- 기존 Bash 설치기를 유지해 사용법과 플랫폼 호환성을 보존한다. 별도 패키지 관리 도구 도입은 범위에서 제외한다.

## 3. 변경 범위 & 파일

- Loop 계약: `commands/`, `skills/under-claw-jarvis-plan-loop/`.
- 참여자 게이트: base 진입점과 `references/10`, `20`, `40`, `50`, `90`.
- 설치 안전성: `install.sh`, 신규 `tests/install.sh`.
- CI·문서: `.github/workflows/ci.yml`, README 한·영, CONTRIBUTING, SECURITY.
- 기존 기능명, 설치 목적지, 공개 옵션은 유지한다.

## 4. 프로젝트 간 계약 영향

- 없음. 단일 저장소 내부의 Claude/Codex/Gemini 진입점 계약만 함께 갱신한다.

## 5. 리스크 & 미해결 가정

- 디렉터리 교체는 POSIX 전체 트랜잭션이 아니므로 staging·백업·실패 복구로 위험을 줄인다.
- 프로젝트 자체의 one-line `master` bootstrap은 release SHA가 생기기 전까지 완전히 고정할 수 없다. 외부 의존성은 이번 변경에서 고정한다.
- 실제 호스트별 멀티에이전트 E2E는 CI에서 실행하기 어렵다. 정적 의미 계약과 설치 동작을 자동 검증한다.

## 6. 검증 방법

- `bash -n install.sh tests/validate.sh tests/install.sh`
- `bash tests/validate.sh`
- `bash tests/install.sh`
- `shellcheck install.sh tests/*.sh` (가용 환경 및 CI)
- `git diff --check`

## 7. task 분할

1. Loop와 참여자 계약 수정 — verify: 의미 계약 검사.
2. 설치기 안전성 개선 — verify: 격리 설치·백업·옵션 실패 테스트.
3. CI와 사용자 문서 정렬 — verify: workflow 및 문서 검사.
4. 전체 독립 리뷰와 회귀 검증.
