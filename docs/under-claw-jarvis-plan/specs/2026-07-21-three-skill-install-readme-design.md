# 세 스킬 설치·README 재구성 설계 doc (2026-07-21)

## 1. 요구 & 성공기준

- 무옵션 설치로 Claude와 Codex에 세 스킬을 모두 설치한다. [verify: 격리 HOME 설치 테스트]
- 기존 대상은 현재 레포 사본으로 업데이트하고 백업한다. [verify: 양 호스트 sentinel 제거·백업 확인]
- 성공 뒤 세 이름과 짧은 설명 목록을 고정 순서로 출력한다. [verify: stdout 순서 검사]
- 한·영 README를 세 스킬 중심의 같은 정보구조로 재작성한다. [verify: 문서 계약 검사]

## 2. 채택 접근법 & 근거

기존 원자적 `install_tree`와 단일 `SKILLS` 목록을 유지하고 기본 `INSTALL_CODEX`만 활성화한다. `--skill-only`와 `--claude-only`는 하위호환을 위해 Claude 전용으로 유지한다. 별도 업데이트 명령은 멱등 설치와 중복되므로 추가하지 않는다.

## 3. 변경 범위 & 파일

- 변경: `install.sh`, `tests/install.sh`, `tests/validate.sh`, `README.md`, `README.en.md`
- 유지: 세 스킬의 실행 계약, 외부 스킬 opt-in, Gemini 선택 설치, 기존 백업·rollback 함수

## 4. 프로젝트 간 계약 영향

없음. 사용자 홈의 Claude/Codex 설치 경로와 CLI 옵션 의미만 변경된다.

## 5. 리스크 & 미해결 가정

- 기본 실행이 기존 Claude 전용에서 Claude+Codex로 확대된다. 사용자 요구에 따른 의도적 변경이다.
- `--codex`는 하위호환 no-op으로 유지한다.
- 세 이름은 완료 안내 상단에서 한 번씩, 설명 목록에서 다시 한 번씩 출력한다. 상세 설치 로그의 경로에는 이름이 추가로 나타날 수 있다.

## 6. 검증 방법

- Bash 문법, 구조 검증, 격리 설치·재설치, meta 파일 처리, `git diff --check`
- 기본·Claude-only·Codex-only·Gemini-only 대상과 완료 안내 검사

## 7. task 분할

1. 설치 기본값·업데이트 로그·완료 안내 수정
2. 설치 및 정적 계약 테스트 보강
3. 한·영 README 대칭 재구성
4. 전체 회귀 검증과 독립 리뷰
