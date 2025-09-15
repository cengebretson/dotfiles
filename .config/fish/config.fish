# path setup
fish_add_path /usr/local/bin
fish_add_path /opt/homebrew/bin
fish_add_path "$VOLTA_HOME/bin"

# load aliases
source ~/.config/fish/alias.fish

# volta setup
set -gx VOLTA_HOME "$HOME/.volta"

# make nvim the default editor
set -gx EDITOR nvim
set -gx TERMINAL ghostty
set -gx XDG_CONFIG_HOME "$HOME/.config"

# fzf settings
fzf_configure_bindings --directory=\ct

# starship init
starship init fish | source

# zoxide integration to use j and ji keys
zoxide init --cmd j fish | source
