# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

# shellcheck shell=bash

settings="$1"
state="$2"
next="$3"
merge_jq="$4"

skip() {
  echo "warning: $1; the managed settings were not merged" >&2
  exit 0
}

if [[ -L $settings ]]; then
  skip "$settings is a symbolic link"
fi

if [[ -e $settings ]] && ! jq -e 'type == "object"' "$settings" > /dev/null 2>&1; then
  skip "$settings is not a JSON object"
fi

previous=/dev/null
if [[ -e $state ]]; then
  if ! jq -e 'type == "object"' "$state" > /dev/null 2>&1; then
    skip "$state is not a JSON object (remove it to merge again)"
  fi
  previous="$state"
fi

mkdir -p "$(dirname "$settings")" "$(dirname "$state")"
work=""
state_tmp=""
trap 'rm -rf "$work" "$state_tmp"' EXIT
work="$(mktemp -d "$(dirname "$settings")/.managed-settings.XXXXXX")"
state_tmp="$(mktemp "$state.XXXXXX")"

snapshot() {
  if [[ -e $settings ]]; then
    sha256sum < "$settings"
  else
    echo missing
  fi
}

for _ in 1 2 3; do
  before="$(snapshot)"
  if [[ -e $settings ]]; then
    cp "$settings" "$work/current.json"
  else
    echo '{}' > "$work/current.json"
  fi

  if ! jq --slurpfile prev "$previous" --slurpfile next "$next" -f "$merge_jq" \
    "$work/current.json" > "$work/result.json"; then
    skip "merging into $settings failed"
  fi

  jq '.settings' "$work/result.json" > "$work/settings.json"
  jq '.added' "$work/result.json" > "$state_tmp"
  if [[ -e $settings ]]; then
    chmod "$(stat -c %a "$settings")" "$work/settings.json"
  fi
  chmod 0644 "$state_tmp"

  if [[ "$(snapshot)" == "$before" ]]; then
    mv "$work/settings.json" "$settings"
    mv "$state_tmp" "$state"
    exit 0
  fi
done

skip "$settings kept changing while the managed settings were merged"
