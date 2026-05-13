function gitcreddel
    if test (count $argv) -lt 1
        echo "Usage:"
        echo "  gitcreddel <path>"
        return 1
    end

    set path $argv[1]

    printf "protocol=https\nhost=github.com\npath=%s\n\n" \
        $path \
        | git credential reject

    echo "Removed credential for github.com/$path"
end
