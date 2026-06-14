# path setup
fish_add_path /usr/local/bin
fish_add_path /opt/homebrew/bin
fish_add_path "$HOME/.local/bin"

# load aliases
source ~/.config/fish/alias.fish

# mise (manages node, bun, and other runtimes)
if status is-interactive; and command -sq mise
    mise activate fish --shims --silent | source
end

# environment (needed in interactive and non-interactive shells)
set -gx EDITOR nvim
set -gx TERMINAL ghostty
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx NVIM_APPNAME nvim-v12
set -gx CLAUDE_CONFIG_DIR "$HOME/.config/claude"

# suppress window title
function fish_title
end

# interactive-only UI: key bindings, prompt, fzf, navigation
if status is-interactive
    fish_vi_key_bindings

    if functions -q fzf_configure_bindings
        fzf_configure_bindings --directory=\ct --processes=\cp
    end

    starship init fish | source

    # zoxide integration to use j and ji keys
    zoxide init --cmd j fish | source
end

# Added by OrbStack: command-line tools and integration
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end
set -gx GIT_OPTIONAL_LOCKS 0
