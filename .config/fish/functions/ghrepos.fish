function ghrepos
    if test (count $argv) -lt 1
        echo "Usage:"
        echo "  ghrepos <token>"
        return 1
    end

    set -l token $argv[1]
    set -l page 1

    while true

        set -l repos (
            curl -s \
                -H "Authorization: Bearer $token" \
                "https://api.github.com/user/repos?per_page=100&page=$page" \
            | jq -r '.[].full_name'
        )

        if test -z "$repos"
            break
        end

        for repo in $repos
            echo $repo
        end

        set page (math $page + 1)
    end
end
