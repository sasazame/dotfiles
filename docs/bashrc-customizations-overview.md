# Bashrc Customizations Overview

This document provides an overview of all customizations in the `.bashrc` file.

## 1. History Management (Enhanced)

### Standard History Features
- **Large history size**: 100,000 commands in memory, 200,000 in file
- **Deduplication**: Removes duplicate commands (`erasedups`)
- **Privacy**: Commands starting with space are ignored (`ignorespace`)
- **Timestamps**: Shows execution date/time for each command
- **Real-time sharing**: History syncs across terminal sessions instantly

### Custom History Features
- **Directory-aware history**: Tracks where each command was executed
- **Custom commands**:
  - `hist [keyword]` - Search history with directory info
  - `histhere` - Show commands from current directory only

📖 [Detailed Guide: Bash History Customization](bash-history-guide.md)

## 2. Shell Options

### Active Options
- `histappend` - Append to history file instead of overwriting
- `checkwinsize` - Update terminal dimensions after each command
- `cmdhist` - Save multi-line commands as single history entry

### Available but Disabled
- `globstar` - ** pattern matches files recursively (commented out)

## 3. Command Aliases

### File Operations
- `ll` - Detailed list with hidden files (`ls -alF`)
- `la` - List all except . and .. (`ls -A`)
- `l` - Compact list (`ls -CF`)

### Color Support
- `ls` - Colored file listings
- `grep`, `fgrep`, `egrep` - Colored search results

### Utilities
- `alert` - Desktop notification for completed commands
  ```bash
  sleep 10; alert  # Notifies when sleep finishes
  ```

## 4. Prompt Customization

### Features
- **Color support**: Green username@hostname, blue current directory
- **Terminal title**: Shows `user@host: directory` in window title
- **Chroot indicator**: Shows if working in chroot environment

### Format
```
username@hostname:~/current/directory$ 
```

## 5. PATH Configuration

Added to PATH in order:
1. `$HOME/.local/bin` - User's local binaries
2. `~/.npm-global/bin` - Global npm packages
3. `$HOME/.cargo/bin` - Rust/Cargo binaries

## 6. External Integrations

### Conditional Loading
- **Bash aliases**: Sources `~/.bash_aliases` if exists
- **Bash completion**: Loads system completion scripts
- **Less preprocessor**: Enables viewing compressed files

### Color Configuration
- **dircolors**: Custom directory colors (reads `~/.dircolors` if exists)
- **GCC colors**: Colored compiler output (disabled by default)

## 7. Terminal Behavior

### Interactive Shell Detection
- Only loads configurations for interactive sessions
- Prevents issues with non-interactive scripts

### Display Management
- Auto-adjusts to terminal resizing
- Supports 256-color terminals
- Sets appropriate terminal title for xterm/rxvt

## Quick Reference

### Most Useful Custom Features
1. **Search command history**: `hist docker`
2. **Current directory history**: `histhere`
3. **Hide sensitive commands**: ` command` (space prefix)
4. **Quick directory listing**: `ll`, `la`, `l`

### Performance Tips
- History operations are optimized for large files
- Deduplication runs automatically to save space
- Real-time sync has minimal overhead

## Customization Guide

To add your own customizations:
1. Edit `~/.bashrc` directly, or
2. Create `~/.bash_aliases` for additional aliases
3. Use `~/.bashrc.local` for machine-specific settings (if implemented)