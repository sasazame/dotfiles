#!/bin/bash

# GPG Key Import Script (Standalone)

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

main() {
    echo "================================"
    echo "GPG Key Import Script"
    echo "================================"
    echo ""
    
    # Check for import file
    if [[ $# -lt 1 ]]; then
        echo_error "Usage: $0 <gpg-backup.tar.gz> or <private-key.asc>"
        exit 1
    fi
    
    IMPORT_FILE="$1"
    
    if [[ ! -f "$IMPORT_FILE" ]]; then
        echo_error "File not found: $IMPORT_FILE"
        exit 1
    fi
    
    # Handle different file types
    if [[ "$IMPORT_FILE" == *.tar.gz ]]; then
        echo_info "Extracting archive..."
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$IMPORT_FILE" -C "$TEMP_DIR"
        
        # Find the extracted directory
        EXTRACT_DIR=$(find "$TEMP_DIR" -name "gpg-backup-*" -type d | head -1)
        
        if [[ -z "$EXTRACT_DIR" ]]; then
            echo_error "Invalid archive format"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        # Import from extracted files
        echo_info "Importing private key..."
        gpg --import "$EXTRACT_DIR/private.asc"
        
        if [[ -f "$EXTRACT_DIR/trust.txt" ]]; then
            echo_info "Importing trust database..."
            gpg --import-ownertrust "$EXTRACT_DIR/trust.txt"
        fi
        
        rm -rf "$TEMP_DIR"
        
    elif [[ "$IMPORT_FILE" == *.asc ]] || [[ "$IMPORT_FILE" == *.gpg ]]; then
        echo_info "Importing key file..."
        gpg --import "$IMPORT_FILE"
    else
        echo_error "Unsupported file format. Use .tar.gz, .asc, or .gpg"
        exit 1
    fi
    
    # List imported keys
    echo_info "Imported keys:"
    gpg --list-secret-keys --keyid-format=long
    
    # Configure Git
    echo -n "Configure Git to use this key? (y/n): "
    read -r configure_git
    
    if [[ "$configure_git" == "y" ]]; then
        # Get key ID
        KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        
        if [[ -z "$KEY_ID" ]]; then
            echo_error "No secret key found"
            exit 1
        fi
        
        echo_info "Configuring Git..."
        git config --global user.signingkey "$KEY_ID"
        git config --global commit.gpgsign true
        git config --global gpg.program "$(command -v gpg)"
        
        echo_info "Git configured with key: $KEY_ID"
        
        # Show current Git config
        echo ""
        echo "Current Git configuration:"
        echo "Name: $(git config --global user.name)"
        echo "Email: $(git config --global user.email)"
        echo "Signing key: $(git config --global user.signingkey)"
        echo "Auto-sign commits: $(git config --global commit.gpgsign)"
    fi
    
    echo ""
    echo_info "Import completed!"
    echo_info "Your GPG key is now available on this machine."
}

main "$@"