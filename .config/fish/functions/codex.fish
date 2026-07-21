function codex --wraps=codex --description 'Codex with clean tmux window name'
    set -l automatic_rename
    if set -q TMUX
        set automatic_rename (tmux show-window-options -v automatic-rename 2>/dev/null)
        if test "$automatic_rename" = on
            tmux rename-window codex
            tmux set-window-option automatic-rename off
        end
    end
    command codex $argv
    set -l st $status
    if set -q TMUX; and test "$automatic_rename" = on
        tmux set-window-option automatic-rename "$automatic_rename"
    end
    return $st
end
