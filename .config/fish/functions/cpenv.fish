function cpenv
    if test (count $argv) -lt 1
        echo "Usage:"
        echo "  cpenv <ENV_VAR_NAME>"
        return 1
    end

    set -l var_name $argv[1]
    set -l value (eval echo \$$var_name)

    if test -z "$value"
        echo "Environment variable not set: $var_name"
        return 1
    end

    echo -n $value | pbcopy
    echo "Copied $var_name to clipboard"
end
