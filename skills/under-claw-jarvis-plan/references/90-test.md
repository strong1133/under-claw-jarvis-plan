# 90 · 자가진단 모드 (`/under-claw-jarvis-plan test` 또는 `$under-claw-jarvis-plan test`)

입력이 `test`면 일반 플로우(Intake→검수) 대신 **이 자가진단**을 수행하고 종료한다.
**안전 원칙**: 읽기 전용. 프로젝트 파일을 변경하지 않는다. 외부 전송·배포 금지. 빠르게 끝낸다.

## 점검 목표
1. **단계별** — 각 Phase의 reference가 로드되고 핵심 동작을 설명 가능한가.
2. **스킬별** — **under-claw-jarvis-plan 구성 스킬만** 대상(아래 목록). 적용 가능한가 / `<이름 호출>` 로깅되는가.
3. **multi-agent** — 현재 세션에서 **서브에이전트 fan-out**(council)이 가능한가(기본). 제2모델 peer가
   환경에 있으면 그 왕복·동등 핸드셰이크도 점검(없으면 ⏭️). 3-pane extra면 Gemini까지 점검한다.
4. **합의·검수 원칙** — 전원 동의와 작업자/검수자 분리 원칙이 선언·준수되는가.

## 대상 = under-claw-jarvis-plan 구성 스킬뿐 (프로젝트 환경 스킬 제외)
| 구성 스킬(출처) | 모듈 | 태그 |
|---|---|---|
| Karpathy Guidelines | 00-karpathy | `<karpathy 호출>` |
| Understand-Anything | 10-understand | `<understand-anything 호출>` |
| Superpowers brainstorming/writing-plans | 20-plan | `<superpowers:plan 호출>` |
| Superpowers subagent-driven-development | 30-implement | `<superpowers:implement 호출>` |
| Superpowers code-review/verification | 40-review | `<superpowers:review 호출>` |
| (자체) peer-collab / skill-orchestration / skill-planning / test | 50 / 60 / 70 / 90 | `<peer-collab 적용>` 등 |

> 요구 이해·패턴 검증·코드 리뷰 등 **프로젝트 환경 스킬은 대상 아님**(구성 스킬이 아님).

## 수행 절차 (호출은 전부 `<이름 호출>` 로깅하며 진행)
1. **환경 감지**: 현재 세션 식별(어느 호스트인가 — Claude/Codex/Gemini/그 외). `05-host-map`을 기준으로
   작업추적(C1)·스킬호출(C2)·멀티에이전트(C3)가 **네이티브 도구냐 fallback이냐**를 판정한다(③ 매트릭스에 표기).
   제2모델 peer(예: 2-pane)가 있는지 확인(없으면 기본 모드).
   커스텀 **skill-map**(프로젝트 `docs/under-claw-jarvis-plan/skill-map.md` → Codex `~/.codex/under-claw-jarvis-plan.skillmap.md` → Claude `~/.claude/under-claw-jarvis-plan.skillmap.md`)
   탐지 — 있으면 적힌 스킬의 런타임 가용·단계 바인딩 점검(`70-planning`), 없으면 ⏭️(60 유형 맵 fallback).
2. **단계별 확인**: `00`~`70` reference 존재·로드 확인(Codex는 `~/.codex/skills/under-claw-jarvis-plan/references`, Claude는 `~/.claude/skills/under-claw-jarvis-plan/references` 등).
   각 Phase가 무엇을 하는지 1줄로 자가 확인.
3. **스킬별 확인** (대상 = 위 **구성 스킬만**, 프로젝트 환경 스킬 제외):
   - 적용 가능성: 각 구성 모듈(00/10/20/30/40/50/60/90)이 로드되어 적용 가능한가.
   - 로깅 실증: 각 구성 스킬을 `<{태그} 호출>` 형식으로 로깅하며 점검(이 자가진단 자체가 로깅 형식을 실증).
   - Understand-Anything은 외부 설치 의존 → 미설치면 ⏭️ + 사유(자체 이해 라우팅으로 대체).
4. **multi-agent 확인**: 서브에이전트 도구가 있으면 **서브에이전트를 1개 띄워** council 동작을 실증한다. 도구가 없으면 현재 세션에서 역할별 독립 패스로 대체 가능 여부를 확인한다. 제2/제3모델 peer가 있으면 그 왕복·동등 핸드셰이크도 확인, 없으면 ⏭️(peer 없음).
5. **합의·검수 원칙 확인**: "전원 동의 없이는 진행/완료 금지", "작업자와 검수자 분리"를 각 agent가 ACK하는지 확인.
   추가로 **단계별 합의 게이트(50)** 선언·로드를 점검한다 — 단계별 독립 산출 + `[DRAFT_READY]`/Read-Lock + 유효 ACK(`[INVALID_ACK]` 반려) + `ACTIVE_PARTICIPANTS` 동적 게이트 상태표(한 칸이라도 비면 진행 금지) + 데드락 처리가 reference에 명시되어 있는지(읽기전용 선언 확인).
6. **로깅 규약 확인**: 위 1~5의 모든 호출이 `<이름 호출>` 형식으로 남았는지 점검.
7. **보증 장치 확인**(설계 강제): command가 **단계 완료 검증(Definition of Done) 표**·**단계 회귀(`<회귀 N→M>`)**·
   **합성 산출 스키마(50)**·**설계 doc 스키마(20)**를 로드·설명 가능한지 점검. 실제 task가 없으므로
   *선언·로드*만 확인(읽기전용). 누락 시 ❌ — 강제가 "선언"에 그치지 않고 산출물·회귀로 닫히는지가 핵심.

## 출력 형식 (반드시 아래 3개 매트릭스 + 종합)

### ① 단계별
| 단계 | 점검 항목 | 결과 |
|------|----------|:---:|
| 0 Intake | 파싱 규칙 로드 | ✅/❌ |
| 2 이해·분석 | 10-understand 로드 + 이해 스킬 가용 | … |
| 3 설계·계획 | 20-plan 로드 | … |
| 4 구현 | 30-implement 로드 | … |
| 5 검수·마감 | 40-review 로드 + 검증 스킬 가용 | … |
| 가드레일 | 00-karpathy / 50-peer-collab / 60-skill / 90-test 로드 | … |

### ② 스킬별 (구성 스킬만)
| 구성 스킬 | 모듈 | 적용가능 | 로깅(`<태그 호출>`) | 결과 |
|-----------|------|:---:|:---:|:---:|
| Karpathy | 00-karpathy | ✅/❌ | `<karpathy 호출>` | … |
| Understand-Anything | 10-understand | ✅/⏭️ | `<understand-anything 호출>` | … |
| Superpowers·plan | 20-plan | ✅/❌ | `<superpowers:plan 호출>` | … |
| Superpowers·implement | 30-implement | ✅/❌ | `<superpowers:implement 호출>` | … |
| Superpowers·review | 40-review | ✅/❌ | `<superpowers:review 호출>` | … |
| peer-collab | 50 | ✅/❌ | `<peer-collab 적용>` | … |
| skill-orchestration | 60 | ✅/❌ | `<skill-orchestration 적용>` | … |
| skill-planning | 70 | ✅/⏭️ | `<planning 적용>` | … |
| test | 90 | ✅/❌ | `<test 실행>` | … |

### ③ 에이전트별
| 에이전트 | 역할 | 응답 | 결과 |
|----------|------|:---:|:---:|
| ORCHESTRATOR (현재 세션) | council 진행 + 합성 | ✅ | … |
| SUBAGENT | 독립 분석/검증 | ✅(fan-out 동작) | … |
| 제2모델 peer (있을 때만) | 교차-모델 동등 협업 | [ACK]/⏭️없음 | … |
| 제3모델 peer / GEMINI (extra) | 교차-모델 동등 협업 | [ACK]/⏭️non-extra | … |

### ④ 합의·검수 원칙 (50 "단계별 합의 게이트" 기준)
| 원칙 | 기대 동작 | 결과 |
|------|----------|:---:|
| 전원 동의 | 이해·계획·구현·검수 단계별 모든 참여 agent ACK 필요 | ✅/❌ |
| BLOCK 처리 | 1명이라도 BLOCK이면 진행 중단 후 DIFF/ASK | ✅/❌ |
| 작업자/검수자 분리 | 작업 agent와 다른 agent가 검증·검수 | ✅/❌ |
| 단계별 독립 산출 | 단계 시작 시 `ACTIVE_PARTICIPANTS` 확정, 참여자별 독립 드래프트 후 `[DRAFT_READY]` | ✅/❌ |
| Read-Lock | 전원 `[DRAFT_READY]` 전 타인 드래프트 미열람(규율) | ✅/❌ |
| 유효 ACK | 단독 `[ACK]` 무효, 요약+근거+리스크+(사고단계)인용 미충족 시 `[INVALID_ACK]` | ✅/❌ |
| 게이트 상태표 | 행=`ACTIVE_PARTICIPANTS` / 열=독립산출·교차검토·유효ACK, 한 칸이라도 비면 진행 금지 | ✅/❌ |
| 데드락 | 3회 초과 핑퐁 → Karpathy 최소안+verify → 사용자 에스컬레이션 | ✅/❌ |
| extra 3-pane | Claude+Codex+Gemini 전원 유효 ACK | ✅/⏭️/❌ |

### 종합 판정
- 단계 N/N · 스킬 N/N · model N/N · 원칙 N/N → **PASS / PARTIAL / FAIL**
- 실패·⏭️ 항목은 사유 1줄. (예: "스타일 규칙 스킬 ⏭️ — MCP 미연결", "제2모델 peer ⏭️ — 없음")
