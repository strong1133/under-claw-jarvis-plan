<!-- 🌐 Language: [한국어](README.md) · **English** -->

# Under Claw — three standalone AI workflow skills

This repository provides three independently invoked skills for Claude Code and Codex. One default install adds all three skills to both hosts; running it again safely updates them to the current repository version.

## Which skill should I use?

| Skill | Purpose | Claude / Codex |
|---|---|---|
| `under-claw-jarvis-plan` | Run complex work through understand → plan → implement → review | `/under-claw-jarvis-plan` / `$under-claw-jarvis-plan` |
| `under-claw-jarvis-plan-loop` | Repeat implementation and independent review until the target is met | `/under-claw-jarvis-plan-loop` / `$under-claw-jarvis-plan-loop` |
| `under-claw-meta-prompt` | Generate or refine a consistent executable prompt | `/under-claw-meta-prompt` / `$under-claw-meta-prompt` |

The three skills are independent and activate only when directly invoked by name or command. They do not affect normal queries or implicitly call one another.

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

Separates implementer and reviewer, then repeats until the review target is reached.

- Default target: `9.5/10`
- Default maximum: `5` rounds
- Improvement below `0.2` is treated as a plateau
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
