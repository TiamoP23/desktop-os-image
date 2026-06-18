#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/component-common.sh"

usage() {
  cat >&2 <<'USAGE'
Usage:
  component-edit.sh start <component-id> [branch-name]
  component-edit.sh finish <component-id>
  component-edit.sh abort <component-id>
  component-edit.sh refresh <component-id> [base-ref]
  component-edit.sh status [component-id]
  component-edit.sh list
USAGE
}

refresh_patches() {
  require_component "$1"
  ensure_vendor_repo
  local base_ref="${2:-}"
  if [[ -z "$base_ref" ]]; then
    load_edit_state "$1"
    base_ref="$EDIT_BASE_REF"
  fi
  require_clean_vendor_repo
  export_patch_series "$vendor_abs" "$patches_abs" "$base_ref"
}

start_edit() {
  require_component "$1"
  ensure_vendor_repo
  reset_vendor_repo_to_ref
  local branch_name="${2:-patch/$1-$(date +%Y%m%d%H%M%S)}"
  local base_ref="$(git -C "$vendor_abs" rev-parse HEAD)"
  git -C "$vendor_abs" switch -c "$branch_name" "$base_ref" >/dev/null
  apply_patches_to_repo "$vendor_abs" "$patches_abs"
  write_edit_state "$1" "$base_ref" "$branch_name"
  echo "Started edit session for $1 on $branch_name"
}

finish_edit() {
  require_component "$1"
  ensure_vendor_repo
  load_edit_state "$1"
  require_clean_vendor_repo
  git -C "$vendor_abs" switch "$EDIT_BRANCH_NAME" >/dev/null
  export_patch_series "$vendor_abs" "$patches_abs" "$EDIT_BASE_REF"
  git -C "$vendor_abs" switch --detach "$EDIT_BASE_REF" >/dev/null
  git -C "$vendor_abs" branch -D "$EDIT_BRANCH_NAME" >/dev/null
  clear_edit_state
  bash "$script_dir/prepare-components.sh" "$1"
}

abort_edit() {
  require_component "$1"
  ensure_vendor_repo
  load_edit_state "$1"
  git -C "$vendor_abs" switch --detach "$EDIT_BASE_REF" >/dev/null
  git -C "$vendor_abs" branch -D "$EDIT_BRANCH_NAME" >/dev/null 2>/dev/null || true
  clear_edit_state
}

show_status() {
  if [[ $# -eq 1 ]]; then
    require_component "$1"
    ensure_vendor_repo
    echo "Component: $component_id"
    echo "Repo: $component_repo"
    echo "Pinned ref: $component_ref"
    echo "Vendor path: $component_vendor_path"
    echo "Patches path: $component_patches_path"
    echo "Install dir: $component_install_dir"
    echo "Vendor HEAD: $(git -C "$vendor_abs" rev-parse HEAD 2>/dev/null || echo missing)"
    echo "Current branch: $(git -C "$vendor_abs" branch --show-current 2>/dev/null || echo detached)"
    return 0
  fi
  load_component_manifest
  printf 'COMPONENT\tVENDOR_PATH\n'
  for component in "${component_ids[@]}"; do
    printf '%s\t%s\n' "$component" "${component_vendor_path_by_id[$component]}"
  done
}

case "${1:-}" in
  start) shift; start_edit "$@" ;;
  finish) shift; finish_edit "$@" ;;
  abort) shift; abort_edit "$@" ;;
  refresh) shift; refresh_patches "$@" ;;
  status) shift; show_status "$@" ;;
  list) load_component_manifest; printf '%s\n' "${component_ids[@]}" ;;
  *) usage; exit 1 ;;
esac
