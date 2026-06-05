function keychain --description 'Inspect macOS Keychain entries and export secrets'
    set -l show_passwords 0
    set -l command list

    if test (count $argv) -gt 0
        switch $argv[1]
            case list ls show
                set command list
                set -e argv[1]
            case setenv env export
                set command env
                set -e argv[1]
        end
    end

    switch $command
        case list
            _keychain_list $argv
        case env
            _keychain_env $argv
    end
end

function _keychain_list
    set -l show_passwords 0
    set -l host ""

    for arg in $argv
        switch $arg
            case --show-passwords
                set show_passwords 1

            case '*'
                set host $arg
        end
    end

    if test -z "$host"
        echo "Usage:"
        echo "  keychain [list] <host> [--show-passwords]"
        echo "  keychain setenv <env-var> <host> <account> [path]"
        return 1
    end

    security dump-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null \
        | awk -v host="$host" '

        /^keychain:/ {

            if (found && acct != "") {

                display_path = path

                if (display_path == "") {
                    display_path = "/"
                }

                print acct "|" path "|" display_path
            }

            found=0
            acct=""
            path=""
        }

        index($0, "0x00000007 <blob>=\"" host "\"") {
            found=1
        }

        found && /"acct"<blob>=/ {
            acct=$0
            sub(/^.*"acct"<blob>="/, "", acct)
            sub(/".*$/, "", acct)
        }

        found && /"path"<blob>=/ {

            if ($0 ~ /<NULL>/) {
                path=""
            } else {
                path=$0
                sub(/^.*"path"<blob>="/, "", path)
                sub(/".*$/, "", path)
            }
        }

        END {

            if (found && acct != "") {

                display_path = path

                if (display_path == "") {
                    display_path = "/"
                }

                print acct "|" path "|" display_path
            }
        }
    ' | while read -l line

        set parts (string split "|" $line)

        set acct $parts[1]
        set raw_path $parts[2]
        set display_path $parts[3]

        echo "Account : $acct"
        echo "Path    : $display_path"

        if test $show_passwords -eq 1

            if test -z "$raw_path"

                set pw (
                    security find-internet-password \
                        -s $host \
                        -a "$acct" \
                        -w 2>/dev/null
                )

            else

                set pw (
                    security find-internet-password \
                        -s $host \
                        -a "$acct" \
                        -p "$raw_path" \
                        -w 2>/dev/null
                )

            end

            if test -n "$pw"
                echo "Password: $pw"
            else
                echo "Password: <unable to retrieve>"
            end
        end

        echo ""
    end
end

function _keychain_env
    if test (count $argv) -lt 3
        echo "Usage:"
        echo "  keychain setenv <env-var> <host> <account> [path]"
        return 1
    end

    set -l env_name $argv[1]
    set -l host $argv[2]
    set -l acct $argv[3]

    if test (count $argv) -ge 4
        set -l path $argv[4]

        set -l secret (
            security find-internet-password \
                -s $host \
                -a "$acct" \
                -p "$path" \
                -w 2>/dev/null
        )
    else
        set -l secret (
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
