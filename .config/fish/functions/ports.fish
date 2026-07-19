function ports --description 'List or stop listening TCP ports'
    set -l command list
    set -l port

    if test (count $argv) -gt 0
        switch $argv[1]
            case -h --help help
                _ports_usage
                return 0
            case --kill -k kill
                set command kill
                set port $argv[2]
            case '*'
                set port $argv[1]
        end
    end

    switch $command
        case list
            _ports_list $port
        case kill
            if test -z "$port"
                _ports_usage
                return 1
            end

            if not _ports_valid_port "$port"
                printf 'ports: invalid TCP port: %s (expected 1-65535)\n' "$port" >&2
                return 2
            end

            set -l pids (_ports_pids $port)
            if test (count $pids) -eq 0
                echo "No listener found on port $port"
                return 1
            end

            if command kill -- $pids
                echo "Sent TERM to "(string join ', ' $pids)" for port $port"
            else
                printf 'ports: failed to send TERM to %s for port %s\n' \
                    (string join ', ' $pids) "$port" >&2
                return 1
            end
    end
end

function _ports_list --argument-names port
    if test -n "$port"
        lsof -nP -iTCP:$port -sTCP:LISTEN
    else
        lsof -nP -iTCP -sTCP:LISTEN
    end
end

function _ports_pids --argument-names port
    lsof -nP -tiTCP:$port -sTCP:LISTEN
end

function _ports_valid_port --argument-names port
    string match -qr '^[0-9]+$' -- "$port"
    and test "$port" -ge 1
    and test "$port" -le 65535
end

function _ports_usage
    echo "Usage:"
    echo "  ports"
    echo "  ports <port>"
    echo "  ports --kill <port>"
end
