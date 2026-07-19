function claude --wraps=claude --description 'Claude Code with clean tmux window name'
    set -l automatic_rename
    if set -q TMUX
        set automatic_rename (tmux show-window-options -v automatic-rename 2>/dev/null)
        tmux rename-window claude
        if test -n "$automatic_rename"
            tmux set-window-option automatic-rename off
        end
    end
    command claude $argv
    set -l st $status
    if set -q TMUX; and test -n "$automatic_rename"
        tmux set-window-option automatic-rename "$automatic_rename"
    end
    return $st
end
