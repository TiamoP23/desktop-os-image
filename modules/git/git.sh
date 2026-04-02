#!/usr/bin/env bash
set -euo pipefail

REPO_URL="$(echo "$1" | jq -r 'try .["repo"]')"
BRANCH="$(echo "$1" | jq -r 'try .["branch"]')"
DEST_DIR="$(echo "$1" | jq -r 'try .["dest"]')"

if [[ -z "$REPO_URL" ]]; then
  echo "git: required option 'repo' is missing" >&2
  exit 1
fi

if [[ -z "$DEST_DIR" ]]; then
  echo "git: required option 'dest' is missing" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git: git is required but was not found in PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST_DIR")"

# Keep behavior deterministic when rerun: replace any previous directory.
rm -rf "$DEST_DIR"

if [[ -n "$BRANCH" ]]; then
  git clone --branch "$BRANCH" "$REPO_URL" "$DEST_DIR"
else
  git clone "$REPO_URL" "$DEST_DIR"
fi
