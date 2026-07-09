function pr-report --description "List your open PRs with Copilot threads, CI/review status, and Jira status"
    # Flags: --json (machine-readable) / --slack (paste-into-Slack). Remaining args
    # are an optional filter matched case-insensitively against title, branch, labels.
    argparse h/help j/json s/slack short -- $argv
    or return

    if set -q _flag_help
        set_color --bold cyan; echo "pr-report"; set_color normal
        echo "List your open PRs with unresolved Copilot threads, CI/review status, and Jira status."
        echo
        set_color --bold white; echo "USAGE"; set_color normal
        echo "    pr-report [--slack | --json] [FILTER...]"
        echo
        set_color --bold white; echo "OPTIONS"; set_color normal
        echo "    -s, --slack   Lean plain-text list to paste into Slack (title, link, review status, labels)."
        echo "    -j, --json    Machine-readable JSON array (pipe into jq, a webhook, etc.)."
        echo "        --short   One line per PR: marker + #number + title (Jira key links to the issue) + [labels]."
        echo "    -h, --help    Show this help."
        echo "    (no flag)     Pretty terminal report — the default."
        echo
        set_color --bold white; echo "FILTER"; set_color normal
        echo "    Space-separated terms, matched case-insensitively against each PR's"
        echo "    title + branch + labels + review status (approved / review required /"
        echo "    changes requested) + state (attention / waiting / approved)."
        echo "    Every term must match (AND); prefix a term with '!' to exclude it."
        echo "    Works in any mode and any position."
        echo
        set_color --bold white; echo "EXAMPLES"; set_color normal
        echo "    pr-report                              # full report, current repo"
        echo "    pr-report login                        # only PRs matching \"login\""
        echo "    pr-report '!approved'                  # everything not yet approved"
        echo "    pr-report 'ready for review !approved' # that label, but not approved"
        echo "    pr-report --json | jq '.[].url'        # just the PR URLs"
        echo
        set_color --bold white; echo "NOTES"; set_color normal
        printf '    • Marker: ◆ draft · ● needs your action · \U000f0349 awaiting reviewer · ✓ approved  (• bullet list in --slack).\n'
        echo "    • Runs against the current repo's GitHub remote (needs gh auth)."
        echo "    • Jira status/links are optional — they appear only when acli is authenticated"
        echo "      (run 'acli jira auth login'). The Jira segment is a click-to-open link in supporting terminals."
        return 0
    end

    # Filter matches title + branch + labels + GitHub review status. Split into
    # space-separated terms: each must match (AND); a term prefixed with '!'
    # excludes. e.g. `pr-report 'ready for review !approved'` = has those words
    # AND is not approved. `pr-report '!wip'` = everything not matching "wip".
    set -l filter (string lower -- "$argv")
    set -l filter_inc
    set -l filter_exc
    for term in (string split ' ' -- $filter)
        test -z "$term"; and continue
        if string match -q '!*' -- "$term"
            set -a filter_exc (string sub -s 2 -- "$term")
        else
            set -a filter_inc $term
        end
    end
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

    # Jira is optional: only enrich rows when acli is installed AND authenticated.
    # `acli jira auth status` exits 0 only when a Jira site is authenticated.
    set -l jira_ok 0
    if command -q acli; and acli jira auth status >/dev/null 2>&1
        set jira_ok 1
    end

    # Jira base URL for click-to-open links — derived from the authenticated acli
    # site (e.g. "Site: venturesgo.atlassian.net"). Left empty when unknown so the
    # segment falls back to plain text.
    set -l jira_server ""
    if test $jira_ok -eq 1
        set -l site (acli jira auth status 2>/dev/null | string match -rg 'Site:\s*(\S+)')
        test -n "$site"; and set jira_server "https://$site"
    end

    # Decorative header is for humans only — keep it out of json/slack payloads.
    if test "$mode" = pretty
        set_color --bold cyan; echo "󰊤  PR Report"; set_color normal
        set_color $dim; echo "   $repo · @$me"; set_color normal
        if test -n "$filter"
            set_color $dim; echo "   filter: \"$filter\""; set_color normal
        end
        if test $jira_ok -eq 0
            set_color $dim; echo "   jira: not authenticated — run 'acli jira auth login' to add issue status"; set_color normal
        end
        echo ""
    end

    # ONE GraphQL call returns every open PR you authored with its url, review
    # decision, CI check rollup, labels, AND unresolved Copilot thread count. jq
    # reduces each PR to a TSV row so there are no per-PR calls. Field order:
    # 1 number  2 title  3 branch  4 reviewDecision  5 ci_pass  6 ci_fail
    # 7 ci_pend  8 labels(csv)  9 copilot_count  10 url  11 idle_days  12 comment_count  13 is_draft
    # 14 requested_reviewers(csv)
    # copilot_count = unresolved threads with a Copilot comment; comment_count =
    # unresolved threads with NO Copilot comment (human-only). They don't overlap.
    set -l pr_lines (gh api graphql -f q="repo:$repo is:pr is:open author:$me" \
        -f query='query($q:String!){search(query:$q,type:ISSUE,first:100){nodes{... on PullRequest{number title url headRefName reviewDecision updatedAt isDraft labels(first:20){nodes{name}} reviewRequests(first:20){nodes{requestedReviewer{__typename ... on User{login} ... on Bot{login} ... on Team{slug}}}} commits(last:1){nodes{commit{statusCheckRollup{contexts(first:100){nodes{__typename ... on CheckRun{status conclusion} ... on StatusContext{state}}}}}}} reviewThreads(first:100){nodes{isResolved comments(first:5){nodes{author{login}}}}}}}}}' \
        --jq '
            def cls:
              if .__typename == "CheckRun" then
                if .status != "COMPLETED" then "pending"
                elif ((.conclusion // "" | ascii_upcase) | . == "SUCCESS" or . == "NEUTRAL" or . == "SKIPPED") then "pass"
                elif ((.conclusion // "" | ascii_upcase) == "CANCELLED") then "ignored"
                else "fail" end
              else
                (.state // "" | ascii_upcase) as $s |
                if $s == "SUCCESS" then "pass"
                elif ($s == "PENDING" or $s == "EXPECTED") then "pending"
                else "fail" end
              end;
            .data.search.nodes[] | select(.number) |
            ([ (.commits.nodes[0].commit.statusCheckRollup.contexts.nodes // [])[] | cls ]) as $c |
            ([ .reviewThreads.nodes[] | select(.isResolved==false) ]) as $open |
            ([ $open[] | select(any(.comments.nodes[]; .author!=null and (.author.login|ascii_downcase|contains("copilot")))) ] | length) as $cop |
            (($open | length) - $cop) as $hum |
            ([.reviewRequests.nodes[]?.requestedReviewer | if .__typename == "Team" then .slug else .login end] | map(select(. != null)) | join(",")) as $req |
            [ (.number|tostring), .title, .headRefName, (.reviewDecision // ""),
              ([$c[]|select(.=="pass")]|length|tostring),
              ([$c[]|select(.=="fail")]|length|tostring),
              ([$c[]|select(.=="pending")]|length|tostring),
              ([.labels.nodes[]?.name] | join(",")),
              ($cop|tostring),
              .url,
              (((now - (.updatedAt | fromdateiso8601)) / 86400) | floor | tostring),
              ($hum|tostring),
              (.isDraft | tostring),
              $req
            ] | @tsv' 2>/dev/null)
    if test $status -ne 0
        set_color red; echo "error: GitHub API request failed — run 'gh auth status' to check token permissions" >&2; set_color normal
        return 1
    end

    if test -z "$pr_lines"
        _pr_report_none $mode "No open PRs in $repo." "No open PRs found."
        return 0
    end

    # Universal sort for every output mode:
    #   1. draft before open
    #   2. needs-attention before waiting before approved
    #   3. Jira key when present, then title
    # Fields: 2 title · 3 branch · 4 review · 6 ci_fail · 9 copilot ·
    # 12 comments · 13 draft · 14 requested reviewers.
    set -l sortable_lines
    for line in $pr_lines
        set -l p (string split \t $line)
        set -l draft_rank 1
        test "$p[13]" = true; and set draft_rank 0

        set -l status_rank 1
        if test "$p[9]" -gt 0 2>/dev/null; or test "$p[12]" -gt 0 2>/dev/null; or test "$p[6]" -gt 0 2>/dev/null; or test "$p[4]" = CHANGES_REQUESTED
            set status_rank 0
        else if test "$p[4]" = APPROVED; and test -z "$p[14]"
            set status_rank 2
        end

        set -l ticket (string match -r '[A-Z][A-Z0-9]+-[0-9]+' -- "$p[3]")
        test -n "$ticket"; or set ticket (string match -r '[A-Z][A-Z0-9]+-[0-9]+' -- "$p[2]")
        test -n "$ticket"; or set ticket "ZZZZ-999999"

        set -l ticket_prefix (string replace -r -- '-[0-9]+$' '' "$ticket")
        set -l ticket_number (string match -rg -- '-([0-9]+)$' "$ticket")
        set -l ticket_sort "$ticket_prefix-999999"
        if test -n "$ticket_number"
            set ticket_sort (printf '%s-%06d' "$ticket_prefix" "$ticket_number")
        end

        set -a sortable_lines (string join \t -- $draft_rank $status_rank (string lower -- "$ticket_sort") (string lower -- "$p[2]") $line)
    end
    set pr_lines (printf '%s\n' $sortable_lines | sort -t \t -k1,1n -k2,2n -k3,3 -k4,4 | cut -f5-)

    # Batch every branch's Jira key into ONE search query, then look statuses up in
    # the render loop — instead of one acli view per PR. Parallel arrays
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
            set -l rows (acli jira workitem search --jql "key in ("(string join , $keys)")" \
                --fields "key,status" --limit 100 --json 2>/dev/null \
                | jq -r '.[]? | [.key, (.fields.status.name // "")] | @tsv' 2>/dev/null)
            for r in $rows
                set -l p (string split \t $r)
                set -a jira_keys $p[1]
                set -a jira_vals $p[2]
            end
            # Safety net: one nonexistent key can make the JQL query fail. If the
            # batch came back empty despite having keys, fall back to resilient
            # per-key views so a single bad branch doesn't blank out every status.
            if test (count $jira_keys) -eq 0
                for k in $keys
                    set -l st (acli jira workitem view $k --fields "key,status" --json 2>/dev/null \
                        | jq -r '.fields.status.name // empty' 2>/dev/null)
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
        set -l idle_days $parts[11]
        test -n "$idle_days"; or set idle_days 0
        set -l comments $parts[12]
        test -n "$comments"; or set comments 0
        set -l is_draft $parts[13]
        test -n "$is_draft"; or set is_draft false
        set -l requested_reviewers $parts[14]

        # PR state drives the marker (computed before the filter so the filter can
        # match it):
        #   attention — needs YOUR action: open Copilot OR reviewer threads, failing CI, or changes requested
        #   approved  — clean and a reviewer approved
        #   waiting   — clean but still awaiting a reviewer (review required / no decision yet)
        set -l pr_state waiting
        if test "$count" -gt 0 2>/dev/null; or test "$comments" -gt 0 2>/dev/null; or test "$ci_fail" -gt 0 2>/dev/null; or test "$review" = CHANGES_REQUESTED
            set pr_state attention
        else if test "$review" = APPROVED; and test -z "$requested_reviewers"
            set pr_state approved
        end
        if test "$is_draft" = true
            set pr_state draft
        end

        # Review label + colour, reused by pretty/slack and searchable by the filter.
        set -l review_text
        set -l review_color
        switch $review
            case APPROVED; set review_text approved; set review_color green
            case CHANGES_REQUESTED; set review_text "changes requested"; set review_color red
            case '*'; set review_text "review required"; set review_color yellow
        end
        if test -n "$requested_reviewers"; and test "$is_draft" != true
            set review_text "re-review requested"
            set review_color yellow
        end

        # Filter: every include term must match and no exclude term may match,
        # against title + branch + labels + review status + state word.
        if test -n "$filter"
            set -l haystack (string lower -- "$pr_title $pr_branch $parts[8] $review_text $pr_state")
            set -l skip 0
            for term in $filter_inc
                string match -q -- "*$term*" $haystack; or set skip 1
            end
            for term in $filter_exc
                string match -q -- "*$term*" $haystack; and set skip 1
            end
            test $skip -eq 1; and continue
        end

        # Count toward the summary only once a PR has passed the filter.
        set -l needs 0
        test "$pr_state" = attention; and set needs 1
        if test $needs -eq 1
            set found (math $found + 1)
        else
            set clean (math $clean + 1)
        end

        # Jira key from the branch name, looked up in the batch table built above.
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

        # --- non-pretty modes accumulate, then emit after the loop ---
        if test "$mode" = json
            # Tab-joined record; jq builds the object (values never contain tabs).
            set -a json_rows (string join \t -- "$pr_num" "$pr_title" "$pr_url" "$pr_branch" \
                "$review" "$jira_key" "$jira_status" "$jira_url" "$count" "$ci_pass" "$ci_fail" "$ci_pend" "$parts[8]" "$idle_days" "$comments" "$is_draft" "$requested_reviewers")
            continue
        else if test "$mode" = slack
            # Lean entry: bullet list item with title, then link + GitHub review status,
            # then labels (if any). Plain text — Slack does not render *bold* on paste.
            # Use the literal • glyph: Slack only auto-converts "- " to a bullet when
            # typed, not when pasted, so a real bullet character shows reliably.
            set -l slack_review_text $review_text
            test "$is_draft" = true; and set slack_review_text "draft · $review_text"
            set -a slack_lines "• $pr_title" "    |  #$pr_num - $slack_review_text - $pr_url"
            test -n "$parts[8]"; and set -a slack_lines "    |  :label: "(string join " · " $pr_labels)
            continue
        end

        # --- pretty (default) terminal rendering ---
        # Marker: ◆ magenta = draft, ● yellow = needs action, 󰍉 blue = awaiting reviewer, ✓ green = approved.
        set -l num_color $dim
        switch $pr_state
            case draft
                set_color magenta; printf "  ◆"; set_color normal
                set num_color white
            case attention
                set_color yellow; printf "  ●"; set_color normal
                set num_color white
            case approved
                set_color green; printf "  ✓"; set_color normal
            case '*' # waiting on a reviewer
                set_color blue; printf '  \U000f0349'; set_color normal # nf-md-magnify
        end
        # PR number is a click-to-open OSC 8 hyperlink to the PR on GitHub.
        set_color --bold $num_color
        if test -n "$pr_url"
            printf ' \e]8;;%s\a#%s\e]8;;\a' $pr_url $pr_num
        else
            printf ' #%s' $pr_num
        end
        # --short: stay one line per PR. Hyperlink the leading Jira key *inside*
        # the title itself (the "FLYWL-1308" in "FLYWL-1308: …") instead of
        # appending a duplicate [KEY] tag, then add the GitHub labels in brackets.
        # Colours mirror the full report (Jira Atlassian-blue; labels keyed by
        # meaning) so a glance reads the same in either mode.
        if set -q _flag_short
            set_color normal; printf "  "
            if test -n "$jira_key" -a -n "$jira_url"; and string match -q -- "$jira_key*" "$pr_title"
                # Link only the key prefix; print the rest of the title verbatim.
                # Keep the title's normal colour — the OSC 8 link still makes it
                # clickable without recolouring it.
                set -l rest (string sub -s (math (string length -- $jira_key) + 1) -- "$pr_title")
                printf '\e]8;;%s\a%s\e]8;;\a%s' $jira_url $jira_key $rest
            else if test -n "$jira_key" -a -n "$jira_url"
                # Title doesn't lead with the key — fall back to a trailing link.
                printf "%s " $pr_title
                printf '\e]8;;%s\a[%s]\e]8;;\a' $jira_url $jira_key
            else
                printf "%s" $pr_title
            end
            for label in $pr_labels
                test -n "$label"; or continue
                _pr_report_label_color $label
                printf " [%s]" $label; set_color normal
            end
            echo ""
            continue
        end
        set_color normal; echo "  $pr_title"

        # Detail line — only segments that carry signal, joined by a dim " · ".
        # $pre holds the separator: empty before the first printed segment, then
        # "  ·  " thereafter, so optional segments never leave a dangling dot.
        printf "     "
        set -l pre ""

        # Unresolved threads — shown only when present (keeps clean PRs short).
        if test "$count" -gt 0 2>/dev/null
            set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
            set_color red; printf "%s copilot" $count; set_color normal
        end
        if test "$comments" -gt 0 2>/dev/null
            set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
            set -l noun comments; test "$comments" -eq 1; and set noun comment
            set_color red; printf "%s %s" $comments $noun; set_color normal
        end

        # CI rollup (always).
        set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
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

        # Review decision (always).
        set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
        set_color $review_color; printf "%s" $review_text; set_color normal

        # Jira (when the branch carries a key).
        if test -n "$jira_key"
            set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
            set_color 2684FF; printf '\U000f0e6f '; set_color normal # Atlassian-blue Jira clipboard glyph
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
            # Click-to-open via an OSC 8 hyperlink when the Jira base URL is known.
            if test -n "$jira_url"
                printf '\e]8;;%s\a%s\e]8;;\a' $jira_url $jira_text
            else
                printf '%s' $jira_text
            end
            set_color normal
        end

        # Idle since last activity — escalating colour when stale (always).
        set_color $dim; printf '%s' "$pre"; set_color normal; set pre "  ·  "
        if test "$idle_days" -gt 14 2>/dev/null
            set_color red
        else if test "$idle_days" -gt 7 2>/dev/null
            set_color yellow
        else
            set_color $dim
        end
        if test "$idle_days" -le 0 2>/dev/null
            printf "today"
        else
            printf "%sd idle" $idle_days
        end
        set_color normal
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
                _pr_report_label_color $label
                printf "%s" $label; set_color normal
            end
            echo ""
        end
    end

    # Nothing survived the filter.
    if test (math $found + $clean) -eq 0
        _pr_report_none $mode "No open PRs match \"$filter\" in $repo." "No open PRs match \"$filter\"."
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
                labels: (if .[12] == "" then [] else (.[12] | split(",")) end),
                idleDays: (.[13] | tonumber),
                reviewerThreads: (.[14] | tonumber),
                isDraft: (.[15] == "true"),
                requestedReviewers: (if .[16] == "" then [] else (.[16] | split(",")) end)
            })'
        return 0
    else if test "$mode" = slack
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

# Emit the mode-appropriate "nothing to show" payload: an empty JSON array,
# a plain sentence for Slack, or a yellow terminal line. Shared by the
# no-open-PRs and nothing-survived-the-filter exits.
function _pr_report_none --argument-names mode slack_msg pretty_msg
    switch $mode
        case json
            echo "[]"
        case slack
            echo $slack_msg
        case '*'
            set_color yellow; echo "  $pretty_msg"; set_color normal
    end
end

# Set the colour for a GitHub label by meaning: attention labels red,
# ready-for-review green, everything else magenta. Shared by the --short
# inline tags and the full report's label line so both read the same.
function _pr_report_label_color --argument-names label
    switch (string lower -- $label)
        case '*blocked*' '*do not merge*' '*do-not-merge*' '*hold*' '*wip*'
            set_color red
        case '*ready for review*' '*ready-for-review*'
            set_color green
        case '*'
            set_color magenta
    end
end
