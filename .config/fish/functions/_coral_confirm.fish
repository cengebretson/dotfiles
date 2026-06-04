function _coral_confirm --argument-names prompt
    # Tab/shift-tab or arrow keys cycle between No (safe default) and Yes.
    # Escape or ctrl-c returns false without selecting.
    # Clear global FZF_DEFAULT_OPTS — the input-border/list-border/preview options break the layout.
    set -lx FZF_DEFAULT_OPTS ""
    set -f choice (printf 'No\nYes' | fzf \
        --height=100% \
        --layout=default \
        --border=none \
        --input-border=none \
        --list-border=none \
        --no-sort \
        --no-info \
        --header-first \
        --header="  $prompt" \
        --prompt="  ❯ " \
        --pointer='▶' \
        --color='prompt:bold:cyan,pointer:cyan,hl+:bold:green,fg+:bold,header:bold:white' \
        --bind 'tab:down,btab:up,right:down,left:up,esc:abort')
    test "$choice" = Yes
end
