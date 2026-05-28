function brs --description "Browse local branches: ENTER checkout, CTRL-P open PR, CTRL-J open Jira"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'brs: not in a git repository.' >&2
        return 1
    end

    set -f base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$base_branch"
        set base_branch develop
    end

    # Fetch all open PR branch names in one call — avoids per-branch network hits
    set -f pr_entries (gh pr list --json headRefName,state --limit 200 2>/dev/null \
        | jq -r '.[] | .headRefName + "=" + .state' 2>/dev/null)

    set -f current (git branch --show-current 2>/dev/null)

    # Branch name is always the first whitespace-separated token — fzf strips ANSI for
    # field boundaries when --ansi is set, so bold on the current branch line is safe
    set -f lines
    for branch in (git branch --sort=-committerdate --format='%(refname:short)' \
                   | grep -vE "^($base_branch|main|master)"'$')
        set -f age (git log -1 --format='%ar' $branch 2>/dev/null)
        set -f pr_line (printf '%s\n' $pr_entries | grep -E "^$branch=")

        if test -n "$pr_line"
            set -f pr_status (string replace -r '^[^=]+=' '' $pr_line)
            set -f suffix (printf '\e[32m●\e[0m  %s' $age)
        else
            set -f suffix (printf '%-10s  %s' '' $age)
        end

        if test "$branch" = "$current"
            set -f display (printf '\e[1m%-65s  %s\e[0m' $branch $suffix)
        else
            set -f display (printf '%-65s  %s' $branch $suffix)
        end

        set -f --append lines $display
    end

    set -f result (printf '%s\n' $lines \
        | _fzf_wrapper \
            --ansi \
            --expect=ctrl-p \
            --bind 'ctrl-j:execute(_brs_open_jira {1})' \
            --prompt="Branch> " \
            --preview='_brs_preview {1}' \
            --preview-window='right:55%:wrap' \
            --header='ENTER: checkout   CTRL-P: open PR   CTRL-J: open Jira'
    )

    test (count $result) -eq 0; and return

    set -f key $result[1]
    set -f branch (string split ' ' $result[2])[1]

    test -z "$branch"; and return

    if test "$key" = ctrl-p
        gh pr view $branch --web
    else
        git checkout $branch
    end
end
