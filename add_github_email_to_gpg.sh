#!/bin/bash

# Add GitHub noreply email to GPG key
cat > /tmp/gpg_adduid <<EOF
adduid
sasazame
sasazame@users.noreply.github.com
O
save
EOF

gpg --command-file /tmp/gpg_adduid --edit-key A177DE22089CB991

# Clean up
rm -f /tmp/gpg_adduid

echo "Email added. Now exporting the updated public key..."
gpg --armor --export A177DE22089CB991 > ~/gpg_public_key_with_github.asc

echo "Updated GPG public key saved to ~/gpg_public_key_with_github.asc"
echo "Please add this key to your GitHub account at: https://github.com/settings/keys"