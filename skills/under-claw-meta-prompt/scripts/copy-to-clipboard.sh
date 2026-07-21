#!/usr/bin/env bash
set -euo pipefail

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard
else
  echo "지원하는 클립보드 명령(pbcopy, wl-copy, xclip)이 없습니다." >&2
  exit 1
fi
