function _coral_popup --argument-names cmd title fzf_port w h
    if test -z "$w"; set w 52; end
    if test -z "$h"; set h 5; end
    tmux display-popup -E -d "#{pane_current_path}" -w $w -h $h -T "$title" \
        -- fish -c "$cmd"
    curl -s --max-time 2 "localhost:$fzf_port" -d 'reload(_coral_list)' >/dev/null 2>&1
    or echo "WARNING: fzf reload failed — press ⌥r to refresh manually" >&2
end
