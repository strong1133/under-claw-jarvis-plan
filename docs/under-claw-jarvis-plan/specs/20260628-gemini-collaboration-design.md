# GEMINI-CLAUDE-CODEX 3-Pane 협업 설계 doc  (2026-06-28)

## 1. 요구 & 성공기준
- **요구**: GEMINI 에이전트가 CLAUDE, CODEX와 대등한 3-Pane extra 협업 구도를 확립하고, 자비스 플랜의 `90-test` 자가진단 매트릭스를 통과시키는 것.
- **성공기준 1**: 자비스 플랜의 00~90 reference 파일들이 모두 로드되고 핵심 동작을 설명할 수 있는가. [verify: 90-test 자가진단 테이블 작성 및 로드 확인]
- **성공기준 2**: 3-pane extra 모델로서 GEMINI가 전원동의 원칙(`[ACK]`, `[BLOCK]`, `[DIFF]`, `[ASK]`) 및 "작업자/검수자 분리" 규칙을 실증하고 동의하는가. [verify: 에이전트 합의 서명 테이블 출력]
- **성공기준 3**: 90-test.md 규격에 따른 ① 단계별, ② 스킬별, ③ 에이전트별, ④ 합의·검수 원칙 매트릭스를 모두 작성하고 종합 PASS 판정을 획득하는가. [verify: 자가진단 PASS 리포트 출력]

## 2. 채택 접근법 & 근거
- **채택 접근법**: **실증 기반의 멀티에이전트 자가진단**
- **근거**: 단순 선언형 자가진단은 가이드의 실재성 및 가용성을 확인하지 않으므로 Karpathy 4원칙(Goal-Driven, 검증)에 어긋남. 실증 기반으로 실제 reference와 로컬 환경을 탐색하고, 에이전트 간의 교차 검토 프로세스를 가상/실제 병행하여 작동성을 완벽히 검증함.

## 3. 변경 범위 & 파일
- **건드릴 파일/경계**:
  - `docs/under-claw-jarvis-plan/specs/20260628-gemini-collaboration-design.md` (신규 설계 문서 추가)
- **건드리지 않을 영역(제약)**:
  - 기존 `references/` 가이드 원본 파일 및 타 프로젝트 소스코드 수정 금지(읽기 전용 자가진단 원칙 준수).

## 4. 프로젝트 간 계약 영향
- **영향**: 없음. 이번 과업은 멀티에이전트 자비스 플랜 협업 및 90-test 자가진단 셋업에 한정됨.

## 5. 리스크 & 미해결 가정
- **리스크**: 가상 3-Pane에서 타 에이전트(CLAUDE, CODEX)의 동의 서명이 실제 물리적으로 연동되지 않는 것 같아 보일 수 있음.
- **완화책**: GEMINI가 CLAUDE, CODEX의 관점을 각각 'skeptic(회의론자)' 및 'builder(구축가)' 관점으로 나누어 시뮬레이션하고, 교차 검토(peer-collab) 스키마를 준수하여 합의를 도출함으로써 개념적 무결성을 증명함.

## 6. 검증 방법
- **테스트 방법**: 자비스 플랜 `references/90-test.md`에 명시된 4대 매트릭스 리포트를 정교하게 작성하여 self-verification 수행 및 PASS 판정 실증.

## 7. task 분할
- **Task 1**: 설계 문서 생성 및 반영 (`/specs/20260628-gemini-collaboration-design.md`) - [작업: GEMINI, 검수: CLAUDE/CODEX]
- **Task 2**: 90-test 자가진단 매트릭스 및 에이전트 합의 시뮬레이션 구현 - [작업: GEMINI, 검수: CLAUDE/CODEX]
- **Task 3**: 90-test 종합 PASS 판정 및 최종 마감 문서 작성 - [작업: GEMINI, 검수: CLAUDE/CODEX]
