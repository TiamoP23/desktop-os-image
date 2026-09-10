#!/usr/bin/env bash
set -euo pipefail

source_dir="bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin"
extension_file="${NEXTPINP_SOURCE_FILE:-$source_dir/extension.js}"
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
require_source "$extension_file" 'window.get_work_area_for_monitor(remembered)' 'window-scoped monitor work area'
require_source "$extension_file" 'window.unmake_above()' 'inverse always-on-top behavior'
require_source "$extension_file" 'window.unstick()' 'inverse all-workspaces behavior'
require_source "$extension_file" 'firstFrameId' 'tracked first-frame signal'
require_source "$extension_file" 'this._trackedWindows.has(window)' 'guarded first-frame callback'
require_source "$extension_file" 'actor.disconnect(signalIds.firstFrameId)' 'disconnected first-frame signal'
require_source "$extension_file" 'DIAGONAL_AXIS_RATIO' 'diagonal velocity classification'
require_source "$extension_file" 'hide_from_window_list' 'window-list hiding'
require_source "$extension_file" "window.connect('notify::minimized'" 'minimize lifecycle handling'
require_source "$extension_file" 'window.delete(global.get_current_time())' 'minimize-to-close behavior'
require_source "$extension_file" 'originalAbove: window.is_above()' 'record original always-on-top state'
require_source "$extension_file" 'originalAllWorkspaces: window.is_on_all_workspaces()' 'record original workspace state'
require_source "$extension_file" 'originalSkipTaskbar: window.is_skip_taskbar()' 'record original window-list state'
require_source "$extension_file" 'if (!signalIds.originalSkipTaskbar)' 'restore window-list visibility conditionally'
require_source "$extension_file" 'window.show_in_window_list?.()' 'inverse window-list hiding'

python3 - "$extension_file" <<'PY'
import re
import sys
from pathlib import Path


source = Path(sys.argv[1]).read_text()


def block_after(label, pattern, text):
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise SystemExit(f"Missing Next PIP structure: {label}")
    opening = text.find("{", match.start())
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    for index in range(opening, len(text)):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
            continue
        if block_comment:
            if char == "*" and next_char == "/":
                block_comment = False
            continue
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in "'\"`":
            quote = char
        elif char == "/" and next_char == "/":
            line_comment = True
        elif char == "/" and next_char == "*":
            block_comment = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[opening + 1:index]
    raise SystemExit(f"Unclosed Next PIP structure: {label}")


def compact(text):
    text = re.sub(r"//[^\n]*|/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"\s+", "", text)


manage = block_after("_managePiPWindow method", r"^    _managePiPWindow\(window\)\s*\{", source)
unmanaged = block_after("unmanaged callback", r"signalIds\.unmanagedId\s*=\s*window\.connect\('unmanaged',\s*\(\)\s*=>\s*\{", manage)
if compact(unmanaged) != "this._untrackPiPWindow(window);":
    raise SystemExit("Unmanaged Next PIP callback must only untrack the window")

disable = block_after("disable method", r"^    disable\(\)\s*\{", source)
loop = block_after("disable tracked-window loop", r"for\s*\(const\s+window\s+of\s+this\._trackedWindows\.keys\(\)\)\s*\{", disable)
if compact(loop) != "this._restorePiPWindow(window);this._untrackPiPWindow(window);":
    raise SystemExit("Disable tracked-window loop must only restore then untrack each window")
PY

if grep -Fq 'build_output: .' manifests/components.yml; then
  printf 'Next PIP must render through source-tree mode, not build_output=.\n' >&2
  exit 1
fi
