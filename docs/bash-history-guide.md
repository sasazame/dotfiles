# Bash History Customization Guide

This document explains the enhanced bash history features added to `.bashrc`.

## Overview

Solves history issues when using multiple terminal sessions and implements advanced history management with directory information.

## Features

### 1. Standard Bash History Enhancements

#### Timestamped History
```bash
$ history
 1001  2025-01-05 14:23:15 ls -la
 1002  2025-01-05 14:23:20 cd /home
 1003  2025-01-05 14:23:25 git status
```

#### Real-time History Sharing
- History is instantly shared between multiple terminal sessions
- Commands are available in other sessions immediately after execution

#### Deduplication
- Keeps only the latest occurrence of duplicate commands (`erasedups` option)
- Automatically removes consecutive duplicates

### 2. Directory-aware History (Custom Features)

#### `hist` Command
Search and display history with directory information.

```bash
# Show all history (last 50 entries)
$ hist

# Search by keyword
$ hist docker
2025-01-05 10:15:30 /home/user/project 1234 docker-compose up -d
2025-01-05 11:20:45 /home/user/test 1567 docker ps -a

# Search for commands containing specific filenames
$ hist requirements.txt
```

#### `histhere` Command
Show only commands executed in the current directory.

```bash
$ cd /home/user/project
$ histhere
2025-01-05 09:30:15 /home/user/project 1001 npm install
2025-01-05 09:35:20 /home/user/project 1002 npm run dev
2025-01-05 10:15:30 /home/user/project 1234 docker-compose up -d
```

### 3. History File Locations

- **`~/.bash_history`** - Standard bash history (without directory info)
- **`~/.bash_history_full`** - Custom history with directory information

## Configuration Details

### Environment Variables

```bash
# History size
HISTSIZE=100000          # Number of commands in memory
HISTFILESIZE=200000      # Number of commands saved to file

# Timestamp format
HISTTIMEFORMAT="%F %T "  # YYYY-MM-DD HH:MM:SS format

# History control
HISTCONTROL=ignoreboth:erasedups
# ignoreboth = ignore space-prefixed & consecutive duplicates
# erasedups = remove duplicates from entire history
```

### Deduplication Behavior

1. **Standard History (~/.bash_history)**
   - Keeps only the latest occurrence of each command
   - Removes duplicates regardless of directory

2. **Custom History (~/.bash_history_full)**
   - Removes duplicates based on directory + command combination
   - Same command in different directories is kept separately

## Usage Examples

### Check project-specific command history
```bash
cd /path/to/project
histhere
```

### Find where specific commands were executed
```bash
hist "npm install"
```

### Prevent sensitive information from being recorded
```bash
# Commands starting with space are not recorded in either history file
$  mysql -u root -p'secret_password'
```

## Troubleshooting

### History not being shared
```bash
# Reload .bashrc
source ~/.bashrc
```

### Custom history file becoming too large
```bash
# Remove old entries (e.g., older than 6 months)
cp ~/.bash_history_full ~/.bash_history_full.bak
awk -v date="$(date -d '6 months ago' '+%Y-%m-%d')" '$1 >= date' ~/.bash_history_full.bak > ~/.bash_history_full
```

## Important Notes

- Avoid entering passwords or API keys directly on the command line
  - If necessary, prefix the command with a space to prevent history recording
  - Better alternatives: use environment variables, config files, or password prompts
- Space-prefixed commands are not recorded in any history file (both standard and custom)
- Regular backups of history files are recommended