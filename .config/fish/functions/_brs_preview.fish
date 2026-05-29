function _brs_preview --argument branch
    set_color --bold white
    echo "  $branch"
    set_color normal

    set -f last (git log -1 --format='%ar by %an' $branch 2>/dev/null)
    set_color brblack
    echo "  $last"
    set_color normal
    echo ""

    # PR and Jira up top so they're visible without scrolling
    set -f pr (gh pr view $branch --json title,state,url 2>/dev/null)
    if test -n "$pr"
        set -f title (echo $pr | jq -r '.title')
        set -f state (echo $pr | jq -r '.state')
        set -f url (echo $pr | jq -r '.url')
        switch $state
            case OPEN
                set_color green
                set -f icon ●
            case MERGED
                set_color magenta
                set -f icon ✓
            case CLOSED
                set_color red
                set -f icon ✕
        end
        echo "  $icon $title"
        set_color normal
        set_color brblack
        echo "  $url"
        set_color normal
    end

    set -f jira_key (string match -r '(?:DLOS|LOSIMP|FLYWL|YELHAM)-[0-9]+' $branch)
    if test -n "$jira_key"
        set_color brblack
        echo "  https://summitgrp.atlassian.net/browse/$jira_key"
        set_color normal
    end

    set -f wt_path (git worktree list --porcelain 2>/dev/null \
        | awk -v b="refs/heads/$branch" '
            /^$/ { block++ }
            block >= 1 && /^worktree / { path = $2 }
            block >= 1 && $0 == "branch " b { print path }
        ')
    if test -n "$wt_path"
        set_color yellow
        echo "  󰙅 $wt_path"
        set_color normal
    end

    set -f base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$base_branch"
        set base_branch develop
    end

    echo ""
    set_color --bold cyan
    echo "  COMMITS AHEAD OF $base_branch"
    set_color normal
    set -f commits (git log --oneline --color=always origin/$base_branch..$branch 2>/dev/null)
    if test (count $commits) -gt 0
        for line in $commits[1..10]
            echo "  $line"
        end
    else
        set_color brblack
        echo "  (none)"
        set_color normal
    end
    echo ""

    set_color --bold cyan
    echo "  CHANGED FILES"
    set_color normal
    set -f files (git diff --name-only origin/$base_branch...$branch 2>/dev/null)
    set -f total (count $files)
    if test $total -gt 0
        for f in $files[1..30]
            echo "  $f"
        end
        if test $total -gt 30
            set_color brblack
            echo "  ... and "(math $total - 30)" more"
            set_color normal
        end
    else
        set_color brblack
        echo "  (none)"
        set_color normal
    end
end
