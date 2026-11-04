function codex --wraps=codex --description 'Codex with clean tmux window name'
    # The shared daemon inherits its first client's pane identity (Codex #48500).
    # Keep interactive tmux sessions local; leave utility/remote commands alone.
    set -l standalone false
    if set -q TMUX; and test -n "$TMUX"
        set standalone true
        for arg in $argv
            switch $arg
                case --no-daemon --remote '--remote=*' agents queue app-server remote-control exec review login logout mcp plugin app completion update doctor debug features apply archive delete unarchive migrate-rollouts migrate-nfs-db cloud exec-server
                    set standalone false
                    break
            end
        end
    end
    if test "$standalone" = true
        _agent_tmux_run codex --no-daemon $argv
        return $status
    end
    _agent_tmux_run codex $argv
end
