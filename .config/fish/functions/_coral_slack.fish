function _coral_slack
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'coral: not in a git repository.' >&2
        return 1
    end

    _coral_list >/dev/null

    set -f cache_file (_coral_cache_file)
    if test -z "$cache_file"; or not test -f "$cache_file"
        echo 'coral: no PR cache available.' >&2
        return 1
    end

    set -f sep (printf '\x01')
    set -f printed 0
    for entry in (cat "$cache_file")
        set -f parts (string split \x01 $entry)
        test (count $parts) -ge 8; or continue

        set -f branch $parts[1]
        set -f state $parts[3]
        set -f labels $parts[5]
        set -f title $parts[6]
        set -f url $parts[8]

        test "$state" = OPEN; or continue
        test -n "$url"; or continue

        set -f haystack "$branch $title $labels"
        set -f matches_filters 1
        for filter in $argv
            if not string match -qi "*$filter*" -- "$haystack"
                set matches_filters 0
                break
            end
        end
        test $matches_filters -eq 1; or continue

        set -f label_text
        if test -n "$labels"
            set label_text " ["(string join ', ' (string split , $labels))"]"
        end

        printf '• <%s|%s> — `%s`%s\n' "$url" "$title" "$branch" "$label_text"
        set printed 1
    end

    if test $printed -eq 0
        if test (count $argv) -gt 0
            echo "coral: no open local-branch PRs matched: $argv" >&2
        else
            echo 'coral: no open local-branch PRs found.' >&2
        end
        return 1
    end
end
