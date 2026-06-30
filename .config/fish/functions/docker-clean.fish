function docker-clean --description 'Safely reclaim Docker/OrbStack disk space'
    set -l include_volumes 0
    set -l reset_orbstack 0
    set -l show_help 0
    set -l failures
    set -l results
    set -l ok (set_color green)'✓'(set_color normal)
    set -l fail (set_color red)'✗'(set_color normal)

    for arg in $argv
        switch $arg
            case -h --help help
                set show_help 1
            case --volumes
                set include_volumes 1
            case --reset-orbstack
                set reset_orbstack 1
            case '*'
                echo "docker-clean: unknown option: $arg" >&2
                _docker_clean_usage >&2
                return 2
        end
    end

    if test $show_help -eq 1
        _docker_clean_usage
        return 0
    end

    if not command -q docker
        _docker_clean_error 'docker command not found'
        return 127
    end

    if test $reset_orbstack -eq 1
        if not command -q orbctl
            _docker_clean_error 'orbctl command not found'
            return 127
        end

        _docker_clean_heading 'OrbStack reset'
        echo 'This will permanently delete all OrbStack Linux machines and Docker data.'
        read --local --prompt-str (set_color yellow)'Type reset-orbstack to continue: '(set_color normal) confirmation
        if test "$confirmation" != reset-orbstack
            echo (set_color yellow)'docker-clean: OrbStack reset cancelled'(set_color normal)
            return 1
        end

        orbctl reset -y
        return $status
    end

    _docker_clean_heading 'Before'
    docker system df
    or return $status

    _docker_clean_heading 'Build cache'
    if docker builder prune -af
        set --append results "$ok build cache pruned"
    else
        set --append results "$fail build cache prune failed"
        set --append failures 'docker builder prune'
    end

    _docker_clean_heading 'Unused images'
    if docker image prune -af
        set --append results "$ok unused images pruned"
    else
        set --append results "$fail image prune failed"
        set --append failures 'docker image prune'
    end

    if test $include_volumes -eq 1
        _docker_clean_heading 'Stopped containers, networks, and unused volumes'
        if docker system prune -af --volumes
            set --append results "$ok stopped containers, networks, and unused volumes pruned"
        else
            set --append results "$fail system prune with volumes failed"
            set --append failures 'docker system prune --volumes'
        end
    else
        _docker_clean_heading 'Stopped containers and networks'
        if docker system prune -f
            set --append results "$ok stopped containers and networks pruned"
        else
            set --append results "$fail system prune failed"
            set --append failures 'docker system prune'
        end
    end

    _docker_clean_heading 'After'
    docker system df
    or return $status

    if test -d "$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data"
        _docker_clean_heading 'OrbStack data'
        du -sh "$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data"
    end

    _docker_clean_heading 'Summary'
    printf '%s\n' $results

    if test (count $failures) -gt 0
        _docker_clean_error "failed: "(string join ', ' $failures)
        return 1
    end
end

function _docker_clean_usage
    set -l command_color (set_color cyan)
    set -l normal (set_color normal)

    echo (set_color --bold)'Usage:'$normal
    echo "  $command_color"docker-clean"$normal"
    echo "  $command_color"docker-clean --volumes"$normal"
    echo "  $command_color"docker-clean --reset-orbstack"$normal"
    echo
    echo 'Default cleanup removes build cache, unused images, stopped containers, and unused networks.'
    echo '--volumes also removes unused Docker volumes.'
    echo '--reset-orbstack deletes all OrbStack Linux machines and Docker data after confirmation.'
end

function _docker_clean_heading --argument-names title
    printf '\n%s==> %s%s\n' (set_color cyan) "$title" (set_color normal)
end

function _docker_clean_error --argument-names message
    printf '%sdocker-clean:%s %s\n' (set_color red) (set_color normal) "$message" >&2
end
