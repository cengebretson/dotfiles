function codex --wraps=codex --description 'Codex with clean tmux window name'
    set -l automatic_rename
    if set -q TMUX
        set automatic_rename (tmux show-window-options -v automatic-rename 2>/dev/null)
        if test "$automatic_rename" = on
            tmux rename-window codex
            tmux set-window-option automatic-rename off
        end
    end
    # See claude.fish: same per-launch claim, so a marker left by a killed agent
    # is cleared on the next launch and its late hooks stop matching.
    set -l attention_owner
    if functions -q tmux_attention_claim
        set attention_owner (tmux_attention_claim codex)
        test -n "$attention_owner"; and set -x TMUX_ATTENTION_OWNER $attention_owner
    end

    command codex $argv
    set -l st $status

    if test -n "$attention_owner"
        tmux_attention_disown
    end
    if set -q TMUX; and test "$automatic_rename" = on
        tmux set-window-option automatic-rename "$automatic_rename"
    end
    return $st
end
