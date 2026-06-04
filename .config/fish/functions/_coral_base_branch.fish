function _coral_base_branch
    set -f branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$branch"
        echo "coral: cannot determine base branch." >&2
        echo "coral: run 'git remote set-head origin --auto' to fix." >&2
        return 1
    end
    printf '%s\n' $branch
end
