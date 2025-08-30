#!/bin/bash

# Dotfiles installation script

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dotfiles directory
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Backup directory
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup existing file
backup_file() {
    local file=$1
    if [ -f "$file" ] || [ -L "$file" ]; then
        local filename=$(basename "$file")
        cp -L "$file" "$BACKUP_DIR/$filename"
        print_info "Backed up $file to $BACKUP_DIR/$filename"
    fi
}

# Create symbolic link
create_symlink() {
    local source=$1
    local target=$2
    
    # Backup existing file
    if [ -e "$target" ]; then
        backup_file "$target"
        rm -rf "$target"
    fi
    
    # Create symlink
    ln -sf "$source" "$target"
    print_info "Created symlink: $target -> $source"
}

# Main installation
main() {
    print_info "Starting dotfiles installation..."
    
    # Create backup directory
    create_backup_dir
    
    # Install bash configuration
    if [ -f "$DOTFILES_DIR/.bashrc" ]; then
        create_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
    fi
    
    # Install git configuration
    if [ -f "$DOTFILES_DIR/.gitconfig" ]; then
        create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    fi
    
    if [ -f "$DOTFILES_DIR/.gitignore_global" ]; then
        create_symlink "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
    fi
    
    # Install vim configuration
    if [ -f "$DOTFILES_DIR/.vimrc" ]; then
        create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
    fi
    
    # Install tmux configuration
    if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then
        create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    fi
    
    # Setup git local configuration
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        if [ -f "$DOTFILES_DIR/.gitconfig.local.example" ]; then
            cp "$DOTFILES_DIR/.gitconfig.local.example" "$HOME/.gitconfig.local"
            print_info "Created ~/.gitconfig.local from template"
            print_warning "Please update ~/.gitconfig.local with your personal information:"
            print_warning "  git config --file ~/.gitconfig.local user.name \"Your Name\""
            print_warning "  git config --file ~/.gitconfig.local user.email \"your.email@example.com\""
        fi
    else
        print_info "~/.gitconfig.local already exists, skipping"
    fi
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Link .config subdirectories
    if [ -d "$DOTFILES_DIR/.config" ]; then
        for config in "$DOTFILES_DIR/.config"/*; do
            if [ -d "$config" ]; then
                config_name=$(basename "$config")
                create_symlink "$config" "$HOME/.config/$config_name"
            fi
        done
    fi
    
    # Make scripts executable
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        chmod +x "$DOTFILES_DIR/scripts"/*.sh 2>/dev/null || true
        print_info "Made scripts executable"
    fi

    # Link select utility scripts into ~/.local/bin for easy access
    mkdir -p "$HOME/.local/bin"
    if [ -f "$DOTFILES_DIR/scripts/gh-pr-review-summary.sh" ]; then
        create_symlink "$DOTFILES_DIR/scripts/gh-pr-review-summary.sh" "$HOME/.local/bin/gh-pr-review"
    fi
    
    print_info "Installation completed!"
    print_info "Backup of existing files saved to: $BACKUP_DIR"
    print_warning "Please restart your shell or run 'source ~/.bashrc' to apply changes"
    
    # Suggest next actions
    echo ""
    print_info "Suggested next actions:"
    echo ""
    
    # Check if git signing is set up
    if [ ! -f "$HOME/.gitconfig.local" ] || ! git config --file "$HOME/.gitconfig.local" user.signingkey >/dev/null 2>&1; then
        echo "  1. Set up Git commit signing (recommended for GitHub):"
        echo -e "     ${GREEN}./scripts/setup-git-signing.sh${NC}"
        echo ""
    fi
    
    # Check if SSH keys exist
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        echo "  2. Generate SSH keys for Git authentication:"
        echo -e "     ${GREEN}ssh-keygen -t ed25519 -C \"your-email@example.com\"${NC}"
        echo ""
    fi
    
    # Check if running on WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "  3. Set up SSH access to WSL2 from LAN devices:"
        echo -e "     ${GREEN}./scripts/setup-wsl2-ssh.sh${NC}"
        echo ""
    fi
    
    # Check if GPG is installed but not configured
    if command -v gpg >/dev/null 2>&1 && ! gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
        echo "  4. Import existing GPG keys:"
        echo -e "     ${GREEN}./scripts/gpg-import.sh${NC}"
        echo ""
    fi
    
    # General maintenance scripts
    echo "  5. Available utility scripts:"
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        for script in "$DOTFILES_DIR/scripts"/*.sh; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                script_name=$(basename "$script")
                case "$script_name" in
                    "setup-git-signing.sh")
                        [ -f "$HOME/.gitconfig.local" ] && git config --file "$HOME/.gitconfig.local" user.signingkey >/dev/null 2>&1 && continue
                        echo -e "     - ${GREEN}$script_name${NC}: Set up Git commit signing"
                        ;;
                    "gpg-export.sh")
                        echo -e "     - ${GREEN}$script_name${NC}: Export GPG keys for backup"
                        ;;
                    "gpg-import.sh")
                        echo -e "     - ${GREEN}$script_name${NC}: Import GPG keys from backup"
                        ;;
                    "setup-wsl2-ssh.sh")
                        grep -qi microsoft /proc/version 2>/dev/null || continue
                        echo -e "     - ${GREEN}$script_name${NC}: Configure SSH access to WSL2"
                        ;;
                    "setup-wsl2-ssh-elevated.ps1")
                        # Skip PowerShell scripts in this list
                        continue
                        ;;
                    *)
                        # Show other scripts without description
                        echo -e "     - ${GREEN}$script_name${NC}"
                        ;;
                esac
            fi
        done
    fi
    
    echo ""
    print_info "For more information about any script, run it with --help"
}

# Run main function
main "$@"
