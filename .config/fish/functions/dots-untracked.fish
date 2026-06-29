function dots-untracked --description 'List untracked files visible to the bare dotfiles repo'
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" ls-files --others --exclude-standard $argv
end
