# Tailscale completions.
#
# 1. tailscale's own generated subcommand/flag completion.
# 2. Dynamic value completion the generated script lacks:
#    - Taildrop targets for `file cp` (own devices + trailing colon)
#    - host arg for `ping` / `ip` (own devices)
#    - `--exit-node=` value for `set` / `up` (exit nodes, with location)

# Subcommands and flags, straight from tailscale's generator.
tailscale completion fish 2>/dev/null | source

# Own devices (magicDNS short name), skipping Mullvad exit nodes (OS == "").
# Optional suffix is appended to each name — used to add the trailing ":"
# that Taildrop targets need. Description column shows the OS.
function __tailscale_devices --argument-names suffix
    tailscale status --json 2>/dev/null | jq -r --arg sfx "$suffix" '
        .Peer[]? | select(.OS != "")
        | "\(.DNSName | rtrimstr(".") | split(".")[0])\($sfx)\t\(.OS)"' 2>/dev/null
end

# Exit-node-capable peers, described by "Country, City".
function __tailscale_exit_nodes
    tailscale status --json 2>/dev/null | jq -r '
        .Peer[]? | select(.ExitNodeOption == true)
        | .HostName as $h
        | (.Location.Country // "?") as $c
        | (.Location.City // "") as $city
        | "\($h)\t\($c)\(if $city != "" then ", \($city)" else "" end)"' 2>/dev/null
end

# Taildrop targets: `tailscale file cp <file> <host>:`
complete -c tailscale \
    -n '__fish_seen_subcommand_from file; and __fish_seen_subcommand_from cp' \
    -a '(__tailscale_devices :)' -d 'Taildrop target'

# Host arg for `ping` / `ip`
complete -c tailscale -n '__fish_seen_subcommand_from ping ip' \
    -a '(__tailscale_devices)' -d 'tailnet host'

# `--exit-node=` value for `set` / `up`
complete -c tailscale -n '__fish_seen_subcommand_from set up' \
    -l exit-node -x -a '(__tailscale_exit_nodes)'
