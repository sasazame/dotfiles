# WSL2 SSH Key Authentication Setup Guide

A guide for securely transferring SSH keys to WSL2 within a local network without using cloud services.

## Prerequisites
- SSH service is running on WSL2
- Port forwarding is configured with `scripts/setup-wsl2-ssh.sh`
- Windows host IP address is known

## Steps

### 1. Generate SSH Key on Client Machine

```bash
# Run on the client machine
ssh-keygen -t ed25519 -f ~/.ssh/wsl2_key -N ""
```

### 2. Connect to WSL2 via Password Authentication

```bash
# Replace <WINDOWS_IP> with the actual Windows host IP address
ssh -p 2222 sasazame@<WINDOWS_IP>
```

### 3. Encode Public Key with base64 in Another Terminal

Open a new terminal and run the following on the client machine:

```bash
# Encode the public key with base64
cat ~/.ssh/wsl2_key.pub | base64 -w 0
```

Copy the long string that is output.

### 4. Receive the Public Key on WSL2

Run the following in the SSH session connected in step 2:

```bash
# Decode the base64 string and append to authorized_keys
echo "paste the copied base64 string here" | base64 -d >> ~/.ssh/authorized_keys

# Set permissions
chmod 600 ~/.ssh/authorized_keys
```

### 5. Verify Key Authentication

Confirm that you can SSH connect with key authentication from the client:

```bash
# You should be able to connect without being prompted for a password
ssh -p 2222 -i ~/.ssh/wsl2_key sasazame@<WINDOWS_IP>
```

### 6. File Transfer with SCP/SFTP

Once key authentication is set up, you can use SCP/SFTP:

```bash
# Send file to WSL2
scp -P 2222 -i ~/.ssh/wsl2_key local_file.txt sasazame@<WINDOWS_IP>:/home/sasazame/

# Retrieve file from WSL2
scp -P 2222 -i ~/.ssh/wsl2_key sasazame@<WINDOWS_IP>:/home/sasazame/remote_file.txt ./

# Connect via SFTP
sftp -P 2222 -i ~/.ssh/wsl2_key sasazame@<WINDOWS_IP>
```

## SSH Config File Creation (Optional)

To avoid specifying options every time, add the following to `~/.ssh/config`:

```bash
# Add to ~/.ssh/config on the client
Host wsl2
    HostName <WINDOWS_IP>
    User sasazame
    Port 2222
    IdentityFile ~/.ssh/wsl2_key
```

Now you can connect easily:

```bash
ssh wsl2
scp file.txt wsl2:/home/sasazame/
sftp wsl2
```

## Troubleshooting

### Permission Errors
```bash
# Run on WSL2
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Connection Timeout
- Check if TCP port 2222 is allowed in Windows Firewall
- Re-run `scripts/setup-wsl2-ssh.sh` to reconfigure port forwarding

### base64 Command Not Available
```bash
# Alternative 1: Use Python
python3 -c "import base64; print(base64.b64encode(open('$HOME/.ssh/wsl2_key.pub', 'rb').read()).decode())"

# Alternative 2: Use openssl
openssl base64 -in ~/.ssh/wsl2_key.pub -A
```