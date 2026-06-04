function _coral_delete_common --argument-names branch force
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        printf 'Cannot delete the current branch.\n'
        sleep 1.5
        return 1
    end

    if test "$force" = force
        if _coral_confirm "Force delete '$branch'?"
            git branch -D "$branch" 2>&1
            or printf 'Delete failed.\n' >&2
        end
    else
        if _coral_confirm "Delete '$branch'?"
            if not git branch -d "$branch" 2>&1
                printf 'Not fully merged — use ⌥D to force delete.\n'
                sleep 2
            end
        end
    end
end
