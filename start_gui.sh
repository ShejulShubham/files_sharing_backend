#!/bin/bash

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RESET='\e[0m'

DEFAULT_PORT=5000
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server.js"
NVM_DIR="$HOME/.nvm"
PORT_HISTORY_FILE="$PROJECT_DIR/.port_history"
PORT=$DEFAULT_PORT
URL="http://localhost:$PORT/home"

check_port() {
    lsof -i :$1 -sTCP:LISTEN -t 2>/dev/null
}

pick_port() {
    while true; do
        PID=$(check_port $PORT)
        if [[ -z "$PID" ]]; then return; fi

        echo -e "${YELLOW}⚠ Port $PORT is in use (PID: $PID)${RESET}"
        echo -e "${GREEN}1.${RESET} Use another port"
        echo -e "${GREEN}2.${RESET} Kill the process"
        echo -e "${GREEN}3.${RESET} Exit"

        read -p "Choose (1/2/3): " OPTION
        case $OPTION in
            1)
                read -p "Enter custom port: " PORT
                ;;
            2)
                kill -9 $PID
                echo "${RED} server killed at PORT:$PORT${RESET}"
                sleep 1
                ;;
            3)
                exit 1
                ;;
            *)
                echo "❌ Invalid option."
                ;;
        esac
    done
}

pick_port
cd "$PROJECT_DIR" || exit 1

if [ -s "$NVM_DIR/nvm.sh" ]; then
  export NVM_DIR
  . "$NVM_DIR/nvm.sh"
fi

if [ ! -d node_modules ]; then
  echo "📦 Installing dependencies..."
  npm install
fi

PORT=$PORT node "$SERVER_FILE" &
SERVER_PID=$!
echo "$PORT:$SERVER_PID" >> "$PORT_HISTORY_FILE"
sleep 1
xdg-open "$URL" >/dev/null 2>&1

while true; do
    echo -e "\n🟢 Server running on $URL (PID: $SERVER_PID)"
    echo -e "${GREEN}1.${RESET} Stop server"
    echo -e "${GREEN}2.${RESET} Open browser"
    echo -e "${GREEN}3.${RESET} Exit (server in background)"
    read -p "Choose: " CHOICE
    case "$CHOICE" in
        1)
            kill $SERVER_PID
            echo "🛑 Server stopped."
            break
            ;;
        2)
            xdg-open "$URL" >/dev/null 2>&1
            ;;
        3)
            echo "🚀 Running in background. PID: $SERVER_PID"
            break
            ;;
        *)
            echo "❌ Invalid choice."
            ;;
    esac

done
