#!/bin/bash

# -------------------- COLOR CODES ---------------------
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
RESET='\e[0m'

# -------------------- CONFIG ---------------------
PORT=5000
URL="http://localhost:$PORT"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server.js"
PARENT_PATH=$(dirname "$PROJECT_DIR")
REAL_USER_HOME="$HOME"
NVM_DIR="$REAL_USER_HOME/.nvm"

# -------------------------------------------------
echo -e "\n\033[1;36m🔧 File Sharing App Setup\033[0m"

# Custom path for sharing
read -e -p $'\e[1;35mWould you like to share custom folder? (y/n):\e[0m ' CHOICE

if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    while true; do
        echo -e "${GREEN}1.${RESET} ${CYAN}Enter the file path that you want to share${RESET} OR ${YELLOW}simply leave it blank to exit${RESET}"
        echo -e "${YELLOW}Note:${RESET} You can use ${BLUE}TAB${RESET} to auto-complete folders."

        read -e -p $'\e[1;35mEnter file path:\e[0m ' DIRECTORY_PATH

    if [[ -z "$DIRECTORY_PATH" ]]; then
        echo -e "${YELLOW}Exiting: No directory path provided.${RESET}"
        exit 1
    elif [[ -d "$DIRECTORY_PATH" ]]; then
        break
    else
        echo "❌ Invalid directory. Please try again."
    fi
    done
else
    DIRECTORY_PATH=$PARENT_PATH
    echo -e "${YELLOW}No directory provided. Will share the parent folder${RESET}"
fi

echo -e "✅ Sharing: $DIRECTORY_PATH"

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

# Open default browser (only if xdg-open exists)
if command -v xdg-open >/dev/null 2>&1; then
  sleep 2
  xdg-open "$URL" &
  echo "🖥️  Opening browser to $URL..."
else
  echo "⚠️  'xdg-open' not found. Please open $URL manually."
fi

# Handle Ctrl+C and terminal close to stop server
cleanup() {
  echo -e "\n🛑 Server stopped."
  exit 0
}
trap cleanup SIGINT SIGTERM

# Start the server in foreground
PORT=$PORT node "$SERVER_FILE" "$DIRECTORY_PATH"
