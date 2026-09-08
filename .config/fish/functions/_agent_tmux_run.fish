function _agent_tmux_run --description 'Run an agent with temporary tmux naming and pane ownership'
    set -l agent $argv[1]
    set -e argv[1]
    set -l automatic_rename
    if set -q TMUX
        set automatic_rename (tmux show-window-options -v automatic-rename 2>/dev/null)
        if test "$automatic_rename" = on
            tmux rename-window "$agent"
            tmux set-window-option automatic-rename off
        end
    end

    # The claim is scoped to this launch; manual window names stay untouched.
    set -l attention_owner
    if functions -q tmux_attention_claim
        set attention_owner (tmux_attention_claim "$agent")
        test -n "$attention_owner"; and set -fx TMUX_ATTENTION_OWNER "$attention_owner"
    end
    command $agent $argv
    set -l result $status

    if test -n "$attention_owner"
        tmux_attention_disown
    end
    if set -q TMUX; and test "$automatic_rename" = on
        tmux set-window-option automatic-rename "$automatic_rename"
    end
    return $result
end
