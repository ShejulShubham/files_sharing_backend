#!/bin/bash

# -------------------- CONFIG ---------------------
PORT=5000
URL="http://localhost:$PORT"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server.js"
REAL_USER_HOME="/home/shubham-shejul"
NVM_DIR="$REAL_USER_HOME/.nvm"
# -------------------------------------------------

echo -e "\n\033[1;36m🔧 File Sharing App Setup\033[0m"

# Move to project directory
cd "$PROJECT_DIR" || { echo "❌ Failed to enter project directory."; exit 1; }

# Load NVM
if [ -s "$NVM_DIR/nvm.sh" ]; then
  export NVM_DIR="$NVM_DIR"
  . "$NVM_DIR/nvm.sh"
  echo "📦 NVM loaded from $NVM_DIR"
else
  echo "⚠️  NVM not found. Make sure it's installed at $NVM_DIR"
fi

# Ensure Node is available
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js not found. Please install it and try again."
  exit 1
fi

echo "✅ Node version: $(node -v)"

# Install dependencies if needed
if [ ! -d node_modules ]; then
  echo -e "\n📦 Installing dependencies..."
  npm install || { echo "❌ npm install failed."; exit 1; }
else
  echo -e "\n✅ Dependencies are already installed."
fi

# Show network info
LOCAL_IP=$(hostname -I | awk '{print $1}')
EXTERNAL_URL="http://$LOCAL_IP:$PORT"

echo -e "\n🚀 \033[1;32mStarting the server on port $PORT...\033[0m"
echo "📂 Project Directory: $PROJECT_DIR"
echo "🌐 Access URL (local):    $URL"
echo "🌐 Access URL (external): $EXTERNAL_URL"

# Handle Ctrl+C and terminal close to stop server
cleanup() {
  echo -e "\n🛑 Server stopped."
  exit 0
}
trap cleanup SIGINT SIGTERM

# Start the server in foreground
PORT=$PORT node "$SERVER_FILE"
