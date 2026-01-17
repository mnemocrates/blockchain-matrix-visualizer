#!/bin/bash
# Start Bitcoin Fetcher Service

echo "Starting Bitcoin Block Fetcher..."
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Determine Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

# Run the fetcher
$PYTHON_CMD bitcoin_fetcher.py
