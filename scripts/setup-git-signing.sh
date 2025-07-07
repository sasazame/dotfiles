#!/bin/bash

# GitHub Signed Commits Auto Setup Script

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Delete existing GPG keys
delete_gpg_keys() {
    echo_info "Deleting existing GPG keys..."
    
    # Get all secret key fingerprints
    local fingerprints=$(gpg --list-secret-keys --with-colons | grep '^fpr' | cut -d':' -f10)
    
    if [[ -z "$fingerprints" ]]; then
        echo_info "No GPG keys found to delete"
        return
    fi
    
    # Delete each key
    for fingerprint in $fingerprints; do
        echo_info "Deleting key: $fingerprint"
        gpg --batch --yes --delete-secret-and-public-key "$fingerprint"
    done
    
    echo_info "All GPG keys have been deleted"
}

# 1. GPG key setup
setup_gpg_key() {
    echo_info "Starting GPG key setup..."
    
    # Check for existing GPG keys
    if gpg --list-secret-keys --keyid-format=long | grep -q "sec"; then
        echo_info "Existing GPG keys found:"
        gpg --list-secret-keys --keyid-format=long
        
        echo "What would you like to do?"
        echo "1) Use existing key"
        echo "2) Delete all keys and create new one"
        echo "3) Create additional key"
        echo -n "Select option (1/2/3): "
        read -r key_option
        
        case "$key_option" in
            1)
                # Get existing key ID
                GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
                echo_info "Using key ID: $GPG_KEY_ID"
                return
                ;;
            2)
                delete_gpg_keys
                ;;
            3)
                echo_info "Creating additional GPG key..."
                ;;
            *)
                echo_error "Invalid option. Using existing key."
                GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
                return
                ;;
        esac
    fi
    
    # Generate new GPG key
    echo_info "Generating new GPG key..."
    
    # Get user information from .gitconfig.local
    CURRENT_NAME=$(git config --file "$HOME/.gitconfig.local" user.name 2>/dev/null || echo "")
    CURRENT_EMAIL=$(git config --file "$HOME/.gitconfig.local" user.email 2>/dev/null || echo "")
    
    # Ask for name
    if [[ -n "$CURRENT_NAME" ]]; then
        echo_info "Current name: $CURRENT_NAME"
        echo -n "Use this name? (y/n): "
        read -r use_current_name
        if [[ "$use_current_name" != "y" ]]; then
            echo -n "Enter new name: "
            read -r GIT_NAME
        else
            GIT_NAME="$CURRENT_NAME"
        fi
    else
        echo -n "Enter your name: "
        read -r GIT_NAME
    fi
    # Write to .gitconfig.local instead of global config
    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
        touch "$HOME/.gitconfig.local"
    fi
    git config --file "$HOME/.gitconfig.local" user.name "$GIT_NAME"
    
    # Ask for email
    if [[ -n "$CURRENT_EMAIL" ]]; then
        echo_info "Current email: $CURRENT_EMAIL"
        echo -n "Use this email? (y/n): "
        read -r use_current_email
        if [[ "$use_current_email" != "y" ]]; then
            echo -n "Enter new email: "
            read -r GIT_EMAIL
        else
            GIT_EMAIL="$CURRENT_EMAIL"
        fi
    else
        echo -n "Enter your email: "
        read -r GIT_EMAIL
    fi
    git config --file "$HOME/.gitconfig.local" user.email "$GIT_EMAIL"
    
    echo_info "Name: $GIT_NAME"
    echo_info "Email: $GIT_EMAIL"
    
    # Create GPG key generation batch file
    cat > /tmp/gpg_batch.txt <<EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $GIT_NAME
Name-Email: $GIT_EMAIL
Expire-Date: 2y
%no-protection
%commit
%echo done
EOF
    
    # Generate GPG key
    gpg --batch --generate-key /tmp/gpg_batch.txt
    rm -f /tmp/gpg_batch.txt
    
    # Get newly generated key ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    echo_info "New GPG key generated: $GPG_KEY_ID"
}

# 2. Configure Git GPG settings
configure_git_gpg() {
    echo_info "Configuring Git GPG settings..."
    
    # Set GPG key for Git in .gitconfig.local
    git config --file "$HOME/.gitconfig.local" user.signingkey "$GPG_KEY_ID"
    
    # Enable automatic commit signing (already in .gitconfig)
    # git config --global commit.gpgsign true
    
    # Set GPG program path if available (already in .gitconfig)
    # if command -v gpg >/dev/null 2>&1; then
    #     git config --global gpg.program "$(command -v gpg)"
    # fi
    
    echo_info "Note: commit.gpgsign and gpg.program are already configured in the dotfiles .gitconfig"
    
    echo_info "Git GPG configuration completed"
}

# 3. Add public key to GitHub
add_key_to_github() {
    echo_info "Adding public key to GitHub..."
    
    # Export public key
    GPG_PUBLIC_KEY=$(gpg --armor --export "$GPG_KEY_ID")
    
    echo_info "Add the following public key to GitHub:"
    echo "========================================="
    echo "$GPG_PUBLIC_KEY"
    echo "========================================="
    
    echo_info "Steps to add to GitHub:"
    echo "1. Go to https://github.com/settings/keys"
    echo "2. Click 'New GPG key'"
    echo "3. Copy and paste the public key above"
    echo "4. Click 'Add GPG key'"
    
    # Save public key to file
    mkdir -p "gpg-keys"
    echo "$GPG_PUBLIC_KEY" > "gpg-keys/public_key_${GPG_KEY_ID}.asc"
    echo_info "Public key saved to: $(pwd)/gpg-keys/public_key_${GPG_KEY_ID}.asc"
    
    # Copy to clipboard if possible
    if command -v xclip >/dev/null 2>&1; then
        echo "$GPG_PUBLIC_KEY" | xclip -selection clipboard
        echo_info "Public key copied to clipboard"
    elif command -v pbcopy >/dev/null 2>&1; then
        echo "$GPG_PUBLIC_KEY" | pbcopy
        echo_info "Public key copied to clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        echo "$GPG_PUBLIC_KEY" | wl-copy
        echo_info "Public key copied to clipboard"
    fi
}

# 4. Setup GPG agent
setup_gpg_agent() {
    echo_info "Setting up GPG agent..."
    
    # Create GPG agent configuration
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
    
    # Configure gpg-agent.conf
    cat > "$HOME/.gnupg/gpg-agent.conf" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program /usr/bin/pinentry-curses
EOF
    
    # Restart GPG agent
    echo_info "Restarting GPG agent..."
    gpgconf --kill gpg-agent 2>/dev/null || true
    gpg-agent --daemon 2>/dev/null || true
    
    echo_info "GPG agent configuration completed"
}

# 5. Verify setup
verify_setup() {
    echo_info "Verifying setup..."
    
    echo "Git configuration:"
    git config --file "$HOME/.gitconfig.local" --get user.name
    git config --file "$HOME/.gitconfig.local" --get user.email
    git config --file "$HOME/.gitconfig.local" --get user.signingkey
    git config --global --get commit.gpgsign
    
    echo ""
    echo "GPG keys:"
    gpg --list-secret-keys --keyid-format=long
    
    # Test commit
    echo -n "Create a test commit? (y/n): "
    read -r create_test
    
    if [[ "$create_test" == "y" ]]; then
        TEST_DIR="/tmp/git-sign-test-$$"
        mkdir -p "$TEST_DIR"
        cd "$TEST_DIR"
        
        git init
        echo "Test file" > test.txt
        git add test.txt
        
        if git commit -S -m "Test signed commit"; then
            echo_info "Signed commit created successfully!"
            git log --show-signature -1
        else
            echo_error "Failed to create signed commit"
        fi
        
        cd - >/dev/null
        rm -rf "$TEST_DIR"
    fi
}

# Main process
main() {
    echo "================================================"
    echo "GitHub Signed Commits Auto Setup Script"
    echo "================================================"
    echo ""
    
    # Check if GPG is installed
    if ! command -v gpg >/dev/null 2>&1; then
        echo_error "GPG is not installed"
        echo_info "Installation instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install gnupg"
        echo "  macOS: brew install gnupg"
        exit 1
    fi
    
    # Execute each step
    setup_gpg_key
    configure_git_gpg
    add_key_to_github
    setup_gpg_agent
    verify_setup
    
    echo ""
    echo_info "Setup completed!"
    echo_info "Your future commits will be automatically signed."
    echo_warning "Don't forget to add your public key to GitHub!"
}

# Run the script
main