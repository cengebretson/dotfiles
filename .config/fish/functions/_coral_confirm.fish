function _coral_confirm --argument-names prompt
    _coral_load_config

    if command -q gum
        gum confirm \
            --default=false \
            --affirmative="Yes" \
            --negative="No" \
            --prompt.foreground="$CORAL_COLOR_TEXT" \
            --selected.background="$CORAL_COLOR_ACCENT" \
            --selected.foreground="$CORAL_COLOR_BG" \
            --unselected.foreground="$CORAL_COLOR_MUTED" \
            --unselected.background="" \
            "$prompt"
    else
        # Fallback to fzf when gum is not installed.
        set -lx FZF_DEFAULT_OPTS ""
        set -f choice (printf 'No\nYes' | fzf \
            --height=6 --layout=default --border=none --input-border=none --list-border=none \
            --no-sort --no-info --header-first --header="  $prompt" \
            --prompt="  ❯ " --pointer='▶' \
            --bind 'tab:down,btab:up,right:down,left:up,esc:abort')
        test "$choice" = Yes
    end
end
