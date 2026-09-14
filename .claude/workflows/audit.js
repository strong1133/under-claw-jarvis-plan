export const meta = {
  name: 'audit',
  description: '{{점검 대상}} 을 축별로 병렬 점검하고 각 지적을 반증 검증한 뒤 정리',
  whenToUse: '{{구조를 크게 건드린 뒤, 또는 지침과 코드가 어긋나는지 주기적으로 확인할 때}}. 인자로 범위를 주면 그 범위만 본다.',
  phases: [
    { title: 'Audit', detail: '축별 병렬 점검' },
    { title: 'Verify', detail: '지적마다 반증 시도' },
    { title: 'Report', detail: '살아남은 지적만 정리' },
  ],
}

// 파일은 반드시 `export const meta` 로 시작해야 하고, meta 는 순수 리터럴이어야 한다.
// Date.now() / Math.random() 은 사용할 수 없다. 스크립트는 TypeScript 가 아니라 순수 JS.

const scope = typeof args === 'string' && args.trim()
  ? `다음 범위만 본다: ${args.trim()}`
  : '변경 범위를 git diff $(git merge-base HEAD origin/{{BASE_BRANCH}})..HEAD 로 잡는다'

const FINDING = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          rule: { type: 'string' },
          summary: { type: 'string' },
          fix: { type: 'string' },
        },
        required: ['file', 'rule', 'summary', 'fix'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['refuted', 'reason'],
}

const AXES = [
  { key: '{{축1}}', prompt: '{{무엇을 찾을지 · 기준 문서 경로}}' },
  { key: '{{축2}}', prompt: '{{무엇을 찾을지 · 기준 문서 경로}}' },
  { key: '{{축3}}', prompt: '{{무엇을 찾을지 · 기준 문서 경로}}' },
]

const preamble = `너는 {{PROJECT_NAME}} 을 점검한다. ${scope}
파일을 실제로 읽고 확인한 것만 보고한다. 추측으로 지적을 만들지 않는다. 코드는 수정하지 않는다.`

phase('Audit')

/// pipeline 은 축마다 독립 진행 — 한 축의 점검이 끝나면 그 축의 검증이 바로 시작된다
const perAxis = await pipeline(
  AXES,
  (axis) => agent(`${preamble}\n\n${axis.prompt}`, {
    label: `audit:${axis.key}`, phase: 'Audit', schema: FINDING,
  }),
  (result, axis) => {
    const found = (result?.findings ?? []).slice(0, 3)   /// 축당 상위 3건만 검증 (에이전트 수 상한)
    if (!found.length) return []
    return parallel(found.map((f) => () =>
      agent(`다음 지적을 반증하라. 해당 파일을 직접 읽고, 지적이 규칙을 잘못 적용했거나 사실과 다르면 refuted=true 로 답하라. 확신이 없으면 refuted=true 로 기울여라.\n\n파일: ${f.file}\n규칙: ${f.rule}\n지적: ${f.summary}`, {
        label: `verify:${axis.key}`, phase: 'Verify', schema: VERDICT,
      }).then((v) => ({ ...f, axis: axis.key, verdict: v }))
    ))
  }
)

const all = perAxis.flat().filter(Boolean)
const survived = all.filter((f) => f.verdict && !f.verdict.refuted)
log(`검증 통과 ${survived.length}건 · 반증되어 제외 ${all.length - survived.length}건 (축당 상위 3건만 검증)`)

if (!survived.length) return { findings: [], note: '반증을 통과한 위반 없음' }

phase('Report')

const report = await agent(
  `아래는 반증 검증을 통과한 위반 목록이다. 축별로 묶어 정리하되, 같은 원인의 지적은 합치고, 각 항목에 파일:줄 · 위반 규칙 · 조치를 남겨라. 심각도 순으로 정렬한다. 코드는 수정하지 않는다.\n\n${JSON.stringify(survived, null, 2)}`,
  { label: 'report', phase: 'Report' }
)

return { count: survived.length, report }
