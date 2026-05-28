function _brs_force_delete_branch --argument branch
    set -f current (git branch --show-current 2>/dev/null)
    if test "$branch" = "$current"
        echo "brs: cannot delete the current branch — checkout another branch first"
        return 1
    end

    git branch -D $branch
end
