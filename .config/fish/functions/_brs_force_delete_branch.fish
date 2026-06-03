function _brs_force_delete_branch --argument branch
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        printf 'Cannot delete the current branch.\n'
        sleep 1.5
        return 1
    end

    read --prompt-str "Force delete '$branch'? [y/N] " confirm
    if string match -qi y $confirm
        git branch -D $branch 2>&1
    end
end
