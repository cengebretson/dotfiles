function keychainenv
    if test (count $argv) -lt 3
        echo "Usage:"
        echo "  keychainenv <env-var> <host> <account> [path]"
        return 1
    end

    set env_name $argv[1]
    set host $argv[2]
    set acct $argv[3]

    if test (count $argv) -ge 4

        set path $argv[4]

        set secret (
            security find-internet-password \
                -s $host \
                -a "$acct" \
                -p "$path" \
                -w 2>/dev/null
        )

    else

        set secret (
            security find-internet-password \
                -s $host \
                -a "$acct" \
                -w 2>/dev/null
        )

    end

    if test -n "$secret"
        set -gx $env_name $secret
    end
end
