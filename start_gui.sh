#!/bin/bash

# --- Style Definitions ---
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RESET='\e[0m'

# --- Configuration ---
DEFAULT_PORT=5000
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_FILE="server.js"
GUI_FILE="gui.py"
PORT=$DEFAULT_PORT

# --- Utility Functions ---
check_port() {
    # Check for a process listening on the given port (cross-platform)
    if command -v lsof &> /dev/null; then
        lsof -i :$1 -sTCP:LISTEN -t 2>/dev/null
    elif command -v netstat &> /dev/null; then
        netstat -anp 2>/dev/null | grep 'LISTEN' | grep ":$1 " | awk '{print $NF}' | cut -d'/' -f1
    else
        echo "" # No suitable command found
    fi
}

find_available_port() {
    local current_port=$1
    echo -e "${CYAN}Searching for an available port automatically...${RESET}" >&2
    while true; do
        current_port=$((current_port + 1))
        local pid_on_port=$(check_port $current_port)
        if [[ -z "$pid_on_port" ]]; then
            echo -e "${GREEN}Found available port: $current_port${RESET}" >&2
            echo "$current_port" # This is the actual return value
            return
        fi
        echo -e "${YELLOW}Port $current_port is in use, trying next...${RESET}" >&2
        sleep 0.1 # Small delay to prevent busy-waiting
    done
}

cleanup() {
    echo -e "\n${CYAN}ℹ️ Script interrupted. Shutting down background server...${RESET}" >&2
    if [ ! -z "$SERVER_PID" ] && ps -p $SERVER_PID > /dev/null; then
        kill $SERVER_PID
        echo -e "${GREEN}✅ Server with PID $SERVER_PID stopped.${RESET}" >&2
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

# --- Main Logic ---

# 1. Port Selection
while true; do
    PID=$(check_port $PORT)
    if [[ -z "$PID" ]]; then break; fi

    echo -e "${YELLOW}⚠️ Port $PORT is in use by process $PID.${RESET}"
    read -p "Kill it, choose another port, or exit? (k/c/e): " choice
    case "$choice" in
        k|K) kill -9 $PID; echo -e "${RED}🔪 Process $PID killed.${RESET}"; sleep 1;;
        c|C)
            echo -e "${CYAN}1.${RESET} Automatic port selection (starts from $((PORT + 1)))"
            echo -e "${CYAN}2.${RESET} Manually enter port"
            read -p "Choose (1/2): " port_choice
            case "$port_choice" in
                1)
                    PORT=$(find_available_port $PORT)
                    ;;
                2)
                    read -p "Enter custom port (leave blank for automatic): " manual_port
                    if [[ -z "$manual_port" ]]; then
                        PORT=$(find_available_port $PORT)
                    else
                        PORT=$manual_port
                    fi
                    ;;
                *)
                    echo -e "${RED}❌ Invalid choice. Keeping current port for re-evaluation.${RESET}"
                    ;;
            esac
            ;;
        e|E) exit 1;;
        *) echo "❌ Invalid option.";;
    esac
done

# 2. Dependency Installation
cd "$PROJECT_DIR" || exit 1
if [ ! -d "node_modules" ]; then
  echo -e "${CYAN}ℹ️ Installing Node.js dependencies...${RESET}"
  npm install
fi
if ! python3 -c "import requests" &> /dev/null; then
    echo -e "${CYAN}ℹ️ Installing Python 'requests' library...${RESET}"
    python3 -m pip install --user requests
fi

# 3. Start Server
echo -e "${GREEN}🚀 Starting server on port $PORT...${RESET}"
PORT=$PORT node "$SERVER_FILE" & 
SERVER_PID=$!
sleep 1 # Give the server a moment to start

# 4. Run GUI
echo -e "${CYAN}🎨 Launching GUI...${RESET}"
python3 "$GUI_FILE" "$PORT"

# 5. Post-GUI Management Menu
while true; do
    if ! ps -p $SERVER_PID > /dev/null; then
        echo -e "\n${YELLOW}⚠️ Server has stopped unexpectedly.${RESET}"
        break
    fi
    echo -e "\n${CYAN}--- Server is Running (PID: $SERVER_PID) ---${RESET}"
    echo -e "${GREEN}1.${RESET} Stop Server and Exit"
    echo -e "${GREEN}2.${RESET} Open Shared Files in Browser"
    echo -e "${GREEN}3.${RESET} Exit (Keep Server Running)"
    read -p "Your choice: " CHOICE

    case $CHOICE in
        1)
            echo -e "${RED}🛑 Stopping server...${RESET}"
            kill $SERVER_PID
            echo -e "${GREEN}✅ Server stopped.${RESET}"
            break
            ;;
        2)
            echo -e "${CYAN}🌐 Opening browser...${RESET}"
            xdg-open "http://localhost:$PORT/files" >/dev/null 2>&1
            ;;
        3)
            echo -e "${YELLOW}👋 Exiting. Server is still running in the background (PID: $SERVER_PID).${RESET}"
            break
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please try again.${RESET}"
            ;;
    esac
done