#!/usr/bin/env bash
set -euo pipefail

echo "Applying macOS defaults..."

# ── Dock ───────────────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 35
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock minimize-to-application -bool true

# ── Keyboard ───────────────────────────────────────────────────────────────────
# Disable press-and-hold for accents, enabling key repeat instead
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable smart quotes and dashes (they mangle code snippets)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ── Finder ─────────────────────────────────────────────────────────────────────
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder NewWindowTarget -string "PfAF"
defaults write com.apple.finder ShowHiddenFiles -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# No .DS_Store on network or USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Screenshots ────────────────────────────────────────────────────────────────
defaults write com.apple.screencapture disable-shadow -bool true

# ── System ─────────────────────────────────────────────────────────────────────
# Save to disk instead of iCloud by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
# Disable crash reporter dialogs
defaults write com.apple.CrashReporter DialogType -string "none"

# ── Apply ──────────────────────────────────────────────────────────────────────
killall Dock
killall Finder

echo "✓ macOS defaults applied"
