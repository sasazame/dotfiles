#!/bin/bash

# GPG Key Export Script

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
    echo "GPG Key Export Script"
    echo "================================"
    echo ""
    
    # List available keys
    echo_info "Available GPG keys:"
    gpg --list-secret-keys --keyid-format=long
    
    # Get email or key ID
    echo -n "Enter email address or key ID to export: "
    read -r KEY_IDENTIFIER
    
    # Get key ID
    if [[ "$KEY_IDENTIFIER" =~ ^[A-F0-9]{16}$ ]]; then
        GPG_KEY_ID="$KEY_IDENTIFIER"
    else
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$KEY_IDENTIFIER" | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    fi
    
    if [[ -z "$GPG_KEY_ID" ]]; then
        echo_error "No key found for: $KEY_IDENTIFIER"
        exit 1
    fi
    
    echo_info "Exporting key: $GPG_KEY_ID"
    
    # Create export directory
    EXPORT_DIR="gpg-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$EXPORT_DIR"
    
    # Export public key
    echo_info "Exporting public key..."
    gpg --armor --export "$GPG_KEY_ID" > "$EXPORT_DIR/public.asc"
    
    # Export private key
    echo_info "Exporting private key..."
    echo_warning "You may be prompted for your GPG passphrase"
    gpg --armor --export-secret-keys "$GPG_KEY_ID" > "$EXPORT_DIR/private.asc"
    
    # Export trust database
    echo_info "Exporting trust database..."
    gpg --export-ownertrust > "$EXPORT_DIR/trust.txt"
    
    # Create import script
    cat > "$EXPORT_DIR/import.sh" <<'EOF'
#!/bin/bash

# GPG Key Import Script

set -e

echo "Importing GPG keys..."

# Import private key
gpg --import private.asc

# Import trust database
gpg --import-ownertrust trust.txt

# Get the imported key ID
KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)

# Configure Git
git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true
git config --global gpg.program "$(command -v gpg)"

echo "GPG key imported and Git configured!"
echo "Key ID: $KEY_ID"
EOF
    
    chmod +x "$EXPORT_DIR/import.sh"
    
    # Create tarball
    echo_info "Creating archive..."
    ARCHIVE_NAME="gpg-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$ARCHIVE_NAME" "$EXPORT_DIR"
    
    echo ""
    echo_info "Export completed!"
    echo_info "Files saved to: $(pwd)/$EXPORT_DIR"
    echo_info "Archive created: $(pwd)/$ARCHIVE_NAME"
    echo ""
    echo_warning "IMPORTANT: Keep these files secure! They contain your private key."
    echo_info "To import on another machine:"
    echo "  1. Copy the tarball to the new machine"
    echo "  2. Extract: tar -xzf gpg-backup-*.tar.gz"
    echo "  3. Run: cd gpg-backup-* && ./import.sh"
}

main