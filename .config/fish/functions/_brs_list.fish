function _brs_list
    set -f base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$base_branch"
        set base_branch develop
    end

    set -f repo_key (git remote get-url origin 2>/dev/null | string replace -ra '[^a-zA-Z0-9_-]' '_')
    set -f cache_file /tmp/brs_pr_$repo_key.cache
    set -f cache_ttl 300

    set -f wt_branches (git worktree list --porcelain 2>/dev/null \
        | awk '/^$/{block++} block>=1 && /^branch /{sub("branch refs/heads/",""); print}')

    set -f current (git branch --show-current 2>/dev/null)

    set -f branches (git branch --sort=-committerdate --format='%(refname:short)' \
                     | grep -vE "^($base_branch|main|master)"'$')

    set -f pr_entries
    if test -f $cache_file
        set -f cache_age (math (date +%s) - (stat -f %m $cache_file 2>/dev/null))
        if test $cache_age -lt $cache_ttl
            set -f pr_entries (cat $cache_file)
        end
    end

    if test -z "$pr_entries" -a (count $branches) -gt 0
        set -f head_terms
        for b in $branches
            set -f head_terms $head_terms "head:$b"
        end
        set -f search_query (string join " OR " $head_terms)
        set -f pr_entries (gh pr list --search "$search_query" --state all \
            --json headRefName,state,reviewDecision --limit (count $branches) 2>/dev/null \
            | jq -r '.[] | .headRefName + "=" + .state + "=" + (.reviewDecision // "")' 2>/dev/null)
        printf '%s\n' $pr_entries > $cache_file
    end

    set -f col_width 0
    for branch in $branches
        set -f len (string length $branch)
        if test $len -gt $col_width
            set col_width $len
        end
    end
    set col_width (math $col_width + 2)

    for branch in $branches
        set -f age (git log -1 --format='%cr' $branch 2>/dev/null)
        set -f pr_line (printf '%s\n' $pr_entries | awk -F= -v b="$branch" '$1 == b')

        if contains -- $branch $wt_branches
            set -f wt_marker (printf '\e[33m󰙅\e[0m ')
        else
            set -f wt_marker '  '
        end

        if test -n "$pr_line"
            set -f pr_parts (string split '=' $pr_line)
            set -f pr_state $pr_parts[2]
            set -f pr_review $pr_parts[3]
            switch $pr_state
                case OPEN
                    switch $pr_review
                        case APPROVED
                            set -f dot_color '\e[32m'   # green
                            set -f dot '✓'
                        case CHANGES_REQUESTED
                            set -f dot_color '\e[33m'   # yellow
                            set -f dot '!'
                        case '*'
                            set -f dot_color '\e[32m'   # green
                            set -f dot '●'
                    end
                case MERGED
                    set -f dot_color '\e[35m'   # magenta
                    set -f dot '󰘬'
                case CLOSED
                    set -f dot_color '\e[31m'   # red
                    set -f dot '●'
                case '*'
                    set -f dot_color '\e[32m'
                    set -f dot '●'
            end
            set -f suffix (printf '%s'"$dot_color"'%s\e[0m  %s' $wt_marker $dot $age)
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
