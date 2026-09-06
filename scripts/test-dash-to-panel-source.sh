#!/usr/bin/env bash
set -euo pipefail

source_dir="bluebuild/files/generated/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
extension_file="$source_dir/extension.js"
panel_file="$source_dir/panel.js"

require_source() {
  local path="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$path"; then
    printf 'Missing Dash to Panel behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source "$extension_file" "Config.PACKAGE_VERSION >= '50'" 'detect GNOME 50 startup behavior'
require_source "$extension_file" 'Main.overview.hide()' 'use the upstream startup overview fix'
require_source "$panel_file" 'let isShown = !isOverview || isOverviewFocusedMonitor || !this.isPrimary' 'keep secondary panels visible in overview'
