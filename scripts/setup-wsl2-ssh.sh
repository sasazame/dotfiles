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
# Try multiple methods to get the correct IP
WINDOWS_HOST_IP=""

# Method 1: Try to get IP from active network adapters
WINDOWS_HOST_IP=$(powershell.exe -Command "
    \$adapters = Get-NetAdapter | Where-Object {
        \$_.Status -eq 'Up' -and 
        \$_.Name -notlike '*WSL*' -and 
        \$_.Name -notlike '*Loopback*'
    }
    foreach (\$adapter in \$adapters) {
        \$ip = Get-NetIPAddress -InterfaceIndex \$adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
               Where-Object { \$_.IPAddress -notlike '127.*' -and \$_.IPAddress -notlike '169.254.*' }
        if (\$ip) {
            Write-Output \$ip.IPAddress
            break
        }
    }
" 2>/dev/null | tr -d '\r\n' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -n1)

# Method 2: If method 1 fails, try parsing ipconfig
if [ -z "$WINDOWS_HOST_IP" ]; then
    WINDOWS_HOST_IP=$(powershell.exe -Command "ipconfig" 2>/dev/null | grep -A4 "Ethernet\|Wi-Fi\|Wireless" | grep -E "IPv4.*: [0-9]" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -v '^127\.' | grep -v '^169\.254\.' | head -n1)
fi

# Method 3: If still no IP, get the default gateway's interface IP
if [ -z "$WINDOWS_HOST_IP" ]; then
    WINDOWS_HOST_IP=$(powershell.exe -Command "
        \$gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object -Property InterfaceMetric | Select-Object -First 1
        if (\$gateway) {
            \$ip = Get-NetIPAddress -InterfaceIndex \$gateway.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
                   Where-Object { \$_.IPAddress -notlike '127.*' -and \$_.IPAddress -notlike '169.254.*' }
            if (\$ip) { Write-Output \$ip.IPAddress }
        }
    " 2>/dev/null | tr -d '\r\n' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -n1)
fi

# Display connection information
echo ""
if [ -n "$WINDOWS_HOST_IP" ]; then
    echo "To connect via SSH from another machine:"
    echo "  ssh -p $LISTEN_PORT $USER@$WINDOWS_HOST_IP"
else
    echo "Could not automatically determine Windows host IP address."
    echo ""
    echo "To find your Windows IP address manually:"
    echo "  1. Open Command Prompt or PowerShell on Windows"
    echo "  2. Run: ipconfig"
    echo "  3. Look for your active network adapter (Ethernet or Wi-Fi)"
    echo "  4. Use the IPv4 Address shown there"
    echo ""
    echo "Then connect with:"
    echo "  ssh -p $LISTEN_PORT $USER@<YOUR_WINDOWS_IP>"
fi

