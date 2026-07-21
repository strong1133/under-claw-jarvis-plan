#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "사용법: save-prompt.sh <PATH>" >&2
  exit 2
}

[[ "$#" == 1 && -n "$1" ]] || usage
input_path="$1"

if [[ -L "$input_path" ]]; then
  echo "심볼릭 링크는 수정하지 않습니다: $input_path" >&2
  exit 4
fi

if [[ -f "$input_path" ]]; then
  target="$input_path"
elif [[ -e "$input_path" && ! -d "$input_path" ]]; then
  echo "일반 파일 또는 디렉터리가 아닌 대상입니다: $input_path" >&2
  exit 4
elif [[ -d "$input_path" ]]; then
  if [[ -L "$input_path/PROMPT.md" ]]; then
    echo "심볼릭 링크는 수정하지 않습니다: $input_path/PROMPT.md" >&2
    exit 4
  elif [[ -f "$input_path/PROMPT.md" ]]; then
    target="$input_path/PROMPT.md"
  else
    candidates=()
    while IFS= read -r candidate; do
      candidates+=("$candidate")
    done < <(find "$input_path" -maxdepth 1 -type f -iname '*prompt*.md' -print | sort)

    if ((${#candidates[@]} > 1)); then
      echo "프롬프트 후보가 여러 개입니다:" >&2
      printf '%s\n' "${candidates[@]}" >&2
      exit 3
    elif ((${#candidates[@]} == 1)); then
      target="${candidates[0]}"
    else
      target="$input_path/PROMPT.md"
    fi
  fi
elif [[ "$input_path" == *.md ]]; then
  target="$input_path"
else
  target="$input_path/PROMPT.md"
fi

parent="$(dirname "$target")"
mkdir -p "$parent"
[[ ! -L "$target" ]] || { echo "심볼릭 링크는 수정하지 않습니다: $target" >&2; exit 4; }
[[ ! -e "$target" || -f "$target" ]] || { echo "일반 파일이 아닌 대상입니다: $target" >&2; exit 4; }

status="created"
[[ -f "$target" ]] && status="updated"
stage="$(mktemp "$parent/.under-claw-meta-prompt.XXXXXX")"
cleanup() { [[ -n "${stage:-}" && -e "$stage" ]] && rm -f -- "$stage"; }
trap cleanup EXIT HUP INT TERM

dd of="$stage" 2>/dev/null
[[ -s "$stage" ]] || { echo "빈 프롬프트는 저장하지 않습니다." >&2; exit 2; }
mv -f -- "$stage" "$target"
stage=""
printf '%s\t%s\n' "$status" "$target"
