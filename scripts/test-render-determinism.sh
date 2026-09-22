#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
generated_dir="$repo_root/bluebuild/files/generated"

render_hash() {
  tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    -C "$generated_dir" -cf - . | sha256sum | cut -d ' ' -f 1
}

bash "$repo_root/scripts/prepare-components.sh"
first_hash="$(render_hash)"
bash "$repo_root/scripts/prepare-components.sh"
second_hash="$(render_hash)"

if [[ "$first_hash" != "$second_hash" ]]; then
  echo "Generated component tree is not deterministic: $first_hash != $second_hash" >&2
  exit 1
fi

echo "Generated component tree is deterministic: $first_hash"
