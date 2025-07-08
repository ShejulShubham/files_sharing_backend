#!/bin/bash

# ----------------- CONFIG -----------------
PORT=5000
URL="http://localhost"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server.js"

# HARDCODE YOUR USER'S NVM PATH
REAL_USER_HOME="/home/shubham-shejul"
NVM_DIR="$REAL_USER_HOME/.nvm"
# ------------------------------------------

# Ensure we're in project directory
cd "$PROJECT_DIR" || exit 1

# ✅ Load NVM (even under sudo)
if [ -s "$NVM_DIR/nvm.sh" ]; then
  export NVM_DIR="$NVM_DIR"
  . "$NVM_DIR/nvm.sh"
fi

# Optional: use a specific Node version
# nvm use 18

# Check if node is available
NODE_PATH=$(command -v node)
if [ -z "$NODE_PATH" ]; then
  echo "❌ Error: Node.js is not installed or not found in PATH."
  exit 1
fi

echo "🚧 Checking dependencies..."
if [ ! -d node_modules ]; then
  echo "📦 Installing dependencies..."
  npm install
else
  echo "✅ Dependencies already installed."
fi

# Get local IP for external access
LOCAL_IP=$(hostname -I | awk '{print $1}')
EXTERNAL_URL="http://$LOCAL_IP/"

echo ""
echo "🚀 Starting File Sharing Server..."
echo "📂 Project directory: $PROJECT_DIR"

# Start the server (run in background)
PORT=$PORT node "$SERVER_FILE" &

# Wait briefly
sleep 1

# Show URLs
echo ""
echo "🌐 Access from this device: $URL"
echo "📡 Access from other devices: $EXTERNAL_URL"
echo ""

# Try to open in browser only if not running as root
if [ "$(id -u)" -ne 0 ]; then
  if command -v xdg-open >/dev/null; then
    xdg-open "$URL"
  elif command -v open >/dev/null; then
    open "$URL"
  elif command -v start >/dev/null; then
    start "$URL"
  else
    echo "❗ Unable to auto-open browser. Please open manually: $URL"
  fi
else
  echo "⚠️  Running as root, skipping browser launch due to sandbox restrictions."
fi
