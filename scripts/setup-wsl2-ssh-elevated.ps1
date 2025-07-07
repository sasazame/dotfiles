# setup-wsl2-ssh-elevated.ps1
# PowerShell script to run with elevated privileges

param(
    [string]$WslIp,
    [int]$ListenPort = 2222
)

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

Write-Host "Configuring WSL2 SSH port forwarding..." -ForegroundColor Green
Write-Host "WSL2 IP: $WslIp"
Write-Host "Listen Port: $ListenPort"

# Remove existing port proxy rule
Write-Host "Removing existing port forwarding rule..."
netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 2>$null

# Add new port proxy rule
Write-Host "Adding new port forwarding rule..."
netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 connectport=22 connectaddress=$WslIp

# Show current rules
Write-Host "`nCurrent port forwarding rules:" -ForegroundColor Yellow
netsh interface portproxy show v4tov4

# Check/Add firewall rule
$firewallRule = Get-NetFirewallRule -DisplayName "WSL2 SSH" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    Write-Host "`nAdding firewall rule..." -ForegroundColor Green
    New-NetFirewallRule -DisplayName "WSL2 SSH" -Direction Inbound -Protocol TCP -LocalPort $ListenPort -Action Allow
} else {
    Write-Host "`nFirewall rule already exists" -ForegroundColor Green
}

Write-Host "`nConfiguration complete!" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")