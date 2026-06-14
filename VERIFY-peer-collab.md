# 2-pane 동등 협업 검증 시나리오 (Claude ↔ Codex)

`under-claw-jarvis-plan` 2-pane에서 두 모델이 **동등하게 사고·분석·설계**하는지(`references/50-peer-collab.md`)
확인하는 재현 가능한 테스트. 검증은 **과제 내용이 아니라 협업 메커니즘**을 본다.

## 사전 준비
1. 터미널에서 `under-claw-jarvis-plan` 실행 → CLAUDE(0.0) + CODEX(0.1) 2-pane 진입.
2. 부트스트랩 완료 확인: 두 pane이 서로 `[ACK] 준비 완료` 교환했는가.
3. **관찰용 별도 터미널** 1개 열어두기(아래 "관찰 명령" 사용).

## 동등성 6대 합격 신호 (Acceptance Criteria)
1. **독립 병행** — 두 pane이 각자 독립 초안을 만든다(한쪽이 가만히 대기 ❌).
2. **양방향 교환** — `claude-team-send` 메시지가 양쪽으로 오간다.
3. **양방향 교차 검토** — **Codex가 Claude 안을 `[REVIEW]`** 한다(← 위계 없음의 핵심 증거).
4. **근거 기반 합성** — 불일치를 근거로 판정, 못 좁히면 **양안 + 권장안** 제시.
5. **영역 분담** — 나눌 때 기능(설계/구현)이 아니라 **프로젝트/모듈** 기준.
6. **facilitator ≠ boss** — Claude가 루프를 진행하되 Codex 의견을 일방 override 하지 않는다.

## 실패 신호 (하나라도 보이면 FAIL)
- Codex가 분석 없이 "지시 대기"만 한다.
- Claude가 전부 분석한 뒤 Codex엔 "구현만" 시킨다(기능 위계).
- Codex가 Claude 안을 한 번도 검토하지 않는다.
- Claude가 Codex 의견을 근거 없이 무시/덮어쓴다.
- 한 pane의 산출물이 0이다.

---

## 시나리오 A — 스모크 (≈2분): 채널 + 동등 인지
CLAUDE pane에 입력:
```
[검증A] CODEX에게 인사하고, 우리 둘이 동등한 공동작업자(상하관계 아님)임을
서로 한 줄로 확인해라. 끝나면 나에게 "A 통과" 한 줄만 보고.
```
**합격**: 양방향 메시지 1왕복, 두 pane 모두 "동등" 확인, "A 통과" 보고. (신호 2,6)

## 시나리오 B — 핵심: 분석·설계 동등 (≈10분, 읽기 전용 / 코드 변경 없음)
dry-run에서 나온 **실제 갈림길**을 설계 과제로 쓴다(자연스럽게 안이 갈린다).
CLAUDE pane에 `/under-claw-jarvis-plan` 호출 후 아래를 입력:
```
### 작업 대상 프로젝트
- <프로젝트A>: </절대/경로/projA>   # 예시 — 자신의 프로젝트로 교체
- <프로젝트B>: </절대/경로/projB>

### 요구사항 (분석·설계만, 코드 변경 금지)
AI_ARCHIVE_REPORT 의 orphan 참조 문제 — storage 파일이 삭제되면 리포트의
storageFileSeqList 가 잔존 참조가 된다. 이걸 어떻게 처리할지 설계안을 내라.
(후보: 삭제 이벤트 리스너에서 정리 / 조회 시 lazy validate / 배치 cleanup 등)
결론은 설계안 + 근거 + 트레이드오프까지. 구현하지 말 것.
```
**기대 동작**(50-peer-collab):
1. Claude·Codex가 **각자 독립적으로** 설계 초안을 만든다(서로 안 보고).
2. `claude-team-send`로 교환.
3. 서로 `[REVIEW]` — 특히 **Codex가 Claude 안의 허점**(예: 이벤트 유실 시 정합성, 동시성)을 지적.
4. 합의안 합성, 안 좁혀지면 **양안 + 권장안**을 사용자에게 제시.

**합격**: 6대 신호 중 1·2·3·4 모두 관측. 두 pane에 **서로 다른 독립 초안**이 보이고,
Codex가 Claude 안을 검토한 흔적이 있어야 한다. (신호 1,2,3,4)

## 시나리오 C — 선택: 구현 동등 (≈15분, 스크래치라 안전)
스크래치에서 작은 과제를 **영역 분담 + 교차 리뷰**로.
```
mkdir -p /tmp/jp-verify
```
CLAUDE pane에 `/under-claw-jarvis-plan` → 대상 `/tmp/jp-verify` → 입력:
```
간단한 CLI 유틸을 만든다. 모듈 2개로 영역 분담:
- 모듈 X: 입력 파서   - 모듈 Y: 출력 포매터
각자 자기 모듈을 설계+구현+자체리뷰하고, 그다음 서로의 모듈을 교차 리뷰한다.
(기능 위계로 나누지 말 것 — '설계는 너, 구현은 나' 금지. 영역으로 분담.)
```
**합격**: 분담이 **모듈(영역) 기준**이고, **Claude 코드를 Codex가 리뷰**(반대도)한 흔적. (신호 3,5)

## (선택) 대조군 — `--solo` 비교
같은 시나리오 B를 `under-claw-jarvis-plan --solo`(단독 Claude)로도 돌려, 2-pane이 **독립 2관점**을
실제로 더 내는지 대비한다. solo는 한 관점, 2-pane은 두 독립 관점이어야 정상.

---

## 채점표 (6/6 = 동등 협업 정상)
- [ ] 1 독립 병행 — 두 pane 독립 초안
- [ ] 2 양방향 교환 — 메시지 양쪽 오감
- [ ] 3 양방향 교차 검토 — **Codex→Claude 리뷰 존재**
- [ ] 4 근거 기반 합성 — 불일치 시 양안+권장안
- [ ] 5 영역 분담 — 기능 아님, 모듈/프로젝트 기준
- [ ] 6 facilitator≠boss — 일방 override 없음

## 관찰 명령 (별도 터미널)
```bash
tmux capture-pane -t under-claw-jarvis-plan:0.0 -p -S -300   # CLAUDE pane 최근 300줄
tmux capture-pane -t under-claw-jarvis-plan:0.1 -p -S -300   # CODEX pane 최근 300줄
tmux list-panes -t under-claw-jarvis-plan                     # pane 생존 확인
```
> 핵심 관전 포인트: **Codex가 Claude의 설계를 검토·반박**하는 장면. 이게 보이면 위계가 깨지고
> 동등 협업이 실제로 작동하는 것이다. 안 보이면(=Codex가 구현/대기만) 50-peer-collab 미발현 → 재튜닝.
