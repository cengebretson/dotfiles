function kp --description 'Kill processes selected with fzf'
    set -l signal TERM

    if test (count $argv) -gt 0
        set signal $argv[1]
    end

    set -l selected (
        ps -eo pid=,user=,comm=,args= \
            | string trim \
            | fzf --multi --header="kill:$signal"
    )

    test (count $selected) -gt 0; or return 0

    set -l pids
    for process in $selected
        set -a pids (string split --max 1 ' ' $process)[1]
    end

    test (count $pids) -gt 0; or return 0

    kill -s $signal $pids
end
