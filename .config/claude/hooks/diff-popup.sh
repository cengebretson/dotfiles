#!/usr/bin/env bash

json=$(cat)
session_id=$(printf '%s' "$json" | jq -r '.session_id // ""')
flag_file="$HOME/.config/claude/flags/diff-popup"
changes_file="/tmp/claude-changes-${session_id}"

[[ ! -f "$flag_file" ]] && exit 0
[[ ! -f "$changes_file" ]] && exit 0

files=$(sort -u "$changes_file")
rm -f "$changes_file"
[[ -z "$files" ]] && exit 0

files_list=$(mktemp)
echo "$files" > "$files_list"

viewer="$HOME/.config/claude/hooks/diff-viewer.sh"

if [[ -n "$TMUX" ]]; then
    tmux display-popup -E -w 90% -h 90% "$viewer $files_list $session_id"
else
    "$viewer" "$files_list" "$session_id" < /dev/tty > /dev/tty
fi

rm -rf "/tmp/claude-snapshots-${session_id}"
