#!/bin/bash
cd "$(dirname "$0")"

echo "========================================"
echo "    IPTV Player Server"
echo "    http://localhost:8099"
echo "========================================"
echo ""

# Check Python
if command -v python3 &>/dev/null; then
    PY=python3
elif command -v python &>/dev/null; then
    PY=python
else
    echo "[ERROR] Python not found!"
    echo "Install: brew install python (macOS) / apt install python3 (Linux)"
    exit 1
fi

# Open browser (macOS/Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://localhost:8099" 2>/dev/null &
elif [[ "$OSTYPE" == "linux"* ]]; then
    xdg-open "http://localhost:8099" 2>/dev/null &
fi

$PY server.py
