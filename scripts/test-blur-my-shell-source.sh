#!/usr/bin/env bash
set -euo pipefail

extension_file="${BLUR_MY_SHELL_SOURCE_FILE:-bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js}"

require_source() {
  local pattern="$1"
  local description="$2"
  if ! grep -Fq "$pattern" "$extension_file"; then
    printf 'Missing Blur My Shell behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source 'find_panel_monitor(panel) {' 'central monitor resolver'
require_source 'panel.get_parent()?._dtpIndex' 'Dash to Panel monitor assignment'
require_source 'Main.layoutManager.monitors[monitor_index]' 'assigned monitor lookup'
require_source 'Main.layoutManager.findMonitorForActor(panel)' 'non-Dash-to-Panel fallback'

resolver_calls="$(grep -Fc 'this.find_panel_monitor(panel)' "$extension_file")"
if [[ "$resolver_calls" -ne 2 ]]; then
  printf 'Expected two monitor resolver calls, found %s\n' "$resolver_calls" >&2
  exit 1
fi
