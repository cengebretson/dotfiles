function _coral_pr_entries
    command -q gh; or return 1
    command -q jq; or return 1
    test (count $argv) -gt 1; or return 1

    set -f sep (printf '\x01')
    set -f history_days (_coral_pr_history_days)
    set -f since (_coral_since_date "$history_days")
    set -f batch_size (_coral_pr_batch_size)
    set -f tmp_dir (mktemp -d)
    or return 1

    set -f active_jobs 0
    while test (count $argv) -gt 1
        set -f branch $argv[1]
        set -f sha $argv[2]
        set -e argv[1]
        set -e argv[1]

        set -f branch_key (printf '%s' "$branch" | shasum -a 256 2>/dev/null | string sub -l 16)
        test -n "$branch_key"; or continue
        printf '%s\n' "$branch" > "$tmp_dir/$branch_key.branch"
        printf '%s\n' "$sha" > "$tmp_dir/$branch_key.sha"

        gh pr list --head "$branch" --state all --limit 20 \
            --json headRefName,state,reviewDecision,labels,title,baseRefName,updatedAt,url \
            > "$tmp_dir/$branch_key.json" 2>/dev/null &
        set active_jobs (math $active_jobs + 1)

        if test $active_jobs -ge $batch_size
            wait
            set active_jobs 0
        end
    end
    wait

    for json_file in "$tmp_dir"/*.json
        test -e "$json_file"; or continue
        jq -e 'type == "array"' "$json_file" >/dev/null 2>&1; or continue

        set -f branch_key (basename "$json_file" .json)
        set -f branch (cat "$tmp_dir/$branch_key.branch" 2>/dev/null)
        set -f sha (cat "$tmp_dir/$branch_key.sha" 2>/dev/null)
        test -n "$branch"; or continue
        test -n "$sha"; or continue

        set -f rows (jq -r --arg sep "$sep" --arg since "$since" --arg branch "$branch" --arg sha "$sha" \
            'map(select(.state == "OPEN" or ($since != "" and (.updatedAt[0:10] >= $since)))) | sort_by(if .state == "OPEN" then 0 elif .state == "MERGED" then 1 else 2 end) | unique_by(.headRefName)[] | [$branch, $sha, .state, (.reviewDecision // ""), ([.labels[].name] | join(",")), .title, (.baseRefName // ""), (.url // "")] | join($sep)' \
            "$json_file" 2>/dev/null)
        if test -n "$rows"
            printf '%s\n' $rows
        else
            printf '%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n' "$branch" "$sep" "$sha" "$sep" "" "$sep" "" "$sep" "" "$sep" "" "$sep" "" "$sep" ""
        end
    end

    rm -rf "$tmp_dir"
end
