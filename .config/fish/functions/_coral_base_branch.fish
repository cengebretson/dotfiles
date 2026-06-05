function _coral_base_branch
    set -f branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -n "$branch"
        printf '%s\n' $branch
        return 0
    end

    for candidate in main master develop
        if git show-ref --verify --quiet "refs/heads/$candidate"
            printf '%s\n' $candidate
            return 0
        end
    end

    set -f current (git branch --show-current 2>/dev/null)
    if test -n "$current"
        printf '%s\n' $current
        return 0
    end

    echo "coral: cannot determine base branch." >&2
    echo "coral: run 'git remote set-head origin --auto' to fix remote detection." >&2
    return 1
end
