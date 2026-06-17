function pr-report --description "List your open PRs with Copilot threads, CI/review status, and Jira status"
    # Flags: --json (machine-readable) / --slack (paste-into-Slack). Remaining args
    # are an optional filter matched case-insensitively against title, branch, labels.
    argparse h/help j/json s/slack -- $argv
    or return

    if set -q _flag_help
        set_color --bold cyan; echo "pr-report"; set_color normal
        echo "List your open PRs with unresolved Copilot threads, CI/review status, and Jira status."
        echo
        set_color --bold white; echo "USAGE"; set_color normal
        echo "    pr-report [--slack | --json] [FILTER...]"
        echo
        set_color --bold white; echo "OPTIONS"; set_color normal
        echo "    -s, --slack   Plain text for pasting into Slack (raw URLs auto-link, *bold* renders)."
        echo "    -j, --json    Machine-readable JSON array (pipe into jq, a webhook, etc.)."
        echo "    -h, --help    Show this help."
        echo "    (no flag)     Pretty terminal report — the default."
        echo
        set_color --bold white; echo "FILTER"; set_color normal
        echo "    Any extra words are matched case-insensitively as a substring against each PR's"
        echo "    title + branch + labels. Works in any mode and in any position."
        echo
        set_color --bold white; echo "EXAMPLES"; set_color normal
        echo "    pr-report                          # full report, current repo"
        echo "    pr-report login                    # only PRs matching \"login\""
        echo "    pr-report --slack \"Ready for Review\"   # paste-ready list of that label"
        echo "    pr-report --json | jq '.[].url'    # just the PR URLs"
        echo
        set_color --bold white; echo "NOTES"; set_color normal
        echo "    • Runs against the current repo's GitHub remote (needs gh auth)."
        echo "    • Jira status/links are optional — they appear only when jira-cli is configured"
        echo "      (run 'jira init'). The Jira segment is a click-to-open link in supporting terminals."
        return 0
    end

    set -l filter (string lower -- "$argv")
    set -l mode pretty
    set -q _flag_json; and set mode json
    set -q _flag_slack; and set mode slack

    # Dim-but-readable grey for secondary text (Catppuccin Mocha subtext0).
    # brblack maps to a near-invisible surface colour on this theme.
    set -l dim a6adc8

    set -l repo (gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    if test -z "$repo"
        set_color red; echo "error: not in a GitHub repository" >&2; set_color normal
        return 1
    end

    set -l me (gh api user --jq .login 2>/dev/null)
    if test -z "$me"
        set_color red; echo "error: gh not authenticated" >&2; set_color normal
        return 1
    end

    # Jira is optional: only enrich rows when jira-cli is installed AND actually
    # hooked up. `jira me` exits 0 even with no token (warning goes to stderr), so
    # gate on non-empty stdout — that only appears when auth resolves. One network
    # probe per run; skip entirely when it fails.
    set -l jira_ok 0
    if command -q jira
        set -l jira_user (jira me 2>/dev/null)
        test -n "$jira_user"; and set jira_ok 1
    end

    # Jira base URL for click-to-open links — read from jira-cli config (present
    # whenever `jira init` has run, even if the token later fails). Trailing slash
    # trimmed; left empty when unknown so the segment falls back to plain text.
    set -l jira_server ""
    if test -f "$HOME/.config/.jira/.config.yml"
        set jira_server (yq '.server' "$HOME/.config/.jira/.config.yml" 2>/dev/null | string trim)
        test "$jira_server" = null; and set jira_server ""
        set jira_server (string replace -r '/$' '' -- "$jira_server")
    end

    # Decorative header is for humans only — keep it out of json/slack payloads.
    if test "$mode" = pretty
        set_color --bold cyan; echo "󰊤  PR Report"; set_color normal
        set_color $dim; echo "   $repo · @$me"; set_color normal
        if test -n "$filter"
            set_color $dim; echo "   filter: \"$filter\""; set_color normal
        end
        if test $jira_ok -eq 0
            set_color $dim; echo "   jira: not configured — run 'jira init' to add issue status"; set_color normal
        end
        echo ""
    end

    # ONE GraphQL call returns every open PR you authored with its url, review
    # decision, CI check rollup, labels, AND unresolved Copilot thread count. jq
    # reduces each PR to a TSV row so there are no per-PR calls. Field order:
    # 1 number  2 title  3 branch  4 reviewDecision  5 ci_pass  6 ci_fail
    # 7 ci_pend  8 labels(csv)  9 copilot_count  10 url
    set -l pr_lines (gh api graphql -f q="repo:$repo is:pr is:open author:$me" \
        -f query='query($q:String!){search(query:$q,type:ISSUE,first:100){nodes{... on PullRequest{number title url headRefName reviewDecision labels(first:20){nodes{name}} commits(last:1){nodes{commit{statusCheckRollup{contexts(first:100){nodes{__typename ... on CheckRun{status conclusion} ... on StatusContext{state}}}}}}} reviewThreads(first:100){nodes{isResolved comments(first:5){nodes{author{login}}}}}}}}}' \
        --jq '
            def cls:
              if .__typename == "CheckRun" then
                if .status != "COMPLETED" then "pending"
                elif ((.conclusion // "" | ascii_upcase) | . == "SUCCESS" or . == "NEUTRAL" or . == "SKIPPED") then "pass"
                else "fail" end
              else
                (.state // "" | ascii_upcase) as $s |
                if $s == "SUCCESS" then "pass"
                elif ($s == "PENDING" or $s == "EXPECTED") then "pending"
                else "fail" end
              end;
            .data.search.nodes[] | select(.number) |
            ([ (.commits.nodes[0].commit.statusCheckRollup.contexts.nodes // [])[] | cls ]) as $c |
            ([ .reviewThreads.nodes[] | select(.isResolved==false and any(.comments.nodes[]; .author!=null and (.author.login|ascii_downcase|contains("copilot")))) ] | length) as $cop |
            [ (.number|tostring), .title, .headRefName, (.reviewDecision // ""),
              ([$c[]|select(.=="pass")]|length|tostring),
              ([$c[]|select(.=="fail")]|length|tostring),
              ([$c[]|select(.=="pending")]|length|tostring),
              ([.labels.nodes[]?.name] | join(",")),
              ($cop|tostring),
              .url
            ] | @tsv' 2>/dev/null)
    if test $status -ne 0
        set_color red; echo "error: GitHub API request failed — run 'gh auth status' to check token permissions" >&2; set_color normal
        return 1
    end

    if test -z "$pr_lines"
        switch $mode
            case json
                echo "[]"
            case slack
                echo "No open PRs in $repo."
            case '*'
                set_color yellow; echo "  No open PRs found."; set_color normal
        end
        return 0
    end

    # Sort attention-first: PRs with open Copilot threads, failing CI, or changes
    # requested float to the top; original order is preserved within each group.
    set -l attn_lines
    set -l rest_lines
    for line in $pr_lines
        set -l p (string split \t $line)
        if test "$p[9]" -gt 0 2>/dev/null; or test "$p[6]" -gt 0 2>/dev/null; or test "$p[4]" = CHANGES_REQUESTED
            set -a attn_lines $line
        else
            set -a rest_lines $line
        end
    end
    set pr_lines $attn_lines $rest_lines

    # Batch every branch's Jira key into ONE list query, then look statuses up in
    # the render loop — instead of one `jira issue view` per PR. Parallel arrays
    # (jira_keys[i] -> jira_vals[i]) act as the lookup table.
    set -l jira_keys
    set -l jira_vals
    if test $jira_ok -eq 1
        set -l keys
        for line in $pr_lines
            set -l k (string match -r '[A-Z][A-Z0-9]+-[0-9]+' -- (string split \t $line)[3])
            test -n "$k"; and set -a keys $k
        end
        if test (count $keys) -gt 0
            set -l rows (jira issue list -q "key in ("(string join , $keys)")" --raw 2>/dev/null \
                | jq -r '.issues[]? | [.key, (.fields.status.name // "")] | @tsv' 2>/dev/null)
            for r in $rows
                set -l p (string split \t $r)
                set -a jira_keys $p[1]
                set -a jira_vals $p[2]
            end
            # Safety net: one nonexistent key makes Jira reject the whole
            # `key in (...)` query. If the batch came back empty despite having
            # keys, fall back to resilient per-key lookups so a single bad branch
            # doesn't blank out every status.
            if test (count $jira_keys) -eq 0
                for k in $keys
                    set -l st (jira issue view $k --raw 2>/dev/null | jq -r '.fields.status.name // empty' 2>/dev/null)
                    set -a jira_keys $k
                    set -a jira_vals "$st" # quote: keep arrays aligned even when status is empty
                end
            end
        end
    end

    set -l found 0
    set -l clean 0
    set -l json_rows   # TSV records accumulated for --json
    set -l slack_lines # bullet lines accumulated for --slack

    for line in $pr_lines
        set -l parts (string split \t $line)
        set -l pr_num $parts[1]
        set -l pr_title $parts[2]
        set -l pr_branch $parts[3]
        set -l review $parts[4]
        set -l ci_pass $parts[5]
        set -l ci_fail $parts[6]
        set -l ci_pend $parts[7]
        set -l pr_labels (string split , -- $parts[8])
        set -l count $parts[9]
        test -n "$count"; or set count 0
        set -l pr_url $parts[10]

        # Apply the filter before rendering (title + branch + labels).
        if test -n "$filter"
            if not string match -q -- "*$filter*" (string lower -- "$pr_title $pr_branch $parts[8]")
                continue
            end
        end

        # Jira key from the branch name (e.g. feature/FLYWL-1234-foo -> FLYWL-1234),
        # looked up in the batch table built above.
        set -l jira_key (string match -r '[A-Z][A-Z0-9]+-[0-9]+' -- $pr_branch)
        set -l jira_status ""
        if test -n "$jira_key"
            set -l idx (contains -i -- $jira_key $jira_keys)
            test -n "$idx"; and set jira_status $jira_vals[$idx]
        end
        set -l jira_url ""
        if test -n "$jira_key" -a -n "$jira_server"
            set jira_url "$jira_server/browse/$jira_key"
        end

        # A PR needs attention if Copilot threads are open, CI is failing, or changes were requested.
        set -l needs 0
        if test "$count" -gt 0 2>/dev/null; or test "$ci_fail" -gt 0 2>/dev/null; or test "$review" = CHANGES_REQUESTED
            set needs 1
        end
        if test $needs -eq 1
            set found (math $found + 1)
        else
            set clean (math $clean + 1)
        end

        # Review label + colour, computed once and reused by pretty and slack modes.
        set -l review_text
        set -l review_color
        switch $review
            case APPROVED; set review_text approved; set review_color green
            case CHANGES_REQUESTED; set review_text "changes requested"; set review_color red
            case '*'; set review_text "review required"; set review_color yellow
        end

        # --- non-pretty modes accumulate, then emit after the loop ---
        if test "$mode" = json
            # Tab-joined record; jq builds the object (values never contain tabs).
            set -a json_rows (string join \t $pr_num $pr_title $pr_url $pr_branch \
                $review $jira_key $jira_status $jira_url $count $ci_pass $ci_fail $ci_pend $parts[8])
            continue
        else if test "$mode" = slack
            # Status pieces, only the noteworthy ones, joined with " · ".
            set -l bits $review_text
            if test -n "$jira_key"
                if test -n "$jira_status"
                    set -a bits "$jira_key $jira_status"
                else
                    set -a bits "$jira_key"
                end
            end
            if test "$ci_fail" -gt 0 2>/dev/null
                set -a bits "CI ✗$ci_fail"
            else if test "$ci_pend" -gt 0 2>/dev/null
                set -a bits "CI ●$ci_pend"
            end
            if test "$count" -gt 0 2>/dev/null
                set -a bits "$count Copilot"
            end
            set -a slack_lines "• *$pr_title* — $pr_url — "(string join " · " $bits)
            continue
        end

        # --- pretty (default) terminal rendering ---
        if test $needs -eq 1
            set_color yellow; printf "  ●"; set_color normal
            set_color --bold white; printf " #$pr_num"; set_color normal
        else
            set_color green; printf "  ✓"; set_color normal
            set_color --bold $dim; printf " #$pr_num"; set_color normal
        end
        set_color normal; echo "  $pr_title"

        # Detail line: copilot · ci · review · jira
        printf "     "
        if test "$count" -gt 0 2>/dev/null
            set_color red; printf "copilot %s unresolved" $count; set_color normal
        else
            set_color $dim; printf "copilot clean"; set_color normal
        end

        set_color $dim; printf "  ·  "; set_color normal
        if test (math $ci_pass + $ci_fail + $ci_pend) -eq 0
            set_color $dim; printf "ci none"; set_color normal
        else
            set_color $dim; printf "ci "; set_color normal
            set_color green; printf "✓%s" $ci_pass; set_color normal
            if test "$ci_fail" -gt 0 2>/dev/null
                set_color red; printf " ✗%s" $ci_fail; set_color normal
            end
            if test "$ci_pend" -gt 0 2>/dev/null
                set_color yellow; printf " ●%s" $ci_pend; set_color normal
            end
        end

        set_color $dim; printf "  ·  "; set_color normal
        set_color $review_color; printf "%s" $review_text; set_color normal

        if test -n "$jira_key"
            set_color $dim; printf "  ·  "; set_color normal
            set -l jira_text
            if test -n "$jira_status"
                switch (string lower -- $jira_status)
                    case 'done' 'closed' 'resolved'
                        set_color green
                    case '*progress*' '*review*' '*test*'
                        set_color cyan
                    case '*'
                        set_color yellow
                end
                set jira_text "$jira_key $jira_status"
            else
                set_color $dim
                set jira_text "$jira_key ?"
            end
            # Click-to-open via an OSC 8 hyperlink when the Jira base URL is known
            # (Ghostty, iTerm2, etc. support it; other terminals show plain text).
            if test -n "$jira_url"
                printf '\e]8;;%s\a%s\e]8;;\a' $jira_url $jira_text
            else
                printf '%s' $jira_text
            end
            set_color normal
        end
        echo ""

        # Labels on their own indented line. Attention labels stand out;
        # the ready-for-review label is greened; everything else stays dim.
        if test -n "$parts[8]"
            printf "     "
            set -l i 0
            for label in $pr_labels
                set i (math $i + 1)
                if test $i -gt 1
                    set_color $dim; printf "  ·  "; set_color normal
                end
                switch (string lower -- $label)
                    case '*blocked*' '*do not merge*' '*do-not-merge*' '*hold*' '*wip*'
                        set_color red
                    case '*ready for review*' '*ready-for-review*'
                        set_color green
                    case '*'
                        set_color magenta
                end
                printf "%s" $label; set_color normal
            end
            echo ""
        end
    end

    # Nothing survived the filter.
    if test (math $found + $clean) -eq 0
        switch $mode
            case json
                echo "[]"
            case slack
                echo "No open PRs match \"$filter\" in $repo."
            case '*'
                set_color yellow; echo "  No open PRs match \"$filter\"."; set_color normal
        end
        return 0
    end

    # --- emit accumulated json/slack payloads ---
    if test "$mode" = json
        printf '%s\n' $json_rows | jq -R -s '
            split("\n") | map(select(length > 0)) | map(split("\t")) | map({
                number: (.[0] | tonumber),
                title: .[1],
                url: .[2],
                branch: .[3],
                reviewDecision: ((.[4] | select(. != "")) // null),
                jira: (if .[5] == "" then null else {
                    key: .[5],
                    status: ((.[6] | select(. != "")) // null),
                    url: ((.[7] | select(. != "")) // null)
                } end),
                copilotUnresolved: (.[8] | tonumber),
                checks: { passed: (.[9] | tonumber), failed: (.[10] | tonumber), pending: (.[11] | tonumber) },
                labels: (if .[12] == "" then [] else (.[12] | split(",")) end)
            })'
        return 0
    else if test "$mode" = slack
        echo "*PRs needing review — $repo*  ($found need attention, $clean clean)"
        printf '%s\n' $slack_lines
        return 0
    end

    # --- pretty summary ---
    echo ""
    if test $found -eq 0
        set_color --bold green; echo "  All clear — no PRs need attention."; set_color normal
    else
        set_color --bold red; printf "  $found PR(s) need attention"; set_color normal
        set_color $dim; echo "  ($clean clean)"; set_color normal
    end
end
