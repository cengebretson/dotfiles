function keychain
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
        echo "  keychaincreds <host> [--show-passwords]"
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
