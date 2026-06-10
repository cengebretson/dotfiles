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
  git clone --bare https://github.com/cengebretson/dotfiles.git "$HOME/.dotfiles"
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

# ── Mise (Node, Bun, Go, Python, and other runtimes) ─────────────────────────
mise install
# Put mise-managed runtimes (node/npm, etc.) on PATH for the rest of this script
eval "$(mise activate bash --shims)"
echo "✓ Mise runtimes"

# ── Claude Code ────────────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi
mkdir -p "$HOME/.config/claude"
if [ ! -e "$HOME/.claude" ]; then
  ln -s "$HOME/.config/claude" "$HOME/.claude"
elif [ -L "$HOME/.claude" ] && [ "$(readlink "$HOME/.claude")" != "$HOME/.config/claude" ]; then
  echo "Warning: ~/.claude points to $(readlink "$HOME/.claude"), not ~/.config/claude"
elif [ -e "$HOME/.claude" ] && [ ! -L "$HOME/.claude" ]; then
  echo "Warning: ~/.claude exists and is not a symlink; leaving it unchanged"
fi
echo "✓ Claude Code"

# ── Codex ─────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config"
if [ -L "$HOME/.codex" ]; then
  if [ "$(readlink "$HOME/.codex")" != "$HOME/.config/codex" ]; then
    echo "Warning: ~/.codex points to $(readlink "$HOME/.codex"), not ~/.config/codex"
  fi
elif [ -d "$HOME/.codex" ]; then
  if [ ! -e "$HOME/.config/codex" ]; then
    mv "$HOME/.codex" "$HOME/.config/codex"
    ln -s "$HOME/.config/codex" "$HOME/.codex"
  else
    echo "Warning: both ~/.codex and ~/.config/codex exist; leaving them unchanged"
  fi
elif [ ! -e "$HOME/.codex" ]; then
  mkdir -p "$HOME/.config/codex"
  ln -s "$HOME/.config/codex" "$HOME/.codex"
else
  echo "Warning: ~/.codex exists and is not a directory or symlink; leaving it unchanged"
fi
echo "✓ Codex"

# ── File Associations ──────────────────────────────────────────────────────────
echo "Setting file associations (macOS may prompt to confirm changes)..."
while IFS= read -r line; do
  [[ "$line" =~ ^# || -z "$line" ]] && continue
  read -r bundle ext role <<< "$line"
  current=$(duti -x "$ext" 2>/dev/null | awk 'NR==2')
  if [ "$current" != "$bundle" ]; then
    duti -s "$bundle" "$ext" "$role" 2>/dev/null
  fi
done < "$HOME/.config/duti"
echo "✓ File associations"

# ── Fisher plugins ─────────────────────────────────────────────────────────────
echo "Installing fisher plugins..."
if fish -c "type -q fisher" 2>/dev/null; then
  fish -c "fisher update"
else
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher update"
fi
echo "✓ Fisher plugins"


echo ""
echo "Done! Open a new terminal to start using fish."
