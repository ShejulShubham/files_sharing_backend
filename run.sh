#!/bin/bash

# ====== Script Config ======
LOG_DIR="./log/run_file"
LOG_FILE_NAME="run_sh.log"
LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"
SETUP_SCRIPT="./scripts/linux/setup.sh"
START_CLI="./scripts/linux/start_cli.sh"
START_GUI="./scripts/linux/start_gui.sh"
SERVER_SCRIPT="./src/server.js"
DEFAULT_PORT=5000

mkdir -p "$LOG_DIR"

# ====== Logging Function ======
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ====== Run Setup Script ======
log "🔧 Running setup script..."
if [[ -f "$SETUP_SCRIPT" ]]; then
  bash "$SETUP_SCRIPT"
else
  log "❌ Setup script not found at $SETUP_SCRIPT"
  exit 1
fi

# ====== Find Available Port ======
PORT=$DEFAULT_PORT
while lsof -i :"$PORT" &>/dev/null; do
  log "⚠️ Port $PORT is in use. Trying next..."
  PORT=$((PORT + 1))
done

log "✅ Selected available port: $PORT"

# ====== Start the Server ======
log "🚀 Starting server on port $PORT..."
node "$SERVER_SCRIPT" "$PORT" &
SERVER_PID=$!
log "🔁 Server started with PID: $SERVER_PID"
sleep 2

# ====== Interface Selection ======

echo ""
echo -e "\e[1;34m📦 Interface Mode Selection\e[0m"
echo "----------------------------------"
echo "Please choose how you'd like to select the folder:"
echo "  1) CLI  - Use terminal input"
echo "  2) GUI  - Use graphical window (recommended for ease)"
echo ""

while true; do
  read -rp "Enter your choice [1 or 2]: " USER_CHOICE
  case "$USER_CHOICE" in
    1)
      log "🖥️  CLI mode selected"
      bash "$START_CLI" "$PORT"
      break
      ;;
    2)
      log "🖼️  GUI mode selected"
      python3 ./gui/gui.py "$PORT" &
      break
      ;;
    *)
      echo -e "\e[1;31m❌ Invalid choice. Please enter 1 or 2.\e[0m"
      ;;
  esac
done


# ====== Get Local Network IP ======
DEVICE_IP=$(hostname -I | awk '{print $1}')
URL="http://$DEVICE_IP:$PORT"
log "🌍 App running at: $URL"

# ====== Post-launch Menu ======
while true; do
  echo ""
  echo "What would you like to do?"
  echo "1) Open in browser"
  echo "2) Exit (leave server running)"
  echo "3) Stop this server and exit"
  echo "4) Stop all servers on port 5000+"
  read -rp "Enter your choice: " CHOICE

  case $CHOICE in
    1)
      log "🌐 Opening browser at $URL"
      xdg-open "$URL" >/dev/null 2>&1 &
      ;;
    2)
      log "👋 Exiting script. Server still running (PID: $SERVER_PID)."
      exit 0
      ;;
    3)
      log "🛑 Stopping current server (PID: $SERVER_PID)..."
      kill "$SERVER_PID"
      exit 0
      ;;
    4)
      log "🧹 Stopping all Node.js servers on port >= 5000..."
      for port in $(seq 5000 5999); do
        for pid in $(lsof -ti tcp:$port); do
          if ps -p "$pid" -o comm= | grep -qi node; then
            kill "$pid"
            log "  ✖️ Killed Node.js PID $pid on port $port"
          fi
        done
      done
      exit 0
      ;;
    *)
      echo "❌ Invalid option. Please try again."
      ;;
  esac
done
