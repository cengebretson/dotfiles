#!/usr/bin/env bash
set -euo pipefail

# To use:
# curl https://raw.githubusercontent.com/cengebretson/dotfiles/master/.config/setup.sh | bash

# ── Xcode CLI Tools ────────────────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  echo "Xcode CLI tools not found. Installing..."
  xcode-select --install
  echo "Waiting for Xcode CLI tools to finish installing..."
  until xcode-select -p &>/dev/null; do sleep 5; done
fi
echo "✓ Xcode CLI tools"

# ── Homebrew ───────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for Apple Silicon (no-op on Intel)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
echo "✓ Homebrew"

# ── Dotfiles ───────────────────────────────────────────────────────────────────
function dotfiles {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}

if [ ! -d "$HOME/.dotfiles" ]; then
  echo "Cloning dotfiles..."
  git clone --bare git@github.com:cengebretson/dotfiles.git "$HOME/.dotfiles"
  dotfiles config --local core.bare false
  dotfiles config --local core.worktree "$HOME"
  dotfiles config --local status.showUntrackedFiles no

  mkdir -p "$HOME/.dotfiles-backup"
  if dotfiles checkout; then
    echo "✓ Dotfiles checked out"
  else
    echo "Backing up conflicting files to ~/.dotfiles-backup..."
    dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} "$HOME/.dotfiles-backup/{}"
    dotfiles checkout
    echo "✓ Dotfiles checked out (conflicts backed up)"
  fi
else
  echo "✓ Dotfiles already present"
fi

# ── macOS Defaults ─────────────────────────────────────────────────────────────
bash "$HOME/.config/macos-defaults.sh"

# ── Brew Bundle ────────────────────────────────────────────────────────────────
echo "Installing packages from Brewfile..."
brew bundle --file="$HOME/.config/Brewfile"
echo "✓ Brew bundle complete"

# ── Fish as default shell ──────────────────────────────────────────────────────
FISH_PATH="$(brew --prefix)/bin/fish"
if ! grep -qF "$FISH_PATH" /etc/shells; then
  echo "Adding fish to /etc/shells..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
if [ "$SHELL" != "$FISH_PATH" ]; then
  echo "Setting fish as default shell..."
  chsh -s "$FISH_PATH"
fi
echo "✓ Fish shell"

# ── Mise (Node, Bun, and other runtimes) ──────────────────────────────────────
mise install
echo "✓ Mise runtimes"

# ── Fisher plugins ─────────────────────────────────────────────────────────────
echo "Installing fisher plugins..."
fish -c "fisher update"
echo "✓ Fisher plugins"

# ── fzf universal variable ─────────────────────────────────────────────────────
fish -c "set -U FZF_DEFAULT_OPTS \"--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4 --input-border --list-border --info=inline\n--ansi --preview-window 'right:60%' --preview 'test -f {} && bat --color=always --style=header,grid --line-range :300 {} || echo {}'\""
echo "✓ fzf config"

echo ""
echo "Done! Open a new terminal to start using fish."
