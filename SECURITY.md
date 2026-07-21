# Security Policy

## Supported versions
This is an actively developed skill bundle. Only the latest `master` is supported; fixes
land there and are released by tag.

| Version | Supported |
|---------|-----------|
| latest `master` | ✅ |
| older tags | ❌ |

## Reporting a vulnerability
Please **do not** open a public issue for security problems. Instead:

1. Open a private **GitHub Security Advisory** on this repository
   (`Security` tab → `Report a vulnerability`), or
2. Contact the maintainer privately via their GitHub profile
   ([@strong1133](https://github.com/strong1133)).

Include: affected file(s), reproduction steps, and impact. We aim to acknowledge within
a few days and to ship a fix or mitigation before any public disclosure.

## Scope & threat model
This repo ships **markdown skill instructions, JSON manifests, and shell install scripts** —
no runtime service. The realistic risks are:

- **Sensitive-data leakage** — the bundle must never contain credentials, personal paths,
  emails, or internal identifiers. `tests/validate.sh` includes a sensitive-data guard that
  CI runs on every push/PR; please keep it green and extend it for new patterns.
- **Install-script safety** — `install.sh` stages replacements and backs up existing files by host
  before replacing them. Review shell changes carefully; CI runs isolated install tests and `shellcheck`.
- **Supply chain** — external skills are fetched over HTTPS from their official repositories at
  commit SHAs pinned in `install.sh`. Review pin updates before trusting them in sensitive environments.
  The one-line installer and this repository's bootstrap still track `master` until immutable releases exist;
  review a local clone before installation when that mutable entry point is unacceptable.

## Not vulnerabilities
- The skill calling other installed skills by design.
- A user-provided `skill-map` referencing skills that do not exist (handled gracefully).
