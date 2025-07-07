# WSL2 IP Address Management

## Why WSL2 IP Changes

WSL2 runs in a lightweight virtual machine with its own virtual network adapter. The IP address is dynamically assigned by Windows' virtual switch each time WSL2 starts, which is why it changes.

## Static IP: Not Recommended

### Why Microsoft Doesn't Recommend Static IP

1. **Design Philosophy**: WSL2 is designed to be dynamically managed by Windows
2. **Network Conflicts**: Static IPs can conflict with Windows' virtual network management
3. **Updates**: Windows updates may reset or break static IP configurations
4. **Hyper-V Integration**: WSL2 uses Hyper-V's dynamic networking features

### Potential Issues with Static IP

- Network connectivity problems
- DNS resolution failures
- WSL2 failing to start
- Conflicts with other Hyper-V VMs or containers

## Recommended Alternatives

### 1. Automatic Port Forwarding Script

Create a PowerShell script that runs on WSL2 startup:

```powershell
# auto-portforward.ps1
$wsl_ip = (wsl hostname -I).trim()
$windows_ip = "0.0.0.0"

# Remove existing rules
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=$windows_ip

# Add new rule with current WSL2 IP
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=$windows_ip connectport=22 connectaddress=$wsl_ip
```

### 2. Use localhost with WSLg (Windows 11)

On Windows 11, WSLg provides better localhost integration:

```bash
# From Windows
ssh -p 22 username@localhost
```

### 3. Dynamic DNS Solution

Create a script that updates a hosts file entry:

```bash
#!/bin/bash
# update-wsl-host.sh
WSL_IP=$(hostname -I | awk '{print $1}')
echo "$WSL_IP wsl.local" | sudo tee /etc/hosts
```

### 4. Use WSL2 Bridge Mode (Experimental)

Some users use bridge mode networking, but this is:
- Not officially supported
- May break with updates
- Requires manual configuration

## Best Practice: Embrace Dynamic IP

Instead of fighting WSL2's design, use automation:

1. **Task Scheduler**: Run port forwarding script on Windows startup
2. **WSL Boot Script**: Add to `/etc/wsl.conf`:
   ```ini
   [boot]
   command = /usr/local/bin/setup-network.sh
   ```

3. **Alias/Function**: Create a bash function to get current IP:
   ```bash
   wslip() {
       hostname -I | awk '{print $1}'
   }
   ```

## Conclusion

While technically possible to set a static IP for WSL2, it's not recommended because:
- It goes against WSL2's architecture
- It may cause stability issues
- Microsoft doesn't support it
- Better alternatives exist

Use port forwarding and automation instead of static IPs for a more reliable setup.