#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
state_dir="$repo_root/.work/edit-sessions"
if [[ -d "$state_dir" ]] && compgen -G "$state_dir/*.env" > /dev/null; then
  echo "pre-commit: active component edit sessions exist; finish or abort them before committing." >&2
  find "$state_dir" -maxdepth 1 -type f -name '*.env' -printf '  %f\n' >&2
  exit 1
fi
