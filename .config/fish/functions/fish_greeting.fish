function fish_greeting
    if test (random 0 1) -eq 0
        fastfetch
    else
        _display_random_iroh
    end
end

function _display_random_iroh
    set -l iroh_dir ~/.config/nvim-v12/assets
    if not test -d "$iroh_dir"
        fastfetch
        return
    end

    set -l files (command find "$iroh_dir" -maxdepth 1 -type f -name 'iroh*.png' -print0 2>/dev/null | string split0)
    if test (count $files) -eq 0
        fastfetch
        return
    end

    set -l rand (random 1 (count $files))
    set -l selected $files[$rand]
    set -l width 96

    if set -q COLUMNS; and test "$COLUMNS" -lt $width
        set width $COLUMNS
    end

    chafa --size "$width"x24 --align top,left "$selected"
end
