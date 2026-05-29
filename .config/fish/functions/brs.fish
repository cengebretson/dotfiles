function brs --description "Browse local branches with fzf"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'brs: not in a git repository.' >&2
        return 1
    end

    set -f result (_brs_list \
        | _fzf_wrapper \
            --ansi \
            --delimiter='\t' \
            --with-nth=2 \
            --expect=ctrl-p \
            --bind 'ctrl-j:execute(_brs_open_jira {1})' \
            --bind 'alt-d:execute(_brs_delete_branch {1})+reload(_brs_list)' \
            --bind 'alt-D:execute(_brs_force_delete_branch {1})+reload(_brs_list)' \
            --prompt="Branch> " \
            --preview='_brs_preview {1}' \
            --preview-window='right:55%:wrap' \
            --header="checkout(↵) | PR(⌃p) | Jira(⌃j) | delete(⌥d) | force delete(⌥D)"
    )

    test (count $result) -eq 0; and return

    set -f key $result[1]
    set -f branch (string split \t $result[2])[1]

    test -z "$branch"; and return

    if test "$key" = ctrl-p
        gh pr view $branch --web
    else
        set -f wt_path (git worktree list --porcelain 2>/dev/null \
            | awk -v b="refs/heads/$branch" '
                /^$/ { block++ }
                block >= 1 && /^worktree / { path = $2 }
                block >= 1 && $0 == "branch " b { print path }
            ')
        if test -n "$wt_path"
            if test -n "$TMUX"
                tmux new-window -c "$wt_path"
            else
                echo "Worktree: $wt_path"
            end
        else
            git checkout $branch
        end
    end
end
