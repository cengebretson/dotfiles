#!/usr/bin/env bash
files_list="$1"
session_id="$2"
[[ ! -f "$files_list" ]] && exit 0

preview="$HOME/.config/claude/hooks/diff-preview.sh"

while IFS= read -r f; do
    display="${f/#$HOME/~}"
    printf '%s\t%s\n' "$display" "$f"
done < "$files_list" | fzf \
  --ansi \
  --delimiter='\t' \
  --with-nth=1 \
  --preview "$preview {2} $session_id" \
  --preview-window 'right:70%' \
  --prompt '󱙺 changes > ' \
  --header 'enter: nvim  esc: close' \
  --bind "enter:execute(nvim {2})" \
  --bind "ctrl-u:preview-half-page-up" \
  --bind "ctrl-d:preview-half-page-down" \
  --bind "shift-up:preview-up" \
  --bind "shift-down:preview-down"

rm -f "$files_list"
