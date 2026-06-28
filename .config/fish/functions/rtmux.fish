function rtmux --description 'Pick and attach to a tmux session on a Tailscale peer via fzf'
    # Lists tmux sessions across online macOS/Linux machines on the tailnet and
    # attaches to the one you pick. The local machine and non-tmux peers (iOS,
    # Mullvad exit nodes) are skipped. Each host also gets a "[+ new session]"
    # entry so you can start a fresh session anywhere. SSH user defaults to
    # $USER; override with `rtmux -u <user>` or per-host in ~/.ssh/config.
    #
    # Run `rtmux --doctor` to diagnose why it is not working.

    argparse h/help d/doctor 'u/user=' -- $argv
    or return 1
    if set -q _flag_help
        printf 'Usage: rtmux [-u user]\n'
        printf '       rtmux --doctor      diagnose connectivity\n'
        printf '  Pick a remote tmux session on a Tailscale peer and attach to it.\n'
        return 0
    end

    set -l ssh_user $USER
    set -q _flag_user; and set ssh_user $_flag_user

    if set -q _flag_doctor
        _rtmux_doctor $ssh_user
        return $status
    end

    for tool in tailscale fzf jq ssh
        if not command -q $tool
            printf 'rtmux: %s not found in PATH (try `rtmux --doctor`)\n' $tool >&2
            return 1
        end
    end

    set -l peers (_rtmux_peers)
    if test -z "$peers"
        printf 'rtmux: no online macOS/Linux peers on the tailnet (try `rtmux --doctor`)\n' >&2
        return 1
    end

    # Build fzf rows. Each row is three tab-separated fields:
    #   ssh-target <TAB> session-name (or __new__) <TAB> display text
    # fzf shows only the display column; we recover target + session afterward.
    set -l rows
    for peer in $peers
        set -l target (string split -f1 \t -- $peer)
        set -l label (string split -f2 \t -- $peer)
        for line in (ssh -o ConnectTimeout=5 -o BatchMode=yes $ssh_user@$target \
                "tmux list-sessions -F '#{session_name}\t#{session_windows}w#{?session_attached,\t(attached),}'" 2>/dev/null)
            set -l name (string split -f1 \t -- $line)
            set -l meta (string split -m1 -f2 \t -- $line)
            set -a rows (printf '%s\t%s\t%-12s %-20s %s' $target $name $label $name $meta)
        end
        set -a rows (printf '%s\t%s\t%-12s %s' $target __new__ $label '[+ new session]')
    end

    set -l pick (printf '%s\n' $rows \
        | fzf --delimiter \t --with-nth 3 \
            --prompt 'remote tmux> ' --height 40% --reverse \
            --header 'Select a remote tmux session')
    test -z "$pick"; and return 1

    set -l host (string split -f1 \t -- $pick)
    set -l sess (string split -f2 \t -- $pick)

    if test "$sess" = __new__
        # Attach-or-create a default session so repeated "new" picks reuse it.
        ssh -t $ssh_user@$host "tmux new-session -A -s main"
    else
        ssh -t $ssh_user@$host "tmux attach-session -t '$sess'"
    end
end

function _rtmux_doctor --argument-names ssh_user
    # Walks every failure point of rtmux in order, printing [ok]/[warn]/[fail].
    # Returns nonzero if any hard check failed.
    set -l failures 0

    printf '\nDependencies\n'
    for tool in tailscale fzf jq ssh
        if command -q $tool
            printf '[ok] %s found\n' $tool
        else
            printf '[fail] %s not in PATH\n' $tool
            set failures (math $failures + 1)
        end
    end

    printf '\nTailscale daemon\n'
    if not command -q tailscale
        printf '[fail] tailscale CLI missing; cannot check daemon\n'
        return 1
    end
    set -l ts_status (tailscale status 2>&1)
    if test $status -ne 0
        printf '[fail] `tailscale status` failed: %s\n' "$ts_status"
        printf '       Is Tailscale running and logged in? Try the menu-bar app or `tailscale up`.\n'
        set failures (math $failures + 1)
    else
        printf '[ok] tailnet reachable\n'
    end

    printf '\nSSH agent\n'
    set -l ids (ssh-add -l 2>/dev/null)
    if test $status -eq 0; and test -n "$ids"
        printf '[ok] %d identity(ies) loaded in agent\n' (count $ids)
    else
        printf '[warn] no identities in ssh-agent; key auth will fail unless you use\n'
        printf '       Tailscale SSH (`tailscale up --ssh` on the target) or load a key\n'
        printf '       (`ssh-add --apple-use-keychain`).\n'
    end

    printf '\nPeers\n'
    set -l peers (_rtmux_peers)
    if test -z "$peers"
        printf '[fail] no online macOS/Linux peers found\n'
        printf '       `tailscale status` shows them as offline, or they run a non-tmux OS.\n'
        printf '\n%d hard failure(s)\n' (math $failures + 1)
        return 1
    end
    printf '[ok] %d candidate peer(s) (ssh user: %s)\n' (count $peers) $ssh_user

    printf '\nPer-peer reachability\n'
    for peer in $peers
        set -l target (string split -f1 \t -- $peer)
        set -l label (string split -f2 \t -- $peer)
        printf '  %s (%s)\n' $label $target

        # Non-interactive SSH: this is exactly how session listing authenticates.
        ssh -o ConnectTimeout=5 -o BatchMode=yes $ssh_user@$target true 2>/dev/null
        if test $status -ne 0
            printf '  [warn] non-interactive SSH failed; sessions will not be listed.\n'
            printf '         Enable Tailscale SSH or add key auth for %s@%s.\n' $ssh_user $target
            printf '         (The "[+ new session]" entry still works interactively.)\n'
            continue
        end
        printf '  [ok] SSH ok\n'

        if not ssh -o ConnectTimeout=5 -o BatchMode=yes $ssh_user@$target \
                "command -v tmux >/dev/null 2>&1"
            printf '  [warn] tmux not found on remote PATH\n'
            continue
        end
        set -l n (ssh -o ConnectTimeout=5 -o BatchMode=yes $ssh_user@$target \
            "tmux list-sessions 2>/dev/null | wc -l | tr -d ' '")
        printf '  [ok] tmux present, %s running session(s)\n' $n
    end

    printf '\n%d hard failure(s)\n' $failures
    test $failures -eq 0
end
