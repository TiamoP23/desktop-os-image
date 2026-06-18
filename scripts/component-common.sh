#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
manifest_path="$repo_root/manifests/components.yml"
edit_state_dir="$repo_root/.work/edit-sessions"
generated_dir="$repo_root/bluebuild/files/generated"
render_work_dir="$repo_root/.work/render"
component_manifest_loaded=0

component_id=""
component_type=""
component_repo=""
component_ref=""
component_vendor_path=""
component_patches_path=""
component_install_dir=""
vendor_abs=""
patches_abs=""
state_file=""
COMPONENT_ID=""
EDIT_BASE_REF=""
EDIT_BRANCH_NAME=""

declare -ag component_ids=()
declare -Ag component_type_by_id=()
declare -Ag component_repo_by_id=()
declare -Ag component_ref_by_id=()
declare -Ag component_vendor_path_by_id=()
declare -Ag component_patches_path_by_id=()
declare -Ag component_install_dir_by_id=()
declare -Ag component_id_by_vendor_path=()

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

fail() {
  echo "$*" >&2
  return 1
}

derive_component_vendor_path() {
  local current_component_id="$1"
  printf 'vendor/extensions/%s' "$current_component_id"
}

derive_component_patches_path() {
  local current_component_id="$1"
  printf 'patches/extensions/%s' "$current_component_id"
}

register_component() {
  local current_component_id="$1"
  local current_component_type="$2"
  local current_component_repo="$3"
  local current_component_ref="$4"
  local current_component_vendor_path="$5"
  local current_component_patches_path="$6"
  local current_component_install_dir="$7"

  [[ -n "$current_component_id" ]] || return 0

  if [[ -z "$current_component_type" || -z "$current_component_repo" || -z "$current_component_ref" || -z "$current_component_install_dir" ]]; then
    fail "Component definition is incomplete in $manifest_path: $current_component_id"
    return 1
  fi

  if [[ -z "$current_component_vendor_path" ]]; then
    current_component_vendor_path="$(derive_component_vendor_path "$current_component_id")"
  fi
  if [[ -z "$current_component_patches_path" ]]; then
    current_component_patches_path="$(derive_component_patches_path "$current_component_id")"
  fi

  component_ids+=("$current_component_id")
  component_type_by_id["$current_component_id"]="$current_component_type"
  component_repo_by_id["$current_component_id"]="$current_component_repo"
  component_ref_by_id["$current_component_id"]="$current_component_ref"
  component_vendor_path_by_id["$current_component_id"]="$current_component_vendor_path"
  component_patches_path_by_id["$current_component_id"]="$current_component_patches_path"
  component_install_dir_by_id["$current_component_id"]="$current_component_install_dir"
  component_id_by_vendor_path["$current_component_vendor_path"]="$current_component_id"
}

load_component_manifest() {
  local line=""
  local current_id=""
  local current_type=""
  local current_repo=""
  local current_ref=""
  local current_vendor_path=""
  local current_patches_path=""
  local current_install_dir=""

  if [[ "$component_manifest_loaded" -eq 1 ]]; then
    return 0
  fi
  if [[ ! -f "$manifest_path" ]]; then
    fail "Component manifest not found: $manifest_path"
    return 1
  fi

  component_ids=()
  component_type_by_id=()
  component_repo_by_id=()
  component_ref_by_id=()
  component_vendor_path_by_id=()
  component_patches_path_by_id=()
  component_install_dir_by_id=()
  component_id_by_vendor_path=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]id:[[:space:]]*(.+)$ ]]; then
      register_component "$current_id" "$current_type" "$current_repo" "$current_ref" "$current_vendor_path" "$current_patches_path" "$current_install_dir" || return 1
      current_id="$(trim "${BASH_REMATCH[1]}")"
      current_type=""
      current_repo=""
      current_ref=""
      current_vendor_path=""
      current_patches_path=""
      current_install_dir=""
    elif [[ "$line" =~ ^[[:space:]]*type:[[:space:]]*(.+)$ ]]; then
      current_type="$(trim "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ ^[[:space:]]*repo:[[:space:]]*(.+)$ ]]; then
      current_repo="$(trim "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ ^[[:space:]]*ref:[[:space:]]*(.+)$ ]]; then
      current_ref="$(trim "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ ^[[:space:]]*vendor_path:[[:space:]]*(.+)$ ]]; then
      current_vendor_path="$(trim "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ ^[[:space:]]*patches_path:[[:space:]]*(.+)$ ]]; then
      current_patches_path="$(trim "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ ^[[:space:]]*install_dir:[[:space:]]*(.+)$ ]]; then
      current_install_dir="$(trim "${BASH_REMATCH[1]}")"
    fi
  done < "$manifest_path"

  register_component "$current_id" "$current_type" "$current_repo" "$current_ref" "$current_vendor_path" "$current_patches_path" "$current_install_dir" || return 1
  component_manifest_loaded=1
}

set_component_context() {
  local requested_component_id="$1"
  [[ -n "${component_vendor_path_by_id[$requested_component_id]:-}" ]] || return 1
  component_id="$requested_component_id"
  component_type="${component_type_by_id[$requested_component_id]}"
  component_repo="${component_repo_by_id[$requested_component_id]}"
  component_ref="${component_ref_by_id[$requested_component_id]}"
  component_vendor_path="${component_vendor_path_by_id[$requested_component_id]}"
  component_patches_path="${component_patches_path_by_id[$requested_component_id]}"
  component_install_dir="${component_install_dir_by_id[$requested_component_id]}"
  vendor_abs="$repo_root/$component_vendor_path"
  patches_abs="$repo_root/$component_patches_path"
  state_file="$edit_state_dir/$requested_component_id.env"
}

resolve_component() {
  load_component_manifest || return 1
  set_component_context "$1"
}

require_component() {
  if ! resolve_component "$1"; then
    fail "Component not found in manifest: $1"
    return 1
  fi
}

for_each_component() {
  local callback="$1"
  local current_component_id=""
  load_component_manifest || return 1
  for current_component_id in "${component_ids[@]}"; do
    set_component_context "$current_component_id" || return 1
    "$callback" "$current_component_id" || return 1
  done
}

ensure_vendor_repo() {
  mkdir -p "$(dirname "$vendor_abs")" "$patches_abs"
  if [[ ! -d "$vendor_abs/.git" ]]; then
    git clone "$component_repo" "$vendor_abs" >/dev/null
  else
    git -C "$vendor_abs" remote set-url origin "$component_repo"
  fi
  git -C "$vendor_abs" fetch --quiet --tags origin
}

resolve_component_ref() {
  if git -C "$vendor_abs" rev-parse --verify --quiet "$component_ref^{commit}" >/dev/null 2>&1; then
    git -C "$vendor_abs" rev-parse "$component_ref^{commit}"
    return 0
  fi
  if git -C "$vendor_abs" fetch --quiet origin "$component_ref" >/dev/null 2>&1; then
    git -C "$vendor_abs" rev-parse FETCH_HEAD^{commit}
    return 0
  fi
  fail "Unable to resolve component ref for $component_id: $component_ref"
}

reset_vendor_repo_to_ref() {
  local resolved_ref="$(resolve_component_ref)"
  git -C "$vendor_abs" reset --hard "$resolved_ref" >/dev/null
  git -C "$vendor_abs" clean -fdx >/dev/null
  git -C "$vendor_abs" switch --detach "$resolved_ref" >/dev/null
}

require_clean_vendor_repo() {
  if [[ -n "$(git -C "$vendor_abs" status --short)" ]]; then
    fail "Vendor repository has uncommitted changes: $component_vendor_path"
    return 1
  fi
}

write_edit_state() {
  local current_component_id="$1"
  local base_ref="$2"
  local branch_name="$3"
  mkdir -p "$edit_state_dir"
  printf 'COMPONENT_ID=%q\nEDIT_BASE_REF=%q\nEDIT_BRANCH_NAME=%q\n' "$current_component_id" "$base_ref" "$branch_name" > "$state_file"
}

load_edit_state() {
  local expected_component_id="$1"
  if [[ ! -f "$state_file" ]]; then
    fail "No active edit session found for $expected_component_id"
    return 1
  fi
  COMPONENT_ID=""
  EDIT_BASE_REF=""
  EDIT_BRANCH_NAME=""
  # shellcheck disable=SC1090
  source "$state_file"
  if [[ "$COMPONENT_ID" != "$expected_component_id" || -z "$EDIT_BASE_REF" || -z "$EDIT_BRANCH_NAME" ]]; then
    fail "Edit session state is incomplete for $expected_component_id"
    return 1
  fi
}

clear_edit_state() {
  rm -f "$state_file"
}

apply_patches_to_repo() {
  local repo_path="$1"
  local current_patches_dir="$2"
  local patch_file=""
  [[ -d "$current_patches_dir" ]] || return 0
  while IFS= read -r -d '' patch_file; do
    if ! git -C "$repo_path" am --3way "$patch_file" >/dev/null; then
      git -C "$repo_path" am --abort >/dev/null 2>&1 || true
      fail "Failed to apply patch for $component_id: $(basename "$patch_file")"
      return 1
    fi
  done < <(find "$current_patches_dir" -maxdepth 1 -type f -name '*.patch' -print0 | sort -z)
}

export_patch_series() {
  local repo_path="$1"
  local current_patches_dir="$2"
  local base_ref="$3"
  mkdir -p "$current_patches_dir"
  find "$current_patches_dir" -maxdepth 1 -type f -name '*.patch' -delete
  if [[ -z "$(git -C "$repo_path" rev-list --max-count=1 "$base_ref"..HEAD)" ]]; then
    return 0
  fi
  git -C "$repo_path" format-patch --output-directory "$current_patches_dir" "$base_ref"..HEAD >/dev/null
}

ensure_generated_tree() {
  mkdir -p "$generated_dir/components" "$render_work_dir"
  printf '*\n!.gitignore\n' > "$generated_dir/.gitignore"
}

render_component_to_generated() {
  local component_work_dir="$render_work_dir/$component_id"
  local destination_dir="$generated_dir/components/$component_id"

  ensure_vendor_repo
  reset_vendor_repo_to_ref
  ensure_generated_tree
  rm -rf "$component_work_dir" "$destination_dir"
  git -C "$vendor_abs" worktree remove --force "$component_work_dir" >/dev/null 2>&1 || true
  git -C "$vendor_abs" worktree add --force --detach "$component_work_dir" HEAD >/dev/null
  apply_patches_to_repo "$component_work_dir" "$patches_abs"
  mkdir -p "$destination_dir"
  git -C "$component_work_dir" archive --format=tar HEAD | tar -xf - -C "$destination_dir"
  git -C "$vendor_abs" worktree remove --force "$component_work_dir" >/dev/null
}
