function gitcredset
    if test (count $argv) -lt 3
        echo "Usage:"
        echo "  gitcredset <path> <username> <token>"
        echo ""
        echo "Examples:"
        echo "  gitcredset Lenders-Cooperative api ghp_xxx"
        echo "  gitcredset Lenders-Cooperative/my-repo api ghp_xxx"
        return 1
    end

    set path $argv[1]
    set username $argv[2]
    set token $argv[3]

    printf "protocol=https\nhost=github.com\npath=%s\nusername=%s\npassword=%s\n\n" \
        $path $username $token \
        | git credential approve

    echo "Stored credential for github.com/$path"
end
