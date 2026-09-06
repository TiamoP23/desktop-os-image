#!/usr/bin/env bash
set -euo pipefail

extension_root="bluebuild/files/generated/usr/share/gnome-shell/extensions"

for metadata in "$extension_root"/*/metadata.json; do
  if ! grep -Eq '"50"|"50"[[:space:]]*,' "$metadata"; then
    printf '%s does not declare GNOME Shell 50 support\n' "$metadata" >&2
    exit 1
  fi
done

expected_count=5
actual_count="$(find "$extension_root" -mindepth 2 -maxdepth 2 -name metadata.json | wc -l)"
if [[ "$actual_count" -ne "$expected_count" ]]; then
  printf 'Expected %s rendered extensions, found %s\n' "$expected_count" "$actual_count" >&2
  exit 1
fi
