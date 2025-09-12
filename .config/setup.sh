#!/usr/bin/env bash

# To use
# curl https://raw.githubusercontent.com/cengebretson/dotfiles/master/.config/setup.sh | bash

# define config alias locally since the dotfiles
# aren't installed on the system yet
function dotfiles {
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}

# clone repo
git clone --bare git@github.com:cengebretson/dotfiles.git $HOME/.dotfiles
dotfiles config status.showUntrackedFiles no

# create a directory to backup existing dotfiles to
mkdir -p .dotfiles-backup
dotfiles checkout

if [ $? = 0 ]; then
  echo "Checked out dotfiles from git@github.com:mrjones2014/dotfiles.git";
else
  echo "Moving existing dotfiles to ~/.dotfiles-backup";
  dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
  dotfiles checkout
fi

