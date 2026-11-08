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

assert_head vendor/extensions/dash-to-panel db578c4f0061686609ed0bd1422967dfee2554d6
assert_head vendor/extensions/blur-my-shell 19ce844b8ca36efe4a181b2cf81504063eb4ce4b
assert_head vendor/extensions/coverflow-alt-tab 443f3ae98fc14598ed81e57c1b7f0ca15787b638
assert_head vendor/extensions/clipboard-indicator c880c7fb88dc7232a61a5864d125989a4f375daa
assert_head vendor/extensions/nextpinp 339692b689dffbafd4568b325bd2a1c518fbd38b

assert_file_contains bluebuild/recipes/main.yml 'image-version: "45.20261105"'
assert_file_contains .github/workflows/build.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/pr-validate.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/build.yml 'blue-build/github-action@836161eb076426a451e6a0054f722b1153b8b3ad # v1.12.0'
