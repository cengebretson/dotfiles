function fish_greeting
    _select_random_image
    fastfetch
end

function _select_random_image
    set -l fastfetch_dir ~/.config/fastfetch
    if not test -d "$fastfetch_dir"
        return
    end

    set -l files (command find "$fastfetch_dir" -type f -name 'option*' -print0 2>/dev/null | string split0)
    if test (count $files) -eq 0
        return
    end

    set -l rand (random 1 (count $files))
    set -l selected $files[$rand]

    cp -- "$selected" ~/.config/fastfetch/ascii.txt
end
