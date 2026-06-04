function _coral_list
    set -f base_branch (_coral_base_branch); or return 1

    # sha256 key avoids collisions from repos whose URLs differ only in punctuation
    set -f repo_key (git remote get-url origin 2>/dev/null | shasum -a 256 2>/dev/null | string sub -l 16)
    if test -z "$repo_key"
        echo "coral: shasum unavailable — cannot compute cache key" >&2
        return 1
    end
    set -f cache_file /tmp/coral_pr2_$repo_key.cache
    set -f cache_ttl 300

    # Skip the first block (main worktree = current checkout) so only linked worktrees get the icon.
    set -f wt_branches (git worktree list --porcelain 2>/dev/null \
        | awk 'BEGIN{n=0} /^worktree/{n++} n>1 && /^branch /{sub("branch refs/heads/",""); print}')

    set -f current (git branch --show-current 2>/dev/null)

    # Single git call: branch name + relative date + upstream tracking (free, no extra subprocess)
    # Filter in fish rather than grep to avoid regex metachar issues with branch names
    set -f branch_data_all (git branch --sort=-committerdate \
        --format='%(refname:short)%09%(committerdate:relative)%09%(upstream:trackshort)')
    set -f branch_data
    for line in $branch_data_all
        set -f _b (string split \t $line)[1]
        if test "$_b" != "$base_branch" -a "$_b" != main -a "$_b" != master
            set -f branch_data $branch_data $line
        end
    end

    # Extract branch names and compute col_width in one pass
    set -f branches
    set -f col_width 0
    for line in $branch_data
        set -f b (string split \t $line)[1]
        set -f branches $branches $b
        set -f len (string length $b)
        if test $len -gt $col_width
            set -f col_width $len
        end
    end
    set -f col_width (math $col_width + 2)

    set -f pr_entries
    if test -f $cache_file
        # Separate stat from math so a missing mtime doesn't produce a bad cache_age
        set -f mtime (stat -f %m $cache_file 2>/dev/null)
        if test -n "$mtime"
            set -f cache_age (math (date +%s) - $mtime)
            if test $cache_age -lt $cache_ttl
                set -f pr_entries (cat $cache_file)
            end
        end
    end

    # Validate cached entries have all 5 fields — drops corrupt lines written by old format
    if test -n "$pr_entries"
        set -f valid_entries
        for entry in $pr_entries
            if test (count (string split \x01 $entry)) -ge 5
                set -f valid_entries $valid_entries $entry
            end
        end
        set -f pr_entries $valid_entries
    end

    if test -z "$pr_entries" -a (count $branches) -gt 0
        # One gh pr view per local branch, all in parallel — only queries branches we actually have.
        # gh pr view prefers the open PR for a branch, falling back to the most recent closed/merged
        # one, so OPEN-wins is handled naturally without any dedup logic.
        set -f sep (printf '\x01')
        set -f tmp_dir (mktemp -d)
        for b in $branches
            set -f safe (string replace --all / _ -- $b)
            gh pr view "$b" --json headRefName,state,reviewDecision,labels,title \
                > "$tmp_dir/$safe.json" 2>/dev/null &
        end
        wait
        set -f pr_entries
        for f in "$tmp_dir"/*.json
            test -f "$f"; or continue
            test -s "$f"; or continue
            set pr_entries $pr_entries (jq -r --arg sep "$sep" \
                '[.headRefName, .state, (.reviewDecision // ""), ([.labels[].name] | join(",")), .title] | join($sep)' \
                "$f" 2>/dev/null)
        end
        rm -rf "$tmp_dir"
        if test -n "$pr_entries"
            set -f cache_tmp $cache_file.tmp
            printf '%s\n' $pr_entries > $cache_tmp && mv $cache_tmp $cache_file
        end
    end

    # Build parallel lists for O(1) branch→PR lookup — avoids one awk spawn per branch
    set -f pr_keys
    set -f pr_vals
    for entry in $pr_entries
        set -f pr_keys $pr_keys (string split \x01 $entry)[1]
        set -f pr_vals $pr_vals $entry
    end

    for line in $branch_data
        set -f parts (string split \t $line)
        set -f branch $parts[1]
        set -f age $parts[2]
        set -f trackshort $parts[3]

        set -f pr_line ''
        if set -f pr_idx (contains --index -- $branch $pr_keys)
            set -f pr_line $pr_vals[$pr_idx]
        end

        if contains -- $branch $wt_branches
            set -f wt_marker (printf '\e[33m󰙅\e[0m ')
        else
            set -f wt_marker '  '
        end

        if test -n "$pr_line"
            set -f pr_parts (string split \x01 $pr_line)
            set -f pr_state $pr_parts[2]
            set -f pr_review $pr_parts[3]
            set -f pr_labels $pr_parts[4]
            switch $pr_state
                case OPEN
                    switch $pr_review
                        case APPROVED
                            set -f dot_color '\e[32m'
                            set -f dot '✓'
                        case CHANGES_REQUESTED
                            set -f dot_color '\e[33m'
                            set -f dot '!'
                        case '*'
                            set -f dot_color '\e[32m'
                            set -f dot '●'
                    end
                case MERGED
                    set -f dot_color '\e[35m'
                    set -f dot '󰘬'
                case CLOSED
                    set -f dot_color '\e[31m'
                    set -f dot '●'
                case '*'
                    set -f dot_color '\e[32m'
                    set -f dot '●'
            end
            set -f suffix (printf '%s'"$dot_color"'%s\e[0m  %s' $wt_marker $dot $age)
            if test -n "$pr_labels"
                for label in (string split , $pr_labels)
                    set suffix $suffix(printf '  \e[2m[%s]\e[0m' $label)
                end
            end
        else
            set -f suffix (printf '%s   %s' $wt_marker $age)
        end

        set -f ahead (string match -r '[+]([0-9]+)' $trackshort)[2]
        set -f behind (string match -r '[-]([0-9]+)' $trackshort)[2]
        if test -n "$ahead"
            set suffix $suffix(printf '  \e[36m↑%s\e[0m' $ahead)
        end
        if test -n "$behind"
            set suffix $suffix(printf '  \e[33m↓%s\e[0m' $behind)
        end

        set -f padded (string pad -r -w $col_width $branch)
        if test "$branch" = "$current"
            printf '%s\t\e[1;36m▶ %s  %s\e[0m\n' $branch $padded $suffix
        else
            printf '%s\t  %s  %s\n' $branch $padded $suffix
        end
    end
end
