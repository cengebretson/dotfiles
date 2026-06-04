function _coral_preview --argument-names branch
    set -f upstream (_coral_upstream "$branch"); or return 1

    set -f jira_domain $CORAL_JIRA_DOMAIN

    set_color --bold white
    echo "  $branch"
    set_color normal

    set -f last (git log -1 --format='%cr by %an' "$branch" 2>/dev/null)
    set_color brblack
    echo "  $last"
    set_color normal

    set -f ahead (git rev-list --count "$upstream..$branch" 2>/dev/null)
    set -f behind (git rev-list --count "$branch..$upstream" 2>/dev/null)
    if test -n "$ahead" -a -n "$behind"
        if test "$ahead" = 0 -a "$behind" = 0
            set_color brblack
            echo "  up to date with $upstream"
        else
            set_color cyan
            printf '  ↑%s ahead' $ahead
            if test "$behind" -gt 0
                set_color yellow
                printf '  ↓%s behind' $behind
            end
            echo ''
        end
        set_color normal
    end
    # PR and Jira up top so they're visible without scrolling
    set -f pr (gh pr view "$branch" --json title,state,url,labels 2>/dev/null)
    if test -n "$pr"; and echo $pr | jq -e . >/dev/null 2>&1
        set -f pr_parsed (echo $pr | jq -r '[.title, .state, .url] | join("\t")' 2>/dev/null)
        set -f title (string split \t $pr_parsed)[1]
        set -f state (string split \t $pr_parsed)[2]
        set -f url (string split \t $pr_parsed)[3]
        set -f labels (echo $pr | jq -r '.labels[].name' 2>/dev/null)
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
        if test (count $labels) -gt 0
            printf '  '
            for label in $labels
                set_color '1e1e2e'; set_color --background 'fab387'
                printf ' %s ' $label
                set_color normal
                printf ' '
            end
            echo ''
        end
        set_color brblack
        echo "  $url"
        set_color normal
    end

    if test -n "$jira_domain"
        set -f jira_key (string match -r (_coral_jira_pattern) "$branch")
        if test -n "$jira_key"
            set_color brblack
            echo "  https://$jira_domain/browse/$jira_key"
            set_color normal
        end
    end

    set -f wt_path (_coral_worktree_path "$branch")
    if test -n "$wt_path"
        set_color yellow
        echo "  󰙅 $wt_path"
        set_color normal
    end

    echo ""
    set_color --bold cyan
    echo "  COMMITS AHEAD OF $upstream"
    set_color normal
    set -f commits (git log --oneline --color=always "$upstream..$branch" 2>/dev/null)
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
    set -f files (git diff --name-only "$upstream...$branch" 2>/dev/null)
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
