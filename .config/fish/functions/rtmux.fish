function rtmux --description 'Pick and attach to a tmux session on a Tailscale peer via fzf'
    # Lists tmux sessions across online macOS/Linux machines on the tailnet and
    # attaches to the one you pick. The local machine and non-tmux peers (iOS,
    # Mullvad exit nodes) are skipped. Each host also gets a "[+ new session]"
    # entry so you can start a fresh session anywhere. The SSH username is
    # resolved per host by your ssh config (so a `User` directive — e.g.
    # work-buddy=cengebretson in ~/.ssh/config.local — is honored); `rtmux -u
    # <user>` forces one user for every host.
    #
    # Run `rtmux --doctor` to diagnose why it is not working.
    #
    # Why plain `ssh` and not `tailscale ssh`: Tailscale is used only for peer
    # discovery (`tailscale status`) and MagicDNS addressing over the tailnet —
    # the connection itself is ordinary OpenSSH to each peer's macOS `sshd`
    # (Remote Login). The Mac App Store build of Tailscale is sandboxed and
    # cannot run the Tailscale SSH *server*, so `tailscale ssh` can't reach
    # those Macs; plain ssh over the tailnet works uniformly across every peer.

    argparse h/help d/doctor 'u/user=' -- $argv
    or return 1
    if set -q _flag_help
        printf 'Usage: rtmux [-u user]\n'
        printf '       rtmux --doctor      diagnose connectivity\n'
        printf '  Pick a remote tmux session on a Tailscale peer and attach to it.\n'
        return 0
    end

    # Leave the username to ssh / ssh_config per host (so a `User` directive is
    # honored); `-u` forces one user for every host. ssh_pre is "" or "user@".
    set -l ssh_pre ""
    set -q _flag_user; and set ssh_pre "$_flag_user@"

    if set -q _flag_doctor
        _rtmux_doctor "$ssh_pre"
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
    # A real tab ($tab) is used as the tmux -F delimiter — tmux does not expand
    # the "\t" escape, so it must be a literal tab character.
    set -l tab (printf '\t')
    set -l ssh_opts -o ConnectTimeout=5 -o BatchMode=yes

    # Query every peer in parallel: each background job writes its session list
    # to a per-peer temp file, so one slow or unreachable peer can no longer
    # stall the whole menu (this was previously a serial loop that paid up to
    # ConnectTimeout seconds per peer). Rows are then assembled in peer order.
    set -l tmpdir (mktemp -d)
    set -l i 0
    for peer in $peers
        set i (math $i + 1)
        set -l target (string split -f1 \t -- $peer)
        ssh $ssh_opts $ssh_pre$target \
            "tmux list-sessions -F '#{session_name}$tab#{session_windows}w#{?session_attached, (attached),}'" \
            >$tmpdir/$i 2>/dev/null &
    end
    wait

    set -l rows
    set i 0
    for peer in $peers
        set i (math $i + 1)
        set -l target (string split -f1 \t -- $peer)
        set -l label (string split -f2 \t -- $peer)
        for line in (cat $tmpdir/$i 2>/dev/null)
            set -l name (string split -f1 \t -- $line)
            set -l meta (string split -m1 -f2 \t -- $line)
            set -a rows (printf '%s\t%s\t%-12s %-20s %s' $target $name $label $name $meta)
        end
        set -a rows (printf '%s\t%s\t%-12s %s' $target __new__ $label '[+ new session]')
    end
    rm -rf $tmpdir

    set -l pick (printf '%s\n' $rows \
        | fzf --delimiter \t --with-nth 3 \
            --prompt 'remote tmux> ' --height 40% --reverse \
            --header 'Select a remote tmux session')
    test -z "$pick"; and return 1

    set -l host (string split -f1 \t -- $pick)
    set -l sess (string split -f2 \t -- $pick)

    # Build a remote `env` prefix so tmux starts correctly regardless of the
    # remote login shell (sh/bash/zsh/fish) or its profile:
    #  - LANG/LC_ALL: force a UTF-8 locale. ssh does not forward LANG/LC_*, so the
    #    remote often defaults to C/POSIX, which makes tmux (and anything run in
    #    it) draw pane borders and box-drawing glyphs as blanks, e.g. the
    #    pane-border-status rule under the top status bar. en_US.UTF-8 is present
    #    on macOS and virtually all Linux, so it is the safe cross-peer default.
    #  - TERM: keep the local TERM if the remote knows it, else fall back to a
    #    universally-present terminfo (e.g. a host without the ghostty terminfo).
    set -l env_pre 'env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 '
    if not ssh $ssh_opts $ssh_pre$host "infocmp $TERM" >/dev/null 2>&1
        set env_pre $env_pre'TERM=xterm-256color '
    end

    # `-u` forces the tmux client into UTF-8 mode. Over ssh the remote login
    # shell's locale is often C/POSIX (ssh does not forward LANG/LC_*), so tmux
    # flags the client non-UTF-8 and renders pane borders / box-drawing glyphs
    # (e.g. the pane-border-status rule under the top status bar) as blanks. Drop
    # -u and the remote view silently loses those lines while the local client
    # keeps them.
    if test "$sess" = __new__
        # Attach-or-create a default session so repeated "new" picks reuse it.
        ssh -t $ssh_pre$host $env_pre"tmux -u new-session -A -s main"
    else
        # POSIX single-quote-escape the session name so names containing a quote
        # or space survive the remote shell: each ' becomes '\''.
        set -l sess_esc (string replace -a "'" "'\''" -- $sess)
        ssh -t $ssh_pre$host $env_pre"tmux -u attach-session -t '$sess_esc'"
    end
end

# --- doctor presentation helpers (Catppuccin Mocha) ----------------------------
# Defined alongside rtmux so they load together; private, prefixed _rtmux_*.

function _rtmux_section --argument-names title
    printf '\n'
    set_color -o cba6f7 # mauve
    printf '%s\n' $title
    set_color normal
end

function _rtmux_ok --argument-names message
    set_color a6e3a1 # green
    printf '  ✓ '
    set_color normal
    printf '%s\n' $message
end

function _rtmux_warn --argument-names message
    set_color f9e2af # yellow
    printf '  ⚠ '
    set_color normal
    printf '%s\n' $message
end

function _rtmux_fail --argument-names message
    set_color f38ba8 # red
    printf '  ✗ '
    set_color normal
    printf '%s\n' $message
end

function _rtmux_hint --argument-names message
    set_color 6c7086 # overlay0 (dim)
    printf '      %s\n' $message
    set_color normal
end

function _rtmux_doctor --argument-names ssh_pre
    # Walks every failure point of rtmux in order with colored status glyphs.
    # ssh_pre is "" (let ssh config resolve the user) or "user@" (forced).
    # Returns nonzero if any hard check failed.
    set -l failures 0
    set -l ssh_opts -o ConnectTimeout=5 -o BatchMode=yes

    set_color -o 89b4fa # blue
    printf '\n\U1f489 rtmux doctor\n' # syringe
    set_color normal

    _rtmux_section 'Dependencies'
    for tool in tailscale fzf jq ssh
        if command -q $tool
            _rtmux_ok "$tool found"
        else
            _rtmux_fail "$tool not in PATH"
            set failures (math $failures + 1)
        end
    end

    _rtmux_section 'Tailscale daemon'
    if not command -q tailscale
        _rtmux_fail 'tailscale CLI missing; cannot check daemon'
        printf '\n'
        set_color -o f38ba8
        printf '1 hard failure\n'
        set_color normal
        return 1
    end
    set -l ts_status (tailscale status 2>&1)
    if test $status -ne 0
        _rtmux_fail "\`tailscale status\` failed: $ts_status"
        _rtmux_hint 'Is Tailscale running and logged in? Try the menu-bar app or `tailscale up`.'
        set failures (math $failures + 1)
    else
        _rtmux_ok 'tailnet reachable'
    end

    _rtmux_section 'SSH agent'
    set -l ids (ssh-add -l 2>/dev/null)
    if test $status -eq 0; and test -n "$ids"
        _rtmux_ok (printf '%d identity(ies) loaded in agent' (count $ids))
    else
        _rtmux_warn 'no identities in ssh-agent; key auth will fail unless you'
        _rtmux_hint 'load a key (`ssh-add --apple-use-keychain`).'
    end

    _rtmux_section 'Peers'
    set -l peers (_rtmux_peers)
    if test -z "$peers"
        _rtmux_fail 'no online macOS/Linux peers found'
        _rtmux_hint '`tailscale status` shows them as offline, or they run a non-tmux OS.'
        printf '\n'
        set_color -o f38ba8
        printf '%d hard failure(s)\n' (math $failures + 1)
        set_color normal
        return 1
    end
    set -l user_note 'per ssh config'
    test -n "$ssh_pre"; and set user_note (string replace -- '@' '' "$ssh_pre")" (forced)"
    _rtmux_ok (printf '%d candidate peer(s) (ssh user: %s)' (count $peers) $user_note)

    _rtmux_section 'Per-peer reachability'
    for peer in $peers
        set -l target (string split -f1 \t -- $peer)
        set -l label (string split -f2 \t -- $peer)
        set_color -o 94e2d5 # teal
        printf '  %s' $label
        set_color normal
        set_color 6c7086
        printf ' (%s)\n' $target
        set_color normal

        # Non-interactive SSH: this is exactly how session listing authenticates.
        ssh $ssh_opts $ssh_pre$target true 2>/dev/null
        if test $status -ne 0
            _rtmux_warn 'non-interactive SSH failed; sessions will not be listed.'
            _rtmux_hint "Check key auth and the username for $target — e.g. a Host block with the right User in ~/.ssh/config.local."
            _rtmux_hint 'The "[+ new session]" entry still works interactively.'
            continue
        end
        _rtmux_ok 'SSH ok'

        if not ssh $ssh_opts $ssh_pre$target \
                "command -v tmux >/dev/null 2>&1"
            _rtmux_warn 'tmux not found on remote PATH'
            continue
        end
        set -l n (ssh $ssh_opts $ssh_pre$target \
            "tmux list-sessions 2>/dev/null | wc -l | tr -d ' '")
        _rtmux_ok "tmux present, $n running session(s)"
    end

    printf '\n'
    if test $failures -eq 0
        set_color -o a6e3a1
        printf '✓ all clear\n'
        set_color normal
    else
        set_color -o f38ba8
        printf '✗ %d hard failure(s)\n' $failures
        set_color normal
    end
    test $failures -eq 0
end
