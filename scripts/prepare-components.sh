#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/component-common.sh"

reset_generated_tree() {
  ensure_generated_tree
  rm -rf "$render_work_dir"
  mkdir -p "$render_work_dir"
  find "$generated_dir" -mindepth 1 ! -name '.gitignore' -exec rm -rf {} +
}

render_all_components() {
  load_component_manifest
  reset_generated_tree
  for_each_component render_component_to_generated
  echo "Rendered component sources into $generated_dir/components"
}

if [[ $# -eq 1 ]]; then
  require_component "$1"
  render_component_to_generated
  echo "Rendered $component_id"
elif [[ $# -eq 0 ]]; then
  render_all_components
else
  echo "Usage: prepare-components.sh [component-id]" >&2
  exit 1
fi
