#!/usr/bin/env bash
set -euo pipefail

assert_head() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(git -C "$path" rev-parse HEAD)"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s: expected %s, found %s\n' "$path" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_contains() {
  local path="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$path"; then
    printf '%s: missing %s\n' "$path" "$expected" >&2
    exit 1
  fi
}

assert_head vendor/extensions/dash-to-panel df8a15bac1e5e9fb2b4c5f2407981bd8365a72c4
assert_head vendor/extensions/blur-my-shell b689b991c9a60098818f0dd3772bc9c7a83bbbcb
assert_head vendor/extensions/coverflow-alt-tab 189ee9c5fcf5a2a84914fb337f4d53a705060532
assert_head vendor/extensions/clipboard-indicator c880c7fb88dc7232a61a5864d125989a4f375daa
assert_head vendor/extensions/nextpinp b6d29fa278cd8e509d8521f578aebeed0864bfbb

assert_file_contains bluebuild/recipes/main.yml 'image-version: "44.20260902"'
assert_file_contains .github/workflows/build.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/pr-validate.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/build.yml 'blue-build/github-action@836161eb076426a451e6a0054f722b1153b8b3ad # v1.12.0'
