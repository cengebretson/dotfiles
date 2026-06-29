function dots-status --description 'Show dotfiles status including hidden untracked files'
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short --untracked-files=all $argv
end
