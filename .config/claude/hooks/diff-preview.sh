#!/usr/bin/env bash
file="$1"
session_id="$2"
width="${FZF_PREVIEW_COLUMNS:-80}"
delta_flags="--width $width --file-style omit --hunk-header-style omit"

snap_name="${file//\//_}"
snapshot="/tmp/claude-snapshots-${session_id}/${snap_name}"

if [[ -f "$snapshot" ]]; then
    git diff --color=always --no-index "$snapshot" "$file" 2>/dev/null | delta $delta_flags
elif git ls-files --error-unmatch "$file" 2>/dev/null; then
    git diff --color=always HEAD -- "$file" | delta $delta_flags
else
    git diff --color=always --no-index /dev/null "$file" 2>/dev/null | delta $delta_flags
fi
