function _brs_list
    set -f base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$base_branch"
        set base_branch develop
    end

    set -f pr_entries (gh pr list --state all --json headRefName,state --limit 200 2>/dev/null \
        | jq -r '.[] | .headRefName + "=" + .state' 2>/dev/null)

    set -f wt_branches (git worktree list --porcelain 2>/dev/null \
        | awk '/^$/{block++} block>=1 && /^branch /{sub("branch refs/heads/",""); print}')

    set -f current (git branch --show-current 2>/dev/null)

    set -f branches (git branch --sort=-committerdate --format='%(refname:short)' \
                     | grep -vE "^($base_branch|main|master)"'$')

    set -f col_width 0
    for branch in $branches
        set -f len (string length $branch)
        if test $len -gt $col_width
            set col_width $len
        end
    end
    set col_width (math $col_width + 2)

    for branch in $branches
        set -f age (git log -1 --format='%ar' $branch 2>/dev/null)
        set -f pr_line (printf '%s\n' $pr_entries | grep -E "^$branch=")

        if contains -- $branch $wt_branches
            set -f wt_marker (printf '\e[33m󰙅\e[0m ')
        else
            set -f wt_marker '  '
        end

        if test -n "$pr_line"
            set -f pr_state (string split '=' $pr_line)[2]
            switch $pr_state
                case OPEN
                    set -f dot_color '\e[32m'   # green
                case MERGED
                    set -f dot_color '\e[35m'   # magenta
                case CLOSED
                    set -f dot_color '\e[31m'   # red
                case '*'
                    set -f dot_color '\e[32m'
            end
            set -f suffix (printf '%s'"$dot_color"'●\e[0m  %s' $wt_marker $age)
        else
            set -f suffix (printf '%s   %s' $wt_marker $age)
        end

        set -f padded (string pad -r -w $col_width $branch)
        if test "$branch" = "$current"
            printf '%s\t\e[1;36m▶ %s  %s\e[0m\n' $branch $padded $suffix
        else
            printf '%s\t  %s  %s\n' $branch $padded $suffix
        end
    end
end
