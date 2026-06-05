function _coral_delete_common --argument-names branch force
    _coral_load_config

    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        printf 'Cannot delete the current branch.\n'
        sleep 1.5
        return 1
    end

    if test "$force" = force
        if command -q gum
            gum style --foreground="$CORAL_COLOR_DANGER" --bold --border=rounded \
                --border-foreground="$CORAL_COLOR_DANGER" --padding="0 1" --margin="1 2" "$branch"
        else
            printf '\n  %s\n\n' "$branch"
        end
        if _coral_confirm "Force delete this branch?"
            git branch -D "$branch" 2>&1
            or printf 'Delete failed.\n' >&2
        end
    else
        if command -q gum
            gum style --foreground="$CORAL_COLOR_ACCENT" --bold --border=rounded \
                --border-foreground="$CORAL_COLOR_ACCENT" --padding="0 1" --margin="1 2" "$branch"
        else
            printf '\n  %s\n\n' "$branch"
        end
        if _coral_confirm "Delete this branch?"
            if not git branch -d "$branch" 2>&1
                printf 'Not fully merged — use ⌥D to force delete.\n'
                sleep 2
            end
        end
    end
end
