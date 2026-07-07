function codex --wraps=codex --description 'Codex with clean tmux window name'
    if set -q TMUX
        tmux rename-window "codex"
        tmux set-window-option automatic-rename off
    end
    command codex $argv
    set -l st $status
    if set -q TMUX
        tmux set-window-option automatic-rename on
    end
    return $st
end
