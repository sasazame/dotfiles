#!/bin/bash

# Fix GPG key to include GitHub noreply email
# This script adds the GitHub noreply email as an additional UID to your existing GPG key

GPG_KEY_ID="A177DE22089CB991"
GITHUB_EMAIL="sasazame@users.noreply.github.com"
REAL_NAME="sasazame"

echo "Adding GitHub noreply email to GPG key..."

# Create a temporary file with GPG edit commands
cat > /tmp/gpg_commands.txt << EOF
adduid
$REAL_NAME
$GITHUB_EMAIL

save
EOF

# Execute the commands
gpg --command-fd 0 --edit-key "$GPG_KEY_ID" < /tmp/gpg_commands.txt

# Clean up
rm -f /tmp/gpg_commands.txt

echo "Exporting updated public key..."
gpg --armor --export "$GPG_KEY_ID" > ~/gpg_key_with_github_email.asc

echo "Success! Your GPG key now includes the GitHub noreply email."
echo ""
echo "Next steps:"
echo "1. Go to https://github.com/settings/keys"
echo "2. Delete your old GPG key if one exists"
echo "3. Click 'New GPG key'"
echo "4. Copy and paste the contents of ~/gpg_key_with_github_email.asc"
echo "5. Save the key"
echo ""
echo "After this, new commits will be verified on GitHub!"