function copilot-pr-report --description "List open PRs with unresolved Copilot review threads"
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

    set -l owner (string split / $repo)[1]
    set -l reponame (string split / $repo)[2]

    set_color --bold cyan; echo "󰊤  Copilot PR Report"; set_color normal
    set_color brblack; echo "   $repo · @$me"; set_color normal
    echo ""

    set -l pr_lines (gh api "repos/$repo/pulls?state=open&per_page=100" \
        --jq ".[] | select(.user.login == \"$me\") | [(.number | tostring), .title] | @tsv" 2>/dev/null)

    if test -z "$pr_lines"
        set_color yellow; echo "  No open PRs found."; set_color normal
        return 0
    end

    set -l found 0
    set -l clean 0

    for line in $pr_lines
        set -l parts (string split \t $line)
        set -l pr_num $parts[1]
        set -l pr_title $parts[2]

        set -l count (gh api graphql \
            -F owner=$owner -F repo=$reponame -F number=$pr_num \
            -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved comments(first:5){nodes{author{login}}}}}}}}' \
            --jq '[.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false and (.comments.nodes[].author.login|ascii_downcase|contains("copilot")))]|length' 2>/dev/null)

        if test -n "$count" -a "$count" -gt 0 2>/dev/null
            set_color yellow; printf "  ●"; set_color normal
            set_color --bold white; printf " #$pr_num"; set_color normal
            set_color red; printf " ($count unresolved)"; set_color normal
            set_color normal; echo "  $pr_title"
            set found (math $found + 1)
        else
            set_color green; printf "  ✓"; set_color normal
            set_color brblack; printf " #$pr_num"; set_color normal
            set_color brblack; echo "  $pr_title"; set_color normal
            set clean (math $clean + 1)
        end
    end

    echo ""
    if test $found -eq 0
        set_color --bold green; echo "  All clear — no unresolved Copilot threads."; set_color normal
    else
        set_color --bold red; printf "  $found PR(s) need attention"; set_color normal
        set_color brblack; echo "  ($clean clean)"; set_color normal
    end
end
