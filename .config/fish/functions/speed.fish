function speed --description 'Run macOS networkQuality with friendly modes'
    set -l mode normal
    set -l interval 10
    set -l args

    while test (count $argv) -gt 0
        switch $argv[1]
            case -h --help help
                _speed_usage
                return 0
            case simple --simple
                set mode simple
            case watch --watch
                set mode watch
                if test (count $argv) -gt 1; and string match -qr '^[0-9]+$' -- $argv[2]
                    set interval $argv[2]
                    set -e argv[1]
                end
            case up upload --upload
                set -a args -d
            case down download --download
                set -a args -u
            case full verbose --full --verbose
                set -a args -v
            case sequential seq --sequential
                set -a args -s
            case '*'
                set -a args $argv[1]
        end

        set -e argv[1]
    end

    switch $mode
        case simple
            _speed_simple $args
        case watch
            while true
                date '+%Y-%m-%d %H:%M:%S'
                _speed_simple $args
                sleep $interval
            end
        case normal
            command networkQuality $args
    end
end

function _speed_simple
    command networkQuality $argv \
        | string match --regex '^(====|Upload capacity|Download capacity|Upload flows|Download flows|Responsiveness|Idle Latency|RPM|Quality)'
end

function _speed_usage
    echo "Usage:"
    echo "  speed"
    echo "  speed simple"
    echo "  speed watch [seconds]"
    echo "  speed up"
    echo "  speed down"
    echo "  speed full"
    echo ""
    echo "Native networkQuality flags are passed through."
end
