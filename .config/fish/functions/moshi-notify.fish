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
        case -h --help help
            set -l acc cba6f7
            set -l dim 6c7086
            set -l txt cdd6f4
            set -l sub a6adc8
            echo ''
            printf '  %s󰄛%s  %smoshi-notify%s %s— toggle/inspect Moshi agent-hook pushes%s\n' \
                (set_color $acc) (set_color normal) (set_color --bold $txt) (set_color normal) \
                (set_color $dim) (set_color normal)
            printf '  %s────────────────────%s\n' (set_color $dim) (set_color normal)
            printf '    %son%s | %sloud%s      start the daemon\n'  (set_color $txt) (set_color normal) (set_color $sub) (set_color normal)
            printf '    %soff%s | %squiet%s    stop the daemon\n'   (set_color $txt) (set_color normal) (set_color $sub) (set_color normal)
            printf '    %stoggle%s         flip the daemon on/off\n' (set_color $txt) (set_color normal)
            printf '    %sstatus%s         show daemon + pairing + hook health %s(default)%s\n' (set_color $txt) (set_color normal) (set_color $dim) (set_color normal)
            printf '    %s-h%s, %s--help%s     show this help\n'     (set_color $txt) (set_color normal) (set_color $txt) (set_color normal)
            echo ''
        case status '' '*'
            # Catppuccin Mocha palette (matches the tmux-moshi plugin's moshi-status).
            set -l grn a6e3a1
            set -l amb f9e2af
            set -l dim 6c7086
            set -l txt cdd6f4
            set -l sub a6adc8
            set -l acc cba6f7

            set -l daemon_on 0
            if env -u TMUX brew services list | grep -q '^moshi-hook.*started'
                set daemon_on 1
            end

            # One status snapshot; pull pairing + device name out of it.
            set -l snap (moshi-hook status 2>/dev/null)
            set -l pairing (printf '%s\n' $snap | string replace -rf '^status:[[:space:]]*' '')
            set -l device (printf '%s\n' $snap | string replace -rf '^display name:[[:space:]]*' '')
            test -z "$pairing"; and set pairing unknown
            test -z "$device"; and set device unknown

            echo ''
            printf '  %s󰄛%s  %sMoshi agent-hook%s\n' \
                (set_color $acc) (set_color normal) (set_color --bold $txt) (set_color normal)
            printf '  %s────────────────────%s\n' (set_color $dim) (set_color normal)

            if test $daemon_on -eq 1
                printf '   %s●%s  %sdaemon%s    %sON%s  %srunning%s\n' \
                    (set_color $grn) (set_color normal) (set_color $sub) (set_color normal) \
                    (set_color $grn) (set_color normal) (set_color $dim) (set_color normal)
            else
                printf '   %s●%s  %sdaemon%s    %sOFF%s %sstopped%s\n' \
                    (set_color $dim) (set_color normal) (set_color $sub) (set_color normal) \
                    (set_color $dim) (set_color normal) (set_color $dim) (set_color normal)
            end

            set -l pcol $amb
            test "$pairing" = paired; and set pcol $grn
            printf '   %s●%s  %spairing%s   %s%s%s\n' \
                (set_color $pcol) (set_color normal) (set_color $sub) (set_color normal) \
                (set_color $pcol) $pairing (set_color normal)

            printf '      %sdevice%s    %s%s%s\n' \
                (set_color $sub) (set_color normal) (set_color $txt) $device (set_color normal)

            # Per-agent hook health: show only installed targets (skip "not found"),
            # green = ok, amber = stale/anything needing a reinstall.
            set -l hook_segs
            for line in $snap
                set -l m (string match -rg '^  (\S+) +(\S+)' -- $line)
                test (count $m) -lt 2; and continue
                test "$m[2]" = not; and continue # "<name> not found"
                set -l name $m[1]
                set -l state $m[2]
                set -l note ''
                # Hooks routed through our dispatch.sh aren't recognized by
                # moshi's own installer, so it reports them "stale" even though
                # they fire fine. Treat a dispatch-wired target as ok.
                if test "$state" != ok
                    set -l cfg
                    switch $name
                        case claude
                            set cfg "$HOME/.config/claude/settings.json"
                        case codex
                            set cfg "$HOME/.config/codex/hooks.json"
                    end
                    if test -n "$cfg"; and grep -qE 'dispatch\.sh.* moshi' "$cfg" 2>/dev/null
                        set state ok
                        set note ' (dispatch)'
                    end
                end
                set -l c $amb
                test "$state" = ok; and set c $grn
                set -a hook_segs (printf '%s%s %s%s%s%s' \
                    (set_color $c) $name $state (set_color $dim) $note (set_color normal))
            end
            if test (count $hook_segs) -gt 0
                printf '      %shooks%s     %s\n' \
                    (set_color $sub) (set_color normal) (string join ' · ' $hook_segs)
            end
            echo ''

            __moshi_refresh_paired
    end
end
