# WSL2 SSH Setup Guide

This guide explains how to set up SSH access to WSL2 Ubuntu from other devices on the same local network.

## Prerequisites

- Windows 10/11 with WSL2 installed
- Ubuntu running on WSL2
- Administrator access to Windows
- Another device on the same LAN to test SSH connection

## Setup Steps

### 1. Install OpenSSH Server on WSL2

Open your WSL2 Ubuntu terminal and run:

```bash
sudo apt update
sudo apt install openssh-server
```

### 2. Configure SSH Service

Start the SSH service:

```bash
sudo service ssh start
```

To make SSH start automatically when WSL2 starts, add this to your `.bashrc`:

```bash
echo "sudo service ssh start" >> ~/.bashrc
```

### 3. Get WSL2 IP Address

Find your WSL2 internal IP address:

```bash
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
```

Note: This IP address changes every time WSL2 restarts.

### 4. Configure Windows Port Forwarding

Open PowerShell as Administrator and run:

```powershell
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=<WSL2_IP>
```

Replace `<WSL2_IP>` with the IP address from step 3.

To view current port proxy rules:

```powershell
netsh interface portproxy show all
```

### 5. Configure Windows Firewall

Allow inbound connections on port 2222:

```powershell
New-NetFirewallRule -DisplayName "WSL2 SSH" -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow
```

### 6. Find Windows Host IP Address

On Windows, find your LAN IP address:

```powershell
ipconfig
```

Look for the IPv4 address under your active network adapter (usually Ethernet or Wi-Fi).

## Connecting via SSH

From another device on the same network:

```bash
ssh -p 2222 <username>@<windows_host_ip>
```

Example:
```bash
ssh -p 2222 sasazame@192.168.1.100
```

## File Transfer

### Using SCP

Copy file to WSL2:
```bash
scp -P 2222 /path/to/local/file <username>@<windows_host_ip>:/path/to/destination
```

Copy file from WSL2:
```bash
scp -P 2222 <username>@<windows_host_ip>:/path/to/remote/file /path/to/local/destination
```

### Using SFTP

```bash
sftp -P 2222 <username>@<windows_host_ip>
```

## Automation Script

A fully automated script is available that handles everything from WSL2:

```bash
# Run the automated setup script
./scripts/setup-wsl2-ssh.sh
```

This script:
- Automatically detects WSL2 IP address
- Configures Windows port forwarding using PowerShell
- Starts SSH service if needed
- Sets up Windows firewall rules
- Verifies the configuration

To run automatically on WSL2 startup, add to your `.bashrc` or `.zshrc`:

```bash
# Auto-setup SSH on WSL2 start
if [ -f ~/git/dotfiles/scripts/setup-wsl2-ssh.sh ]; then
    ~/git/dotfiles/scripts/setup-wsl2-ssh.sh > /dev/null 2>&1
fi
```

Note: The first run may require administrator privileges for firewall configuration.

## Troubleshooting

### SSH service not running
```bash
sudo service ssh status
sudo service ssh start
```

### Permission denied
- Check SSH configuration: `sudo nano /etc/ssh/sshd_config`
- Ensure `PasswordAuthentication yes` is set
- Restart SSH: `sudo service ssh restart`

### Connection refused
1. Verify port forwarding: `netsh interface portproxy show all`
2. Check Windows Firewall rules
3. Ensure SSH service is running in WSL2

### WSL2 IP changes frequently
Consider using Task Scheduler to run the update script on Windows startup.

## Security Recommendations

1. Use SSH keys instead of passwords
2. Change default SSH port if needed
3. Limit SSH access to specific users
4. Keep your system updated

## Additional Resources

- [Microsoft WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [OpenSSH Documentation](https://www.openssh.com/manual.html)