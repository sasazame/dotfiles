#!/bin/bash
# setup-wsl2-ssh.sh - Automatic SSH port forwarding setup for WSL2

# Get WSL2 IP address
WSL_IP=$(hostname -I | awk '{print $1}')
LISTEN_PORT=2222
WINDOWS_IP="0.0.0.0"

echo "Setting up SSH port forwarding for WSL2..."
echo "WSL2 IP: $WSL_IP"

# Check if SSH is installed
if ! command -v sshd &> /dev/null; then
    echo "OpenSSH server not installed. Please install it first:"
    echo "  sudo apt update && sudo apt install openssh-server"
    exit 1
fi

# Start SSH service if not running
if ! sudo service ssh status > /dev/null 2>&1; then
    echo "Starting SSH service..."
    sudo service ssh start
fi

# Try to configure port forwarding
echo "Attempting to configure port forwarding..."

# Check if we can run elevated commands
CAN_ELEVATE=$(powershell.exe -Command "([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')" | tr -d '\r\n')

if [ "$CAN_ELEVATE" = "True" ]; then
    # Running with admin privileges
    echo "Running with administrator privileges..."
    
    # Remove existing port proxy rule
    powershell.exe -Command "netsh interface portproxy delete v4tov4 listenport=$LISTEN_PORT listenaddress=$WINDOWS_IP" 2>/dev/null
    
    # Add new port proxy rule
    powershell.exe -Command "netsh interface portproxy add v4tov4 listenport=$LISTEN_PORT listenaddress=$WINDOWS_IP connectport=22 connectaddress=$WSL_IP"
    
    # Add firewall rule if needed
    FIREWALL_EXISTS=$(powershell.exe -Command "Get-NetFirewallRule -DisplayName 'WSL2 SSH' -ErrorAction SilentlyContinue" | grep -c "WSL2 SSH")
    if [ $FIREWALL_EXISTS -eq 0 ]; then
        powershell.exe -Command "New-NetFirewallRule -DisplayName 'WSL2 SSH' -Direction Inbound -Protocol TCP -LocalPort $LISTEN_PORT -Action Allow" > /dev/null
    fi
    
    echo "✓ Port forwarding configured successfully!"
    
else
    # Need to elevate
    echo "Administrator privileges required for port forwarding configuration."
    echo ""
    echo "Option 1: Run the elevated PowerShell script manually:"
    echo "  1. Open PowerShell as Administrator"
    echo "  2. Run: cd $(wslpath -w $(dirname $(readlink -f $0)))"
    echo "  3. Run: .\\setup-wsl2-ssh-elevated.ps1 -WslIp $WSL_IP"
    echo ""
    echo "Option 2: Let this script open an elevated PowerShell window:"
    echo -n "Would you like to open an elevated PowerShell window now? (y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Convert script path to Windows path
        SCRIPT_DIR=$(dirname $(readlink -f $0))
        WINDOWS_SCRIPT_DIR=$(wslpath -w "$SCRIPT_DIR")
        
        # Launch elevated PowerShell
        powershell.exe -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"$WINDOWS_SCRIPT_DIR\\setup-wsl2-ssh-elevated.ps1\" -WslIp $WSL_IP' -Verb RunAs"
        
        echo ""
        echo "Elevated PowerShell window opened. Please check if the configuration was successful."
    fi
fi

# Show current configuration
echo ""
echo "Current port forwarding rules:"
powershell.exe -Command "netsh interface portproxy show v4tov4" | grep -E "$LISTEN_PORT|Listen" || echo "No rules configured"

# Get Windows host IP for reference
WINDOWS_HOST_IP=$(powershell.exe -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {\$_.InterfaceAlias -notlike '*WSL*' -and \$_.IPAddress -notlike '127.*'} | Select-Object -First 1).IPAddress" | tr -d '\r\n')
echo ""
echo "To connect via SSH from another machine:"
echo "  ssh -p $LISTEN_PORT $USER@$WINDOWS_HOST_IP"