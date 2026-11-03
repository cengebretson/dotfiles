function phoneview --description 'Create grouped tmux session(s) for the phone to attach to without clobbering the laptop view'
    # Two clients on ONE tmux session force the same window and shrink to the
    # smaller screen (the phone). A grouped session shares the window list but
    # keeps an independent current-window and size, so the phone can view your
    # work without reshaping the laptop. One "phone-<name>" mirror per session
    # means Moshi's session picker can offer a safe mirror for every project.
    set -l arg $argv[1]

    switch "$arg"
        case clean
            # Remove every phone-* mirror (kills only the mirrors, not the real
            # sessions they are grouped with).
            set -l removed 0
            set -l failures 0
            set -l sessions (tmux list-sessions -F '#S')
            or return $status
            for s in (string match 'phone-*' -- $sessions)
                if tmux kill-session -t "=$s"
                    set removed (math $removed + 1)
                else
                    set failures (math $failures + 1)
                end
            end
            echo "removed $removed phone-* mirror session(s)"
            test $failures -eq 0
            return $status

        case all
            # Mirror every real (non-mirror) session.
            set -l failures 0
            set -l sessions (tmux list-sessions -F '#S')
            or return $status
            for s in (string match -v 'phone-*' -- $sessions)
                if _phoneview_ensure "$s"
                    echo "phone-$s  ->  $s"
                else
                    set failures (math $failures + 1)
                end
            end
            test $failures -eq 0
            return $status

        case ''
            # No arg: mirror the session this command is run from.
            set arg (tmux display-message -p '#S')
            or return $status
    end

    _phoneview_ensure "$arg"; or return $status
    echo "phone view 'phone-$arg' now mirrors session: $arg"
end

function _phoneview_ensure --argument-names arg
    if not tmux has-session -t "=$arg" 2>/dev/null
        echo "phoneview: no session named '$arg'" >&2
        return 1
    end

    set -l mirror "phone-$arg"
    if tmux has-session -t "=$mirror" 2>/dev/null
        set -l source_group (tmux display-message -p -t "=$arg:" '#{session_group}')
        or return $status
        set -l mirror_group (tmux display-message -p -t "=$mirror:" '#{session_group}')
        or return $status
        if test -n "$source_group"; and test "$source_group" = "$mirror_group"
            return 0
        end
        printf "phoneview: '%s' exists in a different session group; leaving it intact\n" "$mirror" >&2
        return 1
    end
    set -l source_id (tmux display-message -p -t "=$arg:" '#{session_id}')
    or return $status
    tmux new-session -d -s "$mirror" -t "$source_id"
end
