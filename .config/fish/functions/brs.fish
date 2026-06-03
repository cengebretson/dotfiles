function brs --description "Browse local branches with fzf"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'brs: not in a git repository.' >&2
        return 1
    end

    # In tmux: execute-silent + popup keeps fzf visible; reload triggered via --listen.
    # Outside tmux: execute (blocking) with inline +reload.
    if test -n "$TMUX"
        set -f delete_bind 'alt-d:execute-silent(_brs_run_delete {1} "" $FZF_PORT)'
        set -f force_bind  'alt-D:execute-silent(_brs_run_delete {1} force $FZF_PORT)'
        set -f extra_flags --listen
    else
        set -f delete_bind 'alt-d:execute(_brs_delete_branch {1})+reload(_brs_list)'
        set -f force_bind  'alt-D:execute(_brs_force_delete_branch {1})+reload(_brs_list)'
        set -f extra_flags
    end

    set -f result (_brs_list \
        | _fzf_wrapper \
            $extra_flags \
            --ansi \
            --delimiter='\t' \
            --with-nth=2 \
            --expect=ctrl-p \
            --bind 'ctrl-j:execute(_brs_open_jira {1})' \
            --bind $delete_bind \
            --bind $force_bind \
            --bind 'ctrl-r:execute(rm -f /tmp/brs_pr_*.cache)+reload(_brs_list)' \
            --prompt="Branch> " \
            --preview='_brs_preview {1}' \
            --preview-window='right:55%:wrap' \
            --header="checkout(↵) | PR(⌃p) | Jira(⌃j) | delete(⌥d) | force delete(⌥D) | refresh(⌃r)"
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
