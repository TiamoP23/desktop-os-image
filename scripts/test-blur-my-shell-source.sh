#!/usr/bin/env bash
set -euo pipefail

extension_file="${BLUR_MY_SHELL_SOURCE_FILE:-bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js}"

extract_method() {
  local method_signature="$1"

  awk -v method_signature="$method_signature" '
    {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      if (!started && line == method_signature)
        started = 1
      if (!started)
        next
      if (line == method_signature)
        print line
      else
        print
      braces = $0
      open_count = gsub(/{/, "", braces)
      close_count = gsub(/}/, "", braces)
      depth += open_count - close_count
      if (depth == 0)
        exit
    }
  ' "$extension_file"
}

assert_isolated_method() {
  local method="$1"
  local method_source

  method_source="$(extract_method "$method")"
  if [[ -z "$method_source" ]] || [[ "${method_source%%$'\n'*}" != "$method" ]]; then
    printf 'Method extraction did not begin with %s\n' "$method" >&2
    return 1
  fi
  local method_count
  method_count="$(grep -Ec '^[[:space:]]*(find_panel_monitor\(panel\) \{|blur_panel\(panel\) \{|update_size\(actors\) \{)' <<<"$method_source" || true)"
  if [[ "$method_count" -ne 1 ]]; then
    printf 'Method extraction was not isolated for %s\n' "$method" >&2
    return 1
  fi
}

resolver_signature='find_panel_monitor(panel) {'
blur_signature='blur_panel(panel) {'
update_signature='update_size(actors) {'

resolver_source="$(extract_method "$resolver_signature")"
assert_isolated_method "$resolver_signature"
if [[ -z "$resolver_source" ]] || ! grep -Fq 'panel.get_parent()?._dtpIndex' <<<"$resolver_source" \
  || ! grep -Fq 'Main.layoutManager.monitors[monitor_index]' <<<"$resolver_source" \
  || ! grep -Fq 'Main.layoutManager.findMonitorForActor(panel)' <<<"$resolver_source"; then
  printf 'Missing panel monitor resolver or actor fallback inside find_panel_monitor()\n' >&2
  exit 1
fi

blur_source="$(extract_method "$blur_signature")"
assert_isolated_method "$blur_signature"
if ! grep -Fq 'this.find_panel_monitor(panel)' <<<"$blur_source"; then
  printf 'Missing panel monitor resolver call in blur_panel()\n' >&2
  exit 1
fi

update_source="$(extract_method "$update_signature")"
assert_isolated_method "$update_signature"
if ! grep -Fq 'this.find_panel_monitor(panel)' <<<"$update_source"; then
  printf 'Missing panel monitor resolver call in update_size()\n' >&2
  exit 1
fi
