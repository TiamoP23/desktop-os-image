#!/usr/bin/env bash
set -euo pipefail

extension_root="bluebuild/files/generated/usr/share/gnome-shell/extensions"

python3 - "$extension_root" <<'PY'
import json
import sys
from pathlib import Path

extension_root = Path(sys.argv[1])
expected_uuids = {
    "blur-my-shell@aunetx",
    "clipboard-indicator@tudmotu.com",
    "CoverflowAltTab@palatis.blogspot.com",
    "dash-to-panel@jderose9.github.com",
    "nextpinp@leonid.nasedkin",
}

actual_uuids = {path.name for path in extension_root.iterdir() if path.is_dir()}
if actual_uuids != expected_uuids:
    print(
        f"Expected rendered extension UUIDs {sorted(expected_uuids)}, "
        f"found {sorted(actual_uuids)}",
        file=sys.stderr,
    )
    raise SystemExit(1)

for uuid in sorted(expected_uuids):
    metadata_path = extension_root / uuid / "metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        print(f"Unable to parse {metadata_path}: {error}", file=sys.stderr)
        raise SystemExit(1)

    if metadata.get("uuid") != uuid:
        print(f"{metadata_path} does not declare UUID {uuid}", file=sys.stderr)
        raise SystemExit(1)

    shell_versions = metadata.get("shell-version")
    if not isinstance(shell_versions, list) or "50" not in shell_versions:
        print(f"{metadata_path} does not declare GNOME Shell 50 support", file=sys.stderr)
        raise SystemExit(1)
PY
