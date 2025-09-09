# dotfiles

Personal configuration files (dotfiles) to streamline setup across systems.

## Repository Contents

- **`.config/`** – Configuration directories for applications and tools.
- **`.ssh/`** – SSH configuration, such as `config`, known hosts, or key management.
- **`.gitconfig`** – Git user profiles, aliases, and preferences.
- **`.gitignore`** – Specifies files and directories to ignore under version control.

## Getting Started

To use these dotfiles on your own system:

```bash
git clone https://github.com/cengebretson/dotfiles.git
cd dotfiles
# Example: Create symlinks in your home directory
ln -s "$(pwd)/.gitconfig" ~/.gitconfig
# Repeat for other files as needed

