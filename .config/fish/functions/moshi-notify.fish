function __moshi_refresh_paired --description 'Refresh the cached @moshi_paired tmux option'
    # moshi-hook status touches Keychain (slow), so the tmux status script reads
    # this cached option instead of querying every 15s refresh. Refresh it here
    # whenever daemon/pairing state might have changed.
    if moshi-hook status 2>/dev/null | grep -qE '^status:[[:space:]]+paired'
        tmux set -g @moshi_paired yes 2>/dev/null
    else
        tmux set -g @moshi_paired no 2>/dev/null
    end
end

function moshi-notify --description 'Toggle/inspect Moshi agent-hook pushes'
    # NOTE: `brew services` refuses to run under tmux, so every brew services call
    # is wrapped in `env -u TMUX` to make start/stop/list work from inside a session.
    switch "$argv[1]"
        case off quiet mute
            if env -u TMUX brew services stop moshi-hook
                echo "Moshi notifications OFF"
            end
            __moshi_refresh_paired
            tmux refresh-client -S 2>/dev/null
        case on loud
            if env -u TMUX brew services start moshi-hook
                echo "Moshi notifications ON"
            end
            __moshi_refresh_paired
            tmux refresh-client -S 2>/dev/null
        case toggle
            # Flip based on whether the daemon is currently running (pgrep is instant).
            if pgrep -f "moshi-hook serve" >/dev/null 2>&1
                moshi-notify off
            else
                moshi-notify on
            end
        case status '' '*'
            if env -u TMUX brew services list | grep -q '^moshi-hook.*started'
                echo "daemon:  ON (running)"
            else
                echo "daemon:  OFF (stopped)"
            end
            moshi-hook status 2>/dev/null | grep -E '^status:' | string replace 'status:' 'pairing:'
            __moshi_refresh_paired
    end
end
