function _brs_list
    set -f base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$base_branch"
        set base_branch develop
    end

    set -f pr_entries (gh pr list --json headRefName,state --limit 200 2>/dev/null \
        | jq -r '.[] | .headRefName + "=" + .state' 2>/dev/null)

    set -f current (git branch --show-current 2>/dev/null)

    for branch in (git branch --sort=-committerdate --format='%(refname:short)' \
                   | grep -vE "^($base_branch|main|master)"'$')
        set -f age (git log -1 --format='%ar' $branch 2>/dev/null)
        set -f pr_line (printf '%s\n' $pr_entries | grep -E "^$branch=")

        if test -n "$pr_line"
            set -f suffix (printf '\e[32m●\e[0m  %s' $age)
        else
            set -f suffix (printf '   %s' $age)
        end

        if test "$branch" = "$current"
            printf '\e[1m%-65s  %s\e[0m\n' $branch $suffix
        else
            printf '%-65s  %s\n' $branch $suffix
        end
    end
end
