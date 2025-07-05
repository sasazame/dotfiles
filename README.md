# Dotfiles

Personal configuration files and scripts for development environment setup.

## Installation

### Quick Setup

1. Clone this repository to your home directory:
```bash
git clone https://github.com/sasazame/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Run the installation script:
```bash
./install.sh
```

### Manual Installation

If you prefer to manually link specific configurations:

```bash
# Create symbolic links for individual config files
ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/.vimrc ~/.vimrc
# Add more as needed
```

## Structure

- `.config/` - Application-specific configurations
- `scripts/` - Utility scripts and tools
- `shell/` - Shell configurations (bash, zsh)
- `vim/` - Vim configuration and plugins
- `git/` - Git configuration and hooks

## Features

- Shell configuration with useful aliases and functions
- Enhanced bash history with directory tracking and real-time sharing
- Git configuration with helpful aliases
- Vim configuration for development
- Utility scripts for common tasks

## Scripts

### kill-port.sh
Kills a process running on a specified port.

Usage:
```bash
./scripts/kill-port.sh <port>
```

Example:
```bash
./scripts/kill-port.sh 3000
```

## Bash Customizations

The `.bashrc` includes numerous enhancements:

- **Enhanced history** with directory tracking and real-time sharing
- **Useful aliases** for common commands
- **Smart PATH configuration** for development tools
- **Color support** for better readability

See [docs/bashrc-customizations-overview.md](docs/bashrc-customizations-overview.md) for a complete overview.

For specific features:
- [Bash History Guide](docs/bash-history-guide.md) - Advanced history features

## Customization

After installation, you can customize the configurations by editing the files in this repository. Changes will be reflected immediately since the files are symlinked.

## Backup

Before installation, the script will backup any existing configuration files to `~/.dotfiles_backup/` with a timestamp.