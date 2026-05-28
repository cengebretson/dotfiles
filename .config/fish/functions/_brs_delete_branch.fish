function _brs_delete_branch --argument branch
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        echo "brs: cannot delete the current branch — checkout another branch first"
        return 1
    end

    if not git branch -d $branch
        echo "brs: '$branch' is not fully merged — use ⌥D to force delete"
        return 1
    end
end
