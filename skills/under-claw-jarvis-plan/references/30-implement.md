# 30 · Phase 4 — 구현 (Implement)

> 출처: Superpowers subagent-driven-development 발췌·적응 (obra/superpowers, MIT).
> 핵심 공식: **task별 fresh 작업자 + 2단계 리뷰(스펙 → 품질) = 빠르고 높은 품질**.

## 환경에 따른 작업자 배분 (Claude+Codex 호환의 핵심)

### 단독 Claude (under-claw-jarvis-plan 환경)
- task마다 **fresh 서브에이전트**(`Agent`)를 띄워 구현. 컨텍스트는 task별로 격리.
- 병렬 변경이 충돌하면 worktree 격리(`isolation: 'worktree'`) 또는 `Workflow`로 파이프라인.

### Claude + Codex 멀티에이전트 (tmux 2-pane) — 동등(→ `references/50-peer-collab.md`)
- 같은 방법론을 동료 pane과 공유한다(이 파일은 Claude·Codex 모두 읽고 따른다).
- **동등 원칙**: 둘 다 설계·구현·리뷰에 참여. "설계=Claude / 구현=Codex" 식 기능 위계 금지.
  **분담은 업무 영역(프로젝트/모듈/파일)** 기준으로 상호 합의(각자 자기 영역의 설계+구현+자체리뷰 책임).
- **교차 리뷰**: 한쪽 산출물은 **상대가** 스펙→품질 2단계 리뷰(이질적 관점 = 강한 검증).
  Codex 구현은 Claude가, **Claude 구현은 Codex가** 리뷰한다.
- 통신: `claude-team-send <세션:pane> "메시지"` (자동 Enter). 태그 규약은 SKILL의 환경 절 참조.
- **동일 파일 동시 수정 금지** — 변경 직전 `[DIFF]` 로 파일·의도 공유 → 상대 `[ACK]` 후 진행.

## task별 워크플로
1. 작업자에게 **task 전문 + 맥락**을 전달(스펙 완비 시 더 빠른 모델 사용 가능).
2. 작업자가 구현 → 자체 테스트 → self-review.
3. **스펙 준수 리뷰**(리뷰어): 요구를 다 만족하는가 — 빠진 것/넘친 것 없는가(Karpathy 2·3).
   - 통과 못 하면 작업자가 고치고 재리뷰.
4. **품질 리뷰**(리뷰어): 설계·패턴·유지보수성. **스펙 통과 전엔 품질 리뷰 시작 금지.**
   - 문제 있으면 고치고 재리뷰. "이 정도면 됨" 금지.
5. task 완료 표시.

## 작업자 상태 신호 처리
- `DONE` → 스펙 리뷰로.
- `DONE_WITH_CONCERNS` → 우려 읽고 정확성/범위 문제는 리뷰 전 해결.
- `NEEDS_CONTEXT` → 빠진 정보 보강 후 재투입.
- `BLOCKED` → 무언가 바꾼다(컨텍스트/모델/범위) 또는 에스컬레이션.

## 절대 금지(레드 플래그)
- 리뷰 건너뛰기 / 미해결 문제로 진행 / 보호 브랜치에 합의 없이 시작 /
  구현 작업자 여러 명 동시 투입(단독 Claude 시) / 스펙 통과 전 품질 리뷰.
