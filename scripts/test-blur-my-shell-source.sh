#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="${BLUR_MY_SHELL_SOURCE_DIR:-$script_dir/../bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx}"

# Exercise v76's geometry and reparenting behavior, not the removed local patches.
gjs -m "$script_dir/test-blur-my-shell-takeover.js" "$source_dir" \
  "$script_dir/../bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell"

if grep -Rq 'gi://Blur' "$source_dir"; then
  echo 'Blur My Shell must not depend on the obsolete rounded-blur library' >&2
  exit 1
fi
