#!/bin/bash

# ====== Script Variables ======
LOG_DIR="./log/start_cli"
LOG_FILE_NAME="start_cli.log"
LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"

# ====== Read Port from Argument ======
PORT=${1:-5000}
API_URL="http://localhost:$PORT"

# ====== Get Local Network IP ======
DEVICE_IP=$(hostname -I | awk '{print $1}')
URL="http://$DEVICE_IP:$PORT"


mkdir -p "$LOG_DIR"

# ====== Logging Function ======
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}


# ====== Check if Server is Running ======
log "🔍 Checking if server is running at $API_URL/ping ..."
PING_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/ping")

if [[ "$PING_RESPONSE" != "200" ]]; then
  log "❌ Server not running or unreachable at $API_URL"
  echo "❌ Server is not running on port $PORT. Exiting."
  exit 1
fi

log "✅ Server is up."

# ====== User Menu Loop ======
while true; do
  echo ""
  echo "📂 Select an option:"
  echo "  1) Enter folder path to share"
  echo "  2) Exit CLI mode"

  # Read input
  read -rp "Your choice [1-2]: " 
  USER_CHOICE=1

  sleep 1

  # Exit if input is empty (EOF or broken stream)
  if [[ -z "$USER_CHOICE" ]]; then
    echo "❌ No input detected. Exiting."
    log "No input detected. Exiting loop."
    exit 1
  fi

  case "$USER_CHOICE" in
    1)
      read -rp "Enter absolute folder path: " FOLDER_PATH
      if [[ ! -d "$FOLDER_PATH" ]]; then
        echo "❌ Invalid directory. Please try again."
        log "User entered invalid path: $FOLDER_PATH"
        continue
      fi

      RESPONSE=$(curl -s -X POST "$API_URL/pick-folder" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "{\"path\": \"$FOLDER_PATH\"}")

      if echo "$RESPONSE" | grep -q "\"success\":true"; then
        log "✅ Folder shared successfully: $FOLDER_PATH"
        echo "✅ Folder shared successfully!"
        break
      else
        log "❌ Server rejected the folder path: $FOLDER_PATH"
        echo "❌ Server rejected the folder. Try again."
      fi
      ;;
    2)
      log "👋 User exited CLI folder selection."
      echo "Exiting CLI mode."
      exit 0
      ;;
    *)
      echo "❌ Invalid selection. Enter 1 or 2."
      ;;
  esac
done


log "🌐 Opening browser at $URL"
xdg-open "$URL" >/dev/null 2>&1 &

exit 0
