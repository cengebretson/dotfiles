function _brs_force_delete_branch --argument branch
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        echo "brs: cannot delete the current branch — checkout another branch first"
        return 1
    end

    read --prompt-str "Force delete '$branch' (unmerged changes will be lost)? [y/N] " --local confirm
    if not string match -qi 'y' $confirm
        echo "brs: cancelled"
        return 1
    end

    git branch -D $branch
end
