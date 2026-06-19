function updates --description 'Update Homebrew, tmux TPM plugins, and Fish completions'
    set -l failures
    set -l tpm_update "$HOME/.config/tmux/plugins/tpm/bin/update_plugins"

    brew update
    or set --append failures 'brew update'

    brew upgrade
    or set --append failures 'brew upgrade'

    if test -x "$tpm_update"
        "$tpm_update" all
        or set --append failures 'tmux TPM plugins'
    else
        echo "updates: skipping tmux TPM plugins; $tpm_update is not executable" >&2
    end

    fisher update
    or set --append failures 'fisher update'

    fish_update_completions
    or set --append failures 'fish_update_completions'

    brew cleanup
    or set --append failures 'brew cleanup'

    if test (count $failures) -gt 0
        printf 'updates: failed: %s\n' (string join ', ' $failures) >&2
        return 1
    end

    confetti
end
