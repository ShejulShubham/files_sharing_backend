#!/bin/bash

# ====== Script Variables ======
CLI_SCRIPT="./scripts/start_cli.sh"
GUI_SCRIPT="./scripts/start_gui.sh"
LOG_DIR="./log/run_file"
LOG_FILE="$LOG_DIR/run_sh.log"

# ====== Ensure log directory exists ======
mkdir -p "$LOG_DIR"

# ====== Logging Function ======
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ====== Welcome Message ======
log "======== File Sharing App Started (Linux) ========"
echo "   🌐 File Sharing App - Linux Mode"

# ====== Interface Selection ======
echo "Choose interface:"
echo "1) CLI"
echo "2) GUI"
read -p "Enter your choice [1/2]: " choice
log "User selected option: $choice"

# ====== Launch Based on Input ======
if [ "$choice" == "1" ]; then
  log "Launching CLI script: $CLI_SCRIPT"
  bash "$CLI_SCRIPT"
elif [ "$choice" == "2" ]; then
  log "Launching GUI script: $GUI_SCRIPT"
  bash "$GUI_SCRIPT"
else
  log "Invalid choice. Exiting script."
  echo "❌ Invalid choice. Exiting."
  exit 1
fi
