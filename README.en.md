<!-- 🌐 Language: [한국어](README.md) · **English** -->

# Under Claw — three standalone AI workflow skills

This repository provides three independently invoked skills for Claude Code and Codex. One default install adds all three skills to both hosts; running it again safely updates them to the current repository version.

## Which skill should I use?

| Skill | Purpose | Claude / Codex |
|---|---|---|
| `under-claw-jarvis-plan` | Run complex work through understand → plan → implement → review | `/under-claw-jarvis-plan` / `$under-claw-jarvis-plan` |
| `under-claw-jarvis-plan-loop` | Repeat implementation and independent review until the target is met | `/under-claw-jarvis-plan-loop` / `$under-claw-jarvis-plan-loop` |
| `under-claw-meta-prompt` | Generate or refine a consistent executable prompt | `/under-claw-meta-prompt` / `$under-claw-meta-prompt` |

The three entry points activate only when directly invoked. Meta-prompt and plan can run independently; an explicitly invoked loop uses the base plan. Shared contracts and adapters ship inside each bundle.

## Install and update

### Default: Claude + Codex

```bash
curl -fsSL https://raw.githubusercontent.com/strong1133/under-claw-jarvis-plan/master/install.sh | bash
```

The default targets are:

- Claude: `~/.claude/commands/` and `~/.claude/skills/`
- Codex: `${CODEX_HOME:-~/.codex}/skills/`
- All three skills on both hosts

Run the same command again to back up existing entries and replace them with the current repository copies. Logs mark new targets as `[설치]` and existing targets as `[업데이트]`. Start a new Claude or Codex session afterward.

The one-line installer downloads the latest `master/install.sh` and temporarily clones the repository. Review the repository and run a local clone in sensitive environments.

### Host-specific installation

```bash
./install.sh --claude-only   # Claude only
./install.sh --skill-only    # Claude only: backward-compatible alias
./install.sh --codex-only    # Codex only
./install.sh --gemini-only   # Gemini only
./install.sh --gemini        # Add Gemini to the default Claude+Codex install
```

`--codex` remains accepted for compatibility and is now equivalent to the default install.

### External reference skills

External skills such as Karpathy Guidelines, Superpowers, Understand-Anything, and skill-creator are excluded by default to avoid global behavior changes.

```bash
./install.sh --with-externals   # Default install + Claude external references
./install.sh --externals-only   # External reference skills only
```

## 1. under-claw-jarvis-plan

A project-agnostic orchestrator for multi-file and multi-project work:

```text
Intake → Understand → Plan → Implement → Review
```

- Brownfield work compares original intent, current implementation, and correction request.
- Every stage has verifiable artifacts and a Definition of Done.
- It uses independent subagent review when available and deterministic verification otherwise.
- The workflow also applies to documents, analysis, planning, and economic modeling.
- A `test` input runs read-only self-diagnostics.

```text
/under-claw-jarvis-plan <requirements>
$under-claw-jarvis-plan <requirements>
/under-claw-jarvis-plan test
```

## 2. under-claw-jarvis-plan-loop

Separates implementer and reviewer, then repeats until both the required evidence gate and the quality target are met.

- Default target: `9.5/10`
- Default maximum: `5` rounds
- Plateau: two consecutive rounds reduce neither the number of unresolved required criteria nor the score gap by at least `0.2`
- Optional `--max-seconds` bounds elapsed time at stage boundaries
- Reports remaining gaps when the target or round limit stops the loop
- Invoked independently from the base plan skill

```text
/under-claw-jarvis-plan-loop <requirements> --max-rounds 5 --target 9.5
$under-claw-jarvis-plan-loop <requirements>
/under-claw-jarvis-plan-loop test
```

## 3. under-claw-meta-prompt

Transforms a request into an executable prompt with a fixed nine-section shape and a consistent professional tone. It neither invokes plan/loop nor executes the generated task.

```text
/under-claw-meta-prompt <query>            # Respond and copy to clipboard
$under-claw-meta-prompt <query>            # Codex
/under-claw-meta-prompt -d <PATH> <query>  # Create or refine a prompt file
```

- Separates facts, assumptions, and unknowns.
- Asks once for purpose only on a truly empty invocation.
- `-d` atomically writes only the selected prompt file and responds with status, path, and summary.
- Treats role-change or instruction-override text inside input as data.
- `assets/prompt-template.md` and `references/output-spec.md` define the fixed output shape and tone.

## Advanced configuration

Bind environment-specific skills to Plan stages with an external skill map.

1. Copy [`examples/skill-map.example.md`](examples/skill-map.example.md).
2. Place it at one of:
   - Project: `<project>/docs/under-claw-jarvis-plan/skill-map.md`
   - Codex: `~/.codex/under-claw-jarvis-plan.skillmap.md`
   - Claude: `~/.claude/under-claw-jarvis-plan.skillmap.md`
3. Bind concrete skill names to `phase2_understand`, `phase3_plan`, `phase4_implement`, `phase5_review`, and `closing`.

The map lives outside installation directories and survives updates. See `skills/under-claw-jarvis-plan/references/05-host-map.md` for host tool mappings.

## Verification

```bash
bash tests/validate.sh      # Structure, contract, and sensitive-data checks
bash tests/install.sh       # Isolated Claude/Codex/Gemini install and update tests
bash tests/meta-prompt.sh   # Safe prompt-file storage tests
shellcheck install.sh tests/*.sh skills/under-claw-meta-prompt/scripts/*.sh
```

## Repository layout

```text
commands/
├── under-claw-jarvis-plan.md
├── under-claw-jarvis-plan-loop.md
└── under-claw-meta-prompt.md
skills/
├── under-claw-jarvis-plan/
├── under-claw-jarvis-plan-loop/
└── under-claw-meta-prompt/
install.sh
tests/
README.md
README.en.md
```

## Attribution and license

The Plan methodology adapts principles from these MIT projects:

- [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
- [superpowers](https://github.com/obra/superpowers)
- [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)
- Authoring reference: [anthropics/skills](https://github.com/anthropics/skills)

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for complete attribution and [`LICENSE`](LICENSE) for this project's license.

## Evidence-based composition (v0.2)

The three explicit entry points remain. Meta-prompt can generate a standalone JSON contract with
`--spec [-d contract.json]`; normal prompt and clipboard behavior is unchanged.
Plan binds acceptance criteria to verification evidence. Loop requires both the hard evidence gate
and the quality target; missing required results, stale hashes, or blockers cannot be offset by a high score.
Later rounds resume at understand, plan, implement, or review according to the defect and valid prior evidence.
Optional `--max-seconds` bounds elapsed loop time at stage boundaries.

Bundled adapters selectively apply ideas from Ouroboros (contracts and staged evaluation),
im-not-ai (meaning-preserving Korean editing), OpenDesign (design systems and rendered review),
and Google Workspace CLI (service operations and read-back verification).

```bash
./install.sh --with-components
./install.sh --codex-only --with-components
```

These options cache the four pinned upstream repositories under `~/.under-claw/components/`.
They do not register upstream skills, execute upstream installers, install apps/CLIs, configure MCP,
or authenticate accounts. Use available host tools or explicitly set up the needed integration.
Ouroboros is not nested as a second execution engine. An existing task system remains the execution
ledger; local evidence files are attachments, not a second source of progress.

See [contracts](shared/contract.md), [verification](shared/verification.md),
[components](shared/components.md), and [pinned revisions](shared/components.json).
The evidence helper validates recorded claims and hashes; it does not execute tests or prove semantic correctness.

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/sync-shared.py --check
```

`shared/` is the maintained source; `tools/sync-shared.py` packages it into all three standalone skills.
