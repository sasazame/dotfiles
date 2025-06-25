#!/bin/bash

# Usage: ./kill-port.sh <port>
# Example: ./kill-port.sh 3000

if [ $# -eq 0 ]; then
    echo "Usage: $0 <port>"
    echo "Example: $0 3000"
    exit 1
fi

PORT=$1

# Find process using the port
PID=$(ss -tlnp 2>/dev/null | grep ":$PORT" | grep -oP 'pid=\K[0-9]+' | head -1)

if [ -z "$PID" ]; then
    echo "No process found on port $PORT"
    exit 0
fi

# Get process name
PROCESS_NAME=$(ps -p $PID -o comm= 2>/dev/null)

echo "Found process: $PROCESS_NAME (PID: $PID) on port $PORT"
echo -n "Kill this process? [y/N] "
read CONFIRM

if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    kill $PID
    if [ $? -eq 0 ]; then
        echo "Process killed successfully"
    else
        echo "Failed to kill process"
        exit 1
    fi
else
    echo "Cancelled"
fi