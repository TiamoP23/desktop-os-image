#!/usr/bin/env bash
set -euo pipefail

source_dir="bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin"
extension_file="$source_dir/extension.js"
prefs_file="$source_dir/prefs.js"
schema_file="$source_dir/schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml"

defaults_file="bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell"

require_source() {
  local path="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$path"; then
    printf 'Missing Next PIP behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source "$defaults_file" '[org/gnome/shell/extensions/auto-pip-manager]' 'correct dconf schema path'
require_source "$defaults_file" 'remember-monitor=true' 'remember-monitor image default'
require_source "$schema_file" 'name="remember-monitor"' 'remember-monitor schema key'
require_source "$schema_file" 'name="snap-animation"' 'snap-animation schema key'
require_source "$prefs_file" "'velocity-throw'" 'velocity preference'
require_source "$extension_file" 'get_work_area_for_monitor(remembered)' 'workspace monitor work area'
require_source "$extension_file" 'DIAGONAL_AXIS_RATIO' 'diagonal velocity classification'
require_source "$extension_file" 'hide_from_window_list' 'window-list hiding'
require_source "$extension_file" "window.connect('notify::minimized'" 'minimize lifecycle handling'
require_source "$extension_file" 'window.delete(global.get_current_time())' 'minimize-to-close behavior'

if grep -Fq 'build_output: .' manifests/components.yml; then
  printf 'Next PIP must render through source-tree mode, not build_output=.\n' >&2
  exit 1
fi
