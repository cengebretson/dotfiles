function _local_ssh_agent --description 'Reuse a working SSH socket before starting an interactive agent'
    command -q ssh-add; and command -q ssh-agent; or return 0
    _local_ssh_agent_ready; and return 0

    set -q SSH_ENV; or set -gx SSH_ENV "$HOME/.ssh/environment"
    if test -r "$SSH_ENV"
        source "$SSH_ENV" >/dev/null 2>&1
        _local_ssh_agent_ready; and return 0
    end

    # Keep the reusable environment private and replace it atomically.
    command mkdir -p -- (path dirname "$SSH_ENV"); or return 1
    set -l agent_file (mktemp "$SSH_ENV.XXXXXX")
    test -n "$agent_file"; or return 1
    set -l agent_env (ssh-agent -c)
    set -l agent_status $status
    if test $agent_status -ne 0
        command rm -f -- "$agent_file"
        return $agent_status
    end
    printf '%s\n' $agent_env | string replace -r '^echo ' '#echo ' >"$agent_file"
    source "$agent_file" >/dev/null
    if _local_ssh_agent_ready
        command mv -f -- "$agent_file" "$SSH_ENV"
        return $status
    end
    command rm -f -- "$agent_file"
    return 1
end

function _local_ssh_agent_ready
    test -n "$SSH_AUTH_SOCK"; or return 1
    ssh-add -l >/dev/null 2>&1
    # An empty agent (1) is usable too. A connection failure is 2.
    contains -- $status 0 1
end
