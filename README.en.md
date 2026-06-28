<!-- 🌐 Language: [한국어](README.md) · **English** -->

# under-claw-jarvis-plan — a step-by-step reasoning skill for requirements

Give it *what to build*, and it reasons through **understand → plan → implement → review**,
**calling the right skills and methodologies at each stage**. It is a Claude Code skill that
**works in a single (solo) session** — no tmux, no 2-pane, no second model required.

> In one line: a **reasoning skill** that takes a requirement and walks the stages — thinking and
> executing — on its own. Multi-agent / cross-model is an *optional amplifier for deeper thinking*,
> never a requirement.

### External reference skills (credits)
This skill **adapts the methodologies of three open-source skills as external references** (it calls/applies
them — it does not reimplement). All MIT.
| External reference skill | Source (GitHub) | Module → stage |
|---|---|---|
| **Karpathy Guidelines** | https://github.com/multica-ai/andrej-karpathy-skills | `00-karpathy` → always-on guardrails |
| **Superpowers** | https://github.com/obra/superpowers | `20`/`30`/`40` → plan · implement · review |
| **Understand-Anything** | https://github.com/Egonex-AI/Understand-Anything | `10-understand` → understand (optional) |

Full license/attribution notices in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

---

## Install (one line — including dependency skills)
### Claude Code
One line in your terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```
Installs under-claw-jarvis-plan **plus its dependency (external reference) skills**
(Karpathy · Superpowers · Understand-Anything · skill-creator) into `~/.claude`. If the repo isn't present
it auto-clones (bootstrap); existing files are backed up (idempotent & safe). Then use `/under-claw-jarvis-plan`.

- ⚠️ **Understand-Anything** is a pnpm plugin, so the installer prints **one manual step** at the end (optional — under-claw-jarvis-plan works without it).
- Skill only (no deps): `… | bash -s -- --skill-only`
- Dev clone install: `git clone https://github.com/strong1133/under-claw-jarvis-plan && cd under-claw-jarvis-plan && ./install.sh`

### Codex
Install as a Codex user skill:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --codex-only
```
It installs into `${CODEX_HOME:-~/.codex}/skills/under-claw-jarvis-plan`. Restart Codex, then use `$under-claw-jarvis-plan`.

To install Claude and Codex support together, pass `--codex`:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --codex
```

### Gemini
Install as a Gemini user skill:
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash -s -- --gemini-only
```
It installs into `${GEMINI_HOME:-~/.gemini}/skills/under-claw-jarvis-plan` with `GEMINI.md` as the entry point. Pass `--gemini` to install alongside Claude.

### Other agents (universal)
The methodology (`references/`) is **agent-neutral**. The only host-dependent parts are the names of three tools —
task tracking, skill invocation, and multi-agent fan-out — and their mapping plus fallbacks are captured as data in
`references/05-host-map.md`. An agent without a dedicated entry point still runs via the generic-LLM fallback by loading
whichever of `SKILL.md` / `GEMINI.md` is available.

---

## Design philosophy (summary)
1. **Decompose the requirement into stages and reason.** No diving straight into code — break it into
   *understand → plan → implement → review*, where each stage's output feeds the next.
2. **Call, don't reimplement.** At each stage it invokes the `/skills` already in your environment and the
   methodologies of **three external reference skills**
   ([Karpathy](https://github.com/multica-ai/andrej-karpathy-skills) ·
   [Superpowers](https://github.com/obra/superpowers) ·
   [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)). The skill itself is the *conductor*.
3. **Solo session by default.** Thinking-heavy stages run on *current-session subagents* — independent
   drafts → cross-review → consensus. No extra setup. (A second-model peer extends it cross-model — optional.)
4. **Environment-agnostic.** Work paths arrive via the prompt; concrete per-stage skills are swapped through
   an external `skill-map`.
5. **Enforced, not skipped.** Stage order, Definition-of-Done artifacts, and backward regression are baked
   in as rules so "casual skipping" shows up.

> Simple queries (lookups, explanations, one-line fixes) skip the stages and answer directly — reasoning
> cost is spent only on complex work.

## Stages
```
/under-claw-jarvis-plan or $under-claw-jarvis-plan
   0 Intake → 2 Understand → 3 Plan → 4 Implement → 5 Review
   (00 / 50 / 60 / 70 apply across all stages; simple queries skip the council)
```
| Stage | What it does | Methodology module (← external reference skill) | Skills used per stage |
|-------|--------------|--------------------------------------------------|------------------------|
| **0 Intake** | Parse paths / requirements / output-doc / constraints; decide greenfield vs brownfield; ask only what's missing | command body | — |
| **2 Understand** | Align requirements (Socratic) + map code structure + (brownfield) **three-way diff** (intent ↔ current ↔ correction) | `10-understand` ← **[Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)** | requirement-clarify / contract-validate / pattern-validate skills · `deep-research` · (Understand-Anything) |
| **3 Plan** | Compare approaches → agree on design → **design doc (fixed schema)** → split into verifiable tasks | `20-plan` ← **[Superpowers](https://github.com/obra/superpowers)** | `deep-research` |
| **4 Implement** | Fresh worker per task + **two-stage review (spec → quality)** | `30-implement` ← **[Superpowers](https://github.com/obra/superpowers)** | style-rule / design-publish / API-sync skills |
| **5 Review & close** | Whole-change review + execution verification + closing doc | `40-review` ← **[Superpowers](https://github.com/obra/superpowers)** | review: pattern/contract/style validators · `code-review` · `security-review` · `simplify` · `verify` / close: ADR docs · API-sync · todo-register |
| **Always-on** | Behavioral guardrails (00) · council collaboration (50) · skill type-map (60) · concrete skill binding (70) | `00-karpathy` ← **[Karpathy](https://github.com/multica-ai/andrej-karpathy-skills)** · `50`·`60`·`70` (original) | ※ Karpathy's 4 principles (no-assumptions · simplicity · surgical · verify) apply as guardrails **across all stages** |

> Stages never skip **forward**, but **must loop backward** (`<회귀 N→M>`) when a later stage exposes an
> earlier gap. A stage's todo closes only when its **Definition-of-Done artifact** exists (design doc saved,
> two-stage review passed, verification run).

## Usage
```
/under-claw-jarvis-plan        # Claude: pass work path(s) + requirements in the prompt
$under-claw-jarvis-plan        # Codex: pass work path(s) + requirements in the prompt
/under-claw-jarvis-plan test   # Claude self-diagnostic (read-only)
$under-claw-jarvis-plan test   # Codex self-diagnostic (read-only)
```
- **Solo Claude (default)**: council = current-session `Agent` / `Workflow` subagents. No extra tooling.
- **Second-model peer (optional)**: with another model present (e.g. 2-pane Claude+Codex), it extends to cross-model peer collaboration.

## Loop variant — `under-claw-jarvis-plan-loop` (self-converging)
Runs the base skill as **one iteration**, and after each round a **separate, independent reviewer session**
scores compliance with the original requirements and the project's source patterns on a **10-point scale**.
The loop **terminates only when the score exceeds 9.5** (otherwise the gap list feeds the next round — Reflexion).
```
/under-claw-jarvis-plan-loop {requirements}        # self-converge to the 9.5 gate (--max-rounds N, --target X.X)
$under-claw-jarvis-plan-loop {requirements}        # Codex
/under-claw-jarvis-plan-loop test                  # self-diagnostic (read-only, no loop run)
```
- **3 roles = 3 separate sessions** (reviewer-separation principle):
  ① Loop orchestrator (main) — drives rounds, hands deliverables to review, decides termination;
  ② Reviewer (**a session distinct from implementer and orchestrator**) — adversarial 10-point scoring;
  ③ Implementer (**fresh session per round**) — completes the base under-claw-jarvis-plan, then reports back.
- **Rubric**: D1 requirement fidelity 4.0 / D2 correctness 3.0 / D3 convention-pattern (source-pattern, generalized) 2.0 / D4 quality-simplicity 1.0.
- **Safety**: MAX_ROUNDS cap (default 5) + plateau detection (gain < 0.2) → no infinite loops; escalate on non-convergence.
- **Domain-agnostic**: applies to file creation, analysis, planning, economic modeling — not just code. Personas and
  system prompts live in `skills/under-claw-jarvis-plan-loop/references/`.

## Per-stage skill customization (skill-map)
The core map (`60`) lists only **skill *types*** so it stays environment-agnostic. To bind your **concrete**
skills per stage, declare a `skill-map` (see `70-planning`):
1. Copy `examples/skill-map.example.md` to one of:
   - project: `<project>/docs/under-claw-jarvis-plan/skill-map.md`
   - Codex user-global: `~/.codex/under-claw-jarvis-plan.skillmap.md`
   - Claude user-global: `~/.claude/under-claw-jarvis-plan.skillmap.md`
2. Fill the fixed stage keys (`phase2_understand` / `phase3_plan` / `phase4_implement` / `phase5_review` / `closing`).
3. The orchestrator loads it at start and calls those skills per stage (70 overrides 60; missing → graceful fallback).

The map lives **outside** the install dir, so reinstalls/updates never wipe it.

## Verify / test
```bash
/under-claw-jarvis-plan test    # stage/skill/model matrix (read-only, no changes)
bash tests/validate.sh          # structure / manifest / sensitive-data checks (also run in CI)
```
`VERIFY-peer-collab.md` contains an optional reproducible 2-pane peer-collaboration scenario (6 acceptance signals).

## External reference skills & attribution (credits)
The methodology modules **adapt** (not verbatim-copy) the MIT **external reference skills** below; full
notices in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md):

| Module | Stage | External reference skill (source GitHub) | License |
|--------|-------|------------------------------------------|---------|
| `00-karpathy` | always-on guardrails | **Karpathy Guidelines** — [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | MIT |
| `10-understand` | understand | own routing + **Understand-Anything** — [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) | MIT |
| `20-plan`·`30-implement`·`40-review` | plan·implement·review | **Superpowers** — [obra/superpowers](https://github.com/obra/superpowers) (brainstorming · subagent-driven-development · code-review/verification) | MIT |
| `50`·`60`·`70`·`90` | collaboration·binding·self-test | original (this repo) | MIT |
| (authoring tool) | — | [anthropics/skills](https://github.com/anthropics/skills) — skill-creator | repo's own |

## Repo layout
```
under-claw-jarvis-plan/
├── .claude-plugin/{plugin.json, marketplace.json}   # Claude Code plugin + marketplace
├── .cursor-plugin/ · .copilot-plugin/               # Cursor / Copilot manifests
├── install.sh                                       # script install (remote bootstrap)
├── README.md · README.en.md                         # Korean (default) / English
├── LICENSE · THIRD_PARTY_NOTICES.md                 # MIT + attribution
├── CONTRIBUTING.md · SECURITY.md · CODE_OF_CONDUCT.md
├── examples/skill-map.example.md                    # per-stage skill map template
├── tests/validate.sh · .github/workflows/ci.yml     # tests + CI
├── commands/
│   ├── under-claw-jarvis-plan.md                    # /under-claw-jarvis-plan entry point
│   └── under-claw-jarvis-plan-loop.md               # /under-claw-jarvis-plan-loop entry point (loop)
└── skills/
    ├── under-claw-jarvis-plan/
    │   ├── SKILL.md · GEMINI.md                     # Codex / Gemini entry points
    │   ├── agents/openai.yaml                       # Codex UI metadata
    │   └── references/                              # 00 + 05-host-map + 10 … 70 + 90 (methodology + host adapter)
    └── under-claw-jarvis-plan-loop/                 # loop variant (base = under-claw-jarvis-plan)
        ├── SKILL.md · GEMINI.md                     # Codex / Gemini entry points
        ├── agents/openai.yaml
        └── references/                              # 00-loop-control + 10-orchestrator + 20-implementer + 30-reviewer + 40-scoring + 90-test
```

## Memory / optional deps
- Memory: **lightweight file-based** (design docs at `docs/under-claw-jarvis-plan/specs/`). No heavy infra.
- Understand-Anything: if installed, strengthens structure mapping via `/understand`·`/understand-diff`; otherwise council fan-out.

## License
MIT — see [`LICENSE`](LICENSE).
