#!/bin/bash

# GPG Backup Secure Transfer Script

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo_method() {
    echo -e "${BLUE}[METHOD]${NC} $1"
}

show_transfer_methods() {
    echo "================================================"
    echo "GPG Backup Transfer Methods (Ranked by Security)"
    echo "================================================"
    echo ""
    
    # Check if file exists
    if [[ $# -lt 1 ]]; then
        echo_error "Usage: $0 <gpg-backup.tar.gz>"
        exit 1
    fi
    
    BACKUP_FILE="$1"
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo_error "File not found: $BACKUP_FILE"
        exit 1
    fi
    
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo_info "File: $BACKUP_FILE ($FILE_SIZE)"
    echo ""
    
    # 1. USB Drive (Most Secure)
    echo_method "1. USB Drive / Physical Media (Most Secure)"
    echo "   - Copy to USB drive and physically transfer"
    echo "   - No network exposure"
    echo "   Commands:"
    echo "     cp $BACKUP_FILE /media/usb/"
    echo ""
    
    # 2. SSH/SCP (Secure)
    echo_method "2. Direct SSH/SCP Transfer (Secure)"
    echo "   - Encrypted transfer over network"
    echo "   - Requires SSH access to target machine"
    echo "   Commands:"
    echo "     scp $BACKUP_FILE user@hostname:~/"
    echo "     # or with specific port"
    echo "     scp -P 2222 $BACKUP_FILE user@hostname:~/"
    echo ""
    
    # 3. Encrypted Archive + Cloud (Moderately Secure)
    echo_method "3. Encrypted Archive + Cloud Storage"
    echo "   - Add password protection before uploading"
    echo "   Commands:"
    echo "     # Encrypt with password"
    echo "     gpg -c $BACKUP_FILE"
    echo "     # Creates ${BACKUP_FILE}.gpg"
    echo "     # Then upload to cloud (Dropbox, Google Drive, etc.)"
    echo "     # On target machine:"
    echo "     gpg -d ${BACKUP_FILE}.gpg > $BACKUP_FILE"
    echo ""
    
    # 4. Git Private Repo (For small files)
    echo_method "4. Private Git Repository"
    echo "   - Only for small backups"
    echo "   - Must be PRIVATE repository"
    echo "   Commands:"
    echo "     # In a private repo"
    echo "     git add $BACKUP_FILE"
    echo "     git commit -m \"Add GPG backup (PRIVATE)\""
    echo "     git push"
    echo ""
    
    # 5. Magic Wormhole (Easy P2P)
    echo_method "5. Magic Wormhole (Easy P2P Transfer)"
    echo "   - Direct peer-to-peer encrypted transfer"
    echo "   - No account needed"
    echo "   Commands:"
    echo "     # Install: pip install magic-wormhole"
    echo "     wormhole send $BACKUP_FILE"
    echo "     # On target machine:"
    echo "     wormhole receive [code]"
    echo ""
    
    # 6. Create encrypted version
    echo_warning "Quick Encryption Option:"
    echo -n "Create encrypted version now? (y/n): "
    read -r encrypt_now
    
    if [[ "$encrypt_now" == "y" ]]; then
        echo_info "Creating encrypted version..."
        gpg -c "$BACKUP_FILE"
        echo_info "Encrypted file created: ${BACKUP_FILE}.gpg"
        echo_info "You'll need the password to decrypt on the target machine"
    fi
    
    echo ""
    echo_warning "Security Tips:"
    echo "- Delete the backup file after successful import"
    echo "- Use 'shred' instead of 'rm' for secure deletion:"
    echo "  shred -vfz -n 3 $BACKUP_FILE"
    echo "- Verify the GPG key after import on target machine"
}

# Run the script
show_transfer_methods "$@"