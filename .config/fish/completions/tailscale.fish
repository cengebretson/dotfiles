# Tailscale completions.
#
# 1. Pull in tailscale's own generated subcommand/flag completion.
# 2. Add live Taildrop target completion for `tailscale file cp <file> <host>:`,
#    which the generated completion does not provide.

# Subcommands and flags, straight from tailscale's generator.
tailscale completion fish 2>/dev/null | source

# Own devices as Taildrop targets: magicDNS short name + trailing colon.
# Skips Mullvad exit nodes (OS == "") since you can only Taildrop to your
# own devices. Description column shows the OS.
function __tailscale_taildrop_hosts
    tailscale status --json 2>/dev/null | jq -r '
        .Peer[]? | select(.OS != "")
        | "\(.DNSName | rtrimstr(".") | split(".")[0]):\t\(.OS)"' 2>/dev/null
end

complete -c tailscale \
    -n '__fish_seen_subcommand_from file; and __fish_seen_subcommand_from cp' \
    -a '(__tailscale_taildrop_hosts)' \
    -d 'Taildrop target'
