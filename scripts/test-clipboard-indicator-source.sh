#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$script_dir/../bluebuild/files/generated/usr/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com"

python3 - "$source_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
for name in ('extension.js', 'confirmDialog.js'):
    source = (root / name).read_text()
    if re.search(r'\bvertical\s*:', source):
        raise SystemExit(f'{name} still uses the removed St vertical property')
    if "import { boxLayoutOrientation } from './compat.js';" not in source:
        raise SystemExit(f'{name} does not import the orientation helper')
    if source.count('...boxLayoutOrientation(') != 2:
        raise SystemExit(f'{name} must adapt both BoxLayout constructors')
PY

gjs -m "$script_dir/test-clipboard-indicator-compat.js" "$source_dir"
