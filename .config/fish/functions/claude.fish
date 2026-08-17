function claude --wraps=claude --description 'Claude Code with clean tmux window name'
    set -l automatic_rename
    if set -q TMUX
        set automatic_rename (tmux show-window-options -v automatic-rename 2>/dev/null)
        if test "$automatic_rename" = on
            tmux rename-window claude
            tmux set-window-option automatic-rename off
        end
    end
    # Claim the pane for this launch so tmux-attention can tell a live marker
    # from one a killed agent left behind. claim also clears whatever marker the
    # pane inherited, and the id reaches the agent's hooks via the environment —
    # which is why it has to happen here rather than in a hook.
    #
    # The helpers come from `tmux-attention shell-init fish` in config.fish. If
    # that did not load, or we are outside tmux, the claim returns nothing and
    # the launch proceeds untouched.
    set -l attention_owner
    if functions -q tmux_attention_claim
        set attention_owner (tmux_attention_claim claude)
        test -n "$attention_owner"; and set -x TMUX_ATTENTION_OWNER $attention_owner
    end

    command claude $argv
    set -l st $status

    if test -n "$attention_owner"
        tmux_attention_disown
    end
    if set -q TMUX; and test "$automatic_rename" = on
        tmux set-window-option automatic-rename "$automatic_rename"
    end
    return $st
end
