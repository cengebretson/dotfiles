#!/usr/bin/env bash

json=$(cat)
session_id=$(printf '%s' "$json" | jq -r '.session_id // ""')
flag_file="$HOME/.config/claude/flags/diff-popup"
changes_file="/tmp/claude-changes-${session_id}"

[[ ! -f "$changes_file" ]] && exit 0

files=$(sort -u "$changes_file")
rm -f "$changes_file"
[[ -z "$files" ]] && exit 0

files_list=$(mktemp)
echo "$files" > "$files_list"

# Check if the claude-preview pane exists in the current session
preview_pane=$(tmux list-panes -s -F "#{pane_title} #{pane_id}" 2>/dev/null \
    | grep "^claude-preview-list " | awk '{print $2}' | head -1)

if [[ -n "$preview_pane" ]]; then
    signal_file="/tmp/claude-preview-signal"
    cp "$files_list" "$signal_file"
    echo "$session_id" > "${signal_file}.session"
    rm -f "$files_list"
elif [[ -f "$flag_file" ]]; then
    viewer="$HOME/.config/claude/hooks/diff-viewer.sh"
    if [[ -n "$TMUX" ]]; then
        tmux display-popup -E -w 90% -h 90% "$viewer $files_list $session_id"
    else
        "$viewer" "$files_list" "$session_id" < /dev/tty > /dev/tty
    fi
    rm -rf "/tmp/claude-snapshots-${session_id}"
fi
