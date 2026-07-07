function pr --description "Open the GitHub PR for the current branch in the browser"
    if not gh pr view --web 2>/dev/null
        echo "No open PR for this branch" >&2
        return 1
    end
end
