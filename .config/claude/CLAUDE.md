# Global Claude Instructions

## Environment

- **Shell:** Fish (interactive), but all scripts must use `#!/usr/bin/env bash` — hooks and non-interactive contexts run bash
- **Editor:** nvim
- **Terminal:** Ghostty + tmux
- **Color scheme:** Catppuccin Mocha throughout (tmux, delta, statusline, starship)

## Dotfiles Git

Config files are tracked in a bare git repo. Always use these flags for dotfiles git operations:

```bash
git --git-dir=/Users/chris/.dotfiles --work-tree=/Users/chris <command>
```

The fish abbreviation is `dots`. Paths in the index are relative to `~` (e.g. `.config/tmux/tmux.conf`). Run git commands from `~` to get full paths, or from `~/.config` where paths appear without the `.config/` prefix.

## Tmux

- tmux 3.6 — `display-popup` height percentages (`-h 10%`) do not render; use fixed line counts (`-h 3`) instead
- Width percentages (`-w 40%`) work fine

## AI-Helpful CLI Tools

These tools are installed and available. Prefer them over naive alternatives when they're a better fit.

| Tool | Use instead of | When to use |
|------|---------------|-------------|
| `ast-grep` | `grep` / regex | Searching or rewriting code by structure — find all function calls, rename a pattern across files, match syntax not strings |
| `difftastic` | `git diff` | Reviewing structural diffs where line-based diffs are noisy — refactors, formatting changes |
| `shellcheck` | manual review | Validating any shell script before finishing — catches bugs, bad practices, portability issues |
| `sd` | `sed` | Find-and-replace in files — cleaner syntax, supports regex and literal strings |
| `scc` | `wc -l` | Getting a codebase overview — lines, blanks, comments, complexity per language |
| `yq` | manual editing | Reading or editing YAML, TOML, JSON config files in pipelines |
| `jq` | manual parsing | Parsing and transforming JSON |
| `delta` | `diff` | Rendering git diffs with syntax highlighting |
| `fd` | `find` | Fast file search with simpler syntax |
| `rg` (ripgrep) | `grep` | Fast recursive text search |
| `bat` | `cat` | Viewing files with syntax highlighting |
| `eza` | `ls` | Directory listings with icons and git status |
