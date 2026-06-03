function _brs_delete_branch --argument branch
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        printf 'Cannot delete the current branch.\n'
        sleep 1.5
        return 1
    end

    read --prompt-str "Delete '$branch'? [y/N] " confirm
    if string match -qi y $confirm
        if not git branch -d $branch 2>&1
            printf 'Not fully merged — use ⌥D to force delete.\n'
            sleep 2
        end
    end
end
