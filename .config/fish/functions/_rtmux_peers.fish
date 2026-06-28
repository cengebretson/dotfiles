function _rtmux_peers --description 'Emit online tmux-capable Tailscale peers as "ssh-target<TAB>label" lines'
    # Online peers running an OS that can host tmux. .Peer excludes Self, so the
    # local machine is never listed; Mullvad exit nodes (OS == "") drop out via
    # the OS filter. The SSH target is the MagicDNS name with its trailing dot
    # stripped (HostName may contain spaces); the label is the friendly HostName.
    tailscale status --json 2>/dev/null \
        | jq -r '.Peer[]?
                 | select(.Online and (.OS == "macOS" or .OS == "linux"))
                 | "\(.DNSName | rtrimstr("."))\t\(.HostName)"'
end
