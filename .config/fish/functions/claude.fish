function claude --wraps=claude --description 'Claude Code with clean tmux window name'
    if set -q TMUX
        tmux rename-window "claude"
        tmux set-window-option automatic-rename off
    end
    command claude $argv
    if set -q TMUX
        tmux set-window-option automatic-rename on
    end
end
