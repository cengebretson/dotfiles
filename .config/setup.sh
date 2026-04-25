#!/usr/bin/env bash
set -euo pipefail

# To use
# curl https://raw.githubusercontent.com/cengebretson/dotfiles/master/.config/setup.sh | bash

# define config alias locally since the dotfiles
# aren't installed on the system yet
function dotfiles {
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME "$@"
}

# clone repo
git clone --bare git@github.com:cengebretson/dotfiles.git $HOME/.dotfiles
dotfiles config --local core.bare false
dotfiles config --local core.worktree $HOME
dotfiles config --local status.showUntrackedFiles no

# create a directory to backup existing dotfiles to
mkdir -p .dotfiles-backup

if dotfiles checkout; then
  echo "Checked out dotfiles from git@github.com:cengebretson/dotfiles.git"
else
  echo "Moving existing dotfiles to ~/.dotfiles-backup"
  dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} .dotfiles-backup/{}
  dotfiles checkout
fi

# set fzf universal variable (not tracked in dotfiles)
fish -c "set -U FZF_DEFAULT_OPTS \"--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4 --input-border --list-border --info=inline\n--ansi --preview-window 'right:60%' --preview 'test -f {} && bat --color=always --style=header,grid --line-range :300 {} || echo {}'\""
