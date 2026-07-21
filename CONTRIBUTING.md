# Contributing to under-claw-jarvis-plan

Thanks for your interest! This repo is the single source of truth (SSOT) for the
`under-claw-jarvis-plan` orchestrator skill. It ships **only the skill** — no project,
company, or session-specific data.

## Ground rules
- **No secrets / no personal data.** Never commit absolute home paths, emails, internal
  entity names, credentials, or company identifiers. CI enforces this (see below).
- **Attribution stays.** The reference modules adapt three MIT skills. Keep
  [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) and the README attribution accurate.
- **Environment-agnostic.** The skill takes work paths via the prompt and lists skills by
  *type*, not by a specific environment's skill names (concrete names go in a user `skill-map`).

## Project layout
```
.claude-plugin/ .cursor-plugin/ .copilot-plugin/   # multi-harness plugin manifests
commands/under-claw-jarvis-plan.md                 # /under-claw-jarvis-plan entry point
skills/under-claw-jarvis-plan/references/          # 00 … 60 + 70-planning + 90-test (9 modules)
examples/skill-map.example.md                      # per-stage custom skill map template
tests/validate.sh  .github/workflows/ci.yml        # tests + CI
```

## Editing reference modules
- Each module is a focused methodology file (`NN-name.md`). Keep them short and prompt-ready.
- A constituent (self-authored) module must be logged with its `<tag>` and listed in the
  command's constituent-skill table, `90-test.md`, and (if new) `THIRD_PARTY_NOTICES.md`.
- Numbering: `00` guardrails, `10`–`40` stages, `50`/`60`/`70` cross-cutting, `90` self-test.

## Before opening a PR
```bash
bash tests/validate.sh        # structure / manifests / attribution / sensitive-data guard
bash tests/install.sh         # isolated install / backup / option behavior
bash -n install.sh            # shell syntax
shellcheck install.sh tests/*.sh
```
All checks must pass (CI runs the same on push/PR). Please:
1. Keep changes surgical and explain the *why* in the PR description.
2. Update both `README.md` (Korean, default) and `README.en.md` (English) when behavior/docs change.
3. Add or extend a contract test when behavior changes; use `tests/install.sh` for installer behavior.

## Commit messages
Conventional, imperative, scoped (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).

By contributing you agree your work is licensed under the repo's [MIT License](LICENSE).
