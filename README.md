<!-- 🌐 Language: **English** · [한국어](README.ko.md) -->

# under-claw-jarvis-plan — project-agnostic multi-agent orchestrator

A **higher-order** Claude Code skill that sits *one level above* a single project and drives a
request all the way through **understand → analyze → design → plan → implement → review** using
**multi-agent council**. It does not reimplement other skills — at each stage it **actively calls
the skills already installed in your environment**.

> **SSOT**: this repo is the single source of truth for the skill. It ships **only the skill**
> (`commands` + `references`) — no project, company, or session-specific data. Work paths are
> supplied at runtime via the prompt, so the skill is environment-agnostic.

Composes three MIT methodologies (see [Attribution](#attribution)):
[Karpathy Guidelines](https://github.com/multica-ai/andrej-karpathy-skills) ·
[Superpowers](https://github.com/obra/superpowers) ·
[Understand-Anything](https://github.com/Egonex-AI/Understand-Anything).

---

## Install

### A. Plugin marketplace (easiest — recommended)
In any Claude Code session:
```
/plugin marketplace add strong1133/under-claw-jarvis-plan
/plugin install under-claw-jarvis-plan@under-claw-jarvis-plan
```
Update later with `/plugin marketplace update under-claw-jarvis-plan`, then reinstall.

### B. One-line remote install (script)
```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```
If run without the repo present, the script auto-clones to a temp dir and continues (bootstrap).

### C. Clone and install
```bash
git clone https://github.com/strong1133/under-claw-jarvis-plan && cd under-claw-jarvis-plan && ./install.sh
```

> **Other harnesses (Cursor / Copilot).** Plugin manifests ship under `.cursor-plugin/` and
> `.copilot-plugin/` (mirroring `.claude-plugin/`) so the bundle is discoverable on Cursor and
> GitHub Copilot via their plugin install flows. The methodology is harness-neutral.

| Flag | Effect |
|------|--------|
| (none) | Install the skill (commands + references) into `~/.claude`. **No network needed** |
| `--with-externals` | Also clone the upstream skills (Karpathy / Superpowers / Skill-Creator / Understand-Anything) |
| `--externals-only` | Upstream skills only |
| `--help` | Usage |

Existing files are backed up to `~/.under-claw-jarvis-plan-backup-<timestamp>/` before replacement (idempotent & safe).

## Usage
After install, in any Claude Code session:
```
/under-claw-jarvis-plan        # pass work-project path(s) + requirements in the prompt
/under-claw-jarvis-plan test   # self-diagnostic across stages / skills / models
```
- **Solo Claude**: the council is built from `Agent` / `Workflow` subagents in the current session — no extra tooling.
- **Claude + second-model peer** (e.g. a 2-pane Claude+Codex): the same patterns extend to cross-model peer collaboration (heterogeneous models catch more).

> Output language follows your environment. The bundled methodology prompts are authored in Korean;
> a full English README lives here and the [Korean docs](README.ko.md) carry the detailed walk-through.

## How it works — stages × skills
```
/under-claw-jarvis-plan
   0 Intake → 2 Understand → 3 Plan → 4 Implement → 5 Review
   (00 / 50 / 60 / 70 apply across all stages; simple queries skip the council)
```
| Stage | What it does | Core module |
|-------|--------------|-------------|
| **0 Intake** | Parse paths / requirements / output-doc / constraints; decide greenfield vs brownfield; ask only what's missing | command body |
| **2 Understand** | Align requirements (Socratic) + map code structure + (brownfield) **three-way diff**: original intent ↔ current impl ↔ correction request | `10-understand` |
| **3 Plan** | Compare 2–3 approaches → agree on design → write design doc → split into verifiable tasks | `20-plan` |
| **4 Implement** | Fresh worker per task + **two-stage review (spec → quality)** | `30-implement` |
| **5 Review & close** | Whole-change review + execution verification + closing doc | `40-review` |
| **Always-on** | Behavioral guardrails (`00-karpathy`), council collaboration (`50-peer-collab`), per-stage skill map (`60-skill-orchestration`), custom skill binding (`70-planning`) | — |

**Hard gate** for complex work: never skip the stage order *forward*, never proceed without applying
the stage's module (with a `<tag>` log line), and never start implementation (Phase 4) on a brownfield
task before the three-way diff is done. Stages may — and must — **loop backward** when a later stage
exposes an earlier gap (logged `<회귀 N→M>`), and each stage's todo closes only when its concrete
**Definition-of-Done artifact** exists (design doc saved, two-stage review passed, verification run).

## Per-stage skill customization (skill-map)
The core map (`60`) lists only **skill *types*** (e.g. "pattern-validation skill") so it stays
environment-agnostic. To bind your **concrete** skills per stage, declare a `skill-map` (see `70-planning`):
1. Copy `examples/skill-map.example.md` to one of:
   - project: `<project>/docs/under-claw-jarvis-plan/skill-map.md`
   - user-global: `~/.claude/under-claw-jarvis-plan.skillmap.md`
2. Fill the fixed stage keys (`phase2_understand` / `phase3_plan` / `phase4_implement` / `phase5_review` / `closing`).
3. The orchestrator loads it at start and calls those skills per stage (70 overrides the 60 type-map; missing → graceful fallback).

The map lives **outside** the install dir, so reinstalls/updates never wipe it.

## Verify / test
```bash
/under-claw-jarvis-plan test    # stage/skill/model matrix (read-only, no changes)
bash tests/validate.sh          # structure / manifest / sensitive-data checks (also run in CI)
```
`VERIFY-peer-collab.md` contains a reproducible 2-pane peer-collaboration scenario (6 acceptance signals).

## Repo layout
```
under-claw-jarvis-plan/
├── .claude-plugin/{plugin.json, marketplace.json}   # Claude Code plugin + marketplace
├── .cursor-plugin/ · .copilot-plugin/                # Cursor / Copilot plugin manifests
├── install.sh                                        # script install (with remote bootstrap)
├── README.md · README.ko.md                          # English / Korean
├── LICENSE · THIRD_PARTY_NOTICES.md                  # MIT + attribution
├── CONTRIBUTING.md · SECURITY.md · CODE_OF_CONDUCT.md # community docs
├── examples/skill-map.example.md                     # per-stage skill map template
├── tests/validate.sh · .github/workflows/ci.yml      # tests + CI
├── commands/under-claw-jarvis-plan.md                # /under-claw-jarvis-plan entry point
└── skills/under-claw-jarvis-plan/references/         # 00 … 60 + 70-planning + 90-test (9 modules)
```

## Attribution
The reference modules **adapt** (not verbatim-copy) three MIT-licensed skills; full notices in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md):

| Module | Source |
|--------|--------|
| `00-karpathy` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (MIT) |
| `10-understand` | own routing + [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) (MIT) |
| `20/30/40` | [obra/superpowers](https://github.com/obra/superpowers) brainstorming · subagent-driven-dev · code-review/verification (MIT) |
| `50 / 60 / 70 / 90` | original (this repo) |

## License
MIT — see [`LICENSE`](LICENSE).
