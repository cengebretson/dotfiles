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
            for s in (tmux list-sessions -F '#S' 2>/dev/null | string match 'phone-*')
                tmux kill-session -t "$s"; and set removed (math $removed + 1)
            end
            echo "removed $removed phone-* mirror session(s)"
            return

        case all
            # Mirror every real (non-mirror) session.
            for s in (tmux list-sessions -F '#S' 2>/dev/null | string match -v 'phone-*')
                tmux has-session -t "phone-$s" 2>/dev/null
                or tmux new-session -d -s "phone-$s" -t "$s"
                echo "phone-$s  ->  $s"
            end
            return

        case ''
            # No arg: mirror the session this command is run from.
            set arg (tmux display-message -p '#S')
    end

    if not tmux has-session -t "$arg" 2>/dev/null
        echo "phoneview: no session named '$arg'" >&2
        return 1
    end

    set -l mirror "phone-$arg"
    tmux kill-session -t "$mirror" 2>/dev/null
    tmux new-session -d -s "$mirror" -t "$arg"
    echo "phone view '$mirror' now mirrors session: $arg"
end
