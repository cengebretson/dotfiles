function coral --description "Browse local branches with fzf"
    _coral_load_config

    if test (count $argv) -gt 0
        switch $argv[1]
            case --doctor
                _coral_doctor
                return $status
            case --version
                _coral_version
                return 0
            case --slack
                _coral_slack $argv[2..]
                return $status
        end
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'coral: not in a git repository.' >&2
        return 1
    end

    if not functions -q _fzf_wrapper
        echo 'coral: _fzf_wrapper not found — install fzf.fish (https://github.com/PatrickF1/fzf.fish)' >&2
        return 1
    end

    # In tmux: execute-silent + popup keeps fzf visible; reload triggered via --listen.
    # Outside tmux: execute (blocking) with inline +reload.
    if test -n "$TMUX"
        set -f force_bind 'alt-D:execute-silent(_coral_run_delete {1} force $FZF_PORT)'
        set -f rebase_bind 'alt-e:execute-silent(_coral_run_rebase {1} $FZF_PORT)'
        set -f extra_flags --listen
    else
        set -f force_bind 'alt-D:execute(_coral_force_delete_branch {1})+reload(_coral_list)'
        set -f rebase_bind 'alt-e:execute(_coral_rebase {1})+reload(_coral_list)'
        set -f extra_flags
    end

    set -f query_flags
    if test (count $argv) -gt 0
        set -f query_flags --query $argv[1]
    end

    set -f preview_toggle 'ctrl-p:toggle-preview'

    set -f jira_flags --bind 'ctrl-j:execute(_coral_open_jira {1})'
    set -f header "checkout(↵) | PR(⌃o) | Jira(⌃j) | preview(⌃p) | rebase(⌥e) | delete(⌥D) | refresh(⌥r)"

    # Strip input-border and list-border from global FZF_DEFAULT_OPTS — coral owns its layout.
    set -lx FZF_DEFAULT_OPTS (string replace --regex --all -- '--(?:input|list)-border\S*' '' "$FZF_DEFAULT_OPTS")

    set -f result (_coral_list \
        | _fzf_wrapper \
            $extra_flags \
            $query_flags \
            --ansi \
            --layout=default \
            --border=none \
            --input-border=none \
            --list-border=none \
            --info=inline-right \
            --delimiter='\t' \
            --with-nth=2 \
            --bind $preview_toggle \
            --bind 'ctrl-o:execute(_coral_open_pr {1})' \
            $jira_flags \
            --bind $force_bind \
            --bind 'alt-r:execute(_coral_clear_cache)+reload(_coral_list)' \
            --bind $rebase_bind \
            --prompt="Branch> " \
            --preview='_coral_preview {1}' \
            --preview-window='right:55%:wrap:border-left' \
            --header=$header
    )

    test (count $result) -eq 0; and return

    set -f branch (string split \t $result[1])[1]

    test -z "$branch"; and return

    set -f wt_path (_coral_worktree_path "$branch")
    if test -n "$wt_path"
        if test -n "$TMUX"
            tmux new-window -c "$wt_path"
        else
            echo "Worktree: $wt_path"
        end
    else
        git checkout "$branch"
        or echo "coral: could not check out '$branch'" >&2
    end
end
