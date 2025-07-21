#!/bin/bash

# ====== Script Variables ======
LOG_FILE_NAME="setup_sh.log"
LOG_DIR="./log/setup_file"
LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"
SRC_DIR="./src"
GUI_REQUIREMENTS=("tkinter" "requests")

# ====== Ensure log directory exists ======
mkdir -p "$LOG_DIR"

# ====== Logging Function ======
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ====== Detect Package Manager ======
detect_package_manager() {
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo ""
  fi
}

PKG_MANAGER=$(detect_package_manager)

if [[ -z "$PKG_MANAGER" ]]; then
  log "❌ No supported package manager found (dnf, apt, pacman)."
  exit 1
fi

log "📦 Using package manager: $PKG_MANAGER"

# ====== Dependency Installer ======
install_if_missing() {
  local cmd="$1"
  local pkg="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "🔍 $cmd not found. Installing $pkg..."
    case $PKG_MANAGER in
      apt)
        sudo apt update && sudo apt install -y "$pkg"
        ;;
      dnf)
        sudo dnf install -y "$pkg"
        ;;
      pacman)
        sudo pacman -Sy --noconfirm "$pkg"
        ;;
    esac
    log "✅ $pkg installed."
  else
    log "✔️ $cmd is already installed."
  fi
}

# ====== Install System Dependencies ======
install_if_missing "node" "nodejs"
install_if_missing "npm" "npm"
install_if_missing "python3" "python3"
install_if_missing "pip3" "python3-pip"

# ----- Python package: tkinter -----
log "📦 Checking for tkinter..."
if python3 -c "import tkinter" &>/dev/null; then
  log "✔ tkinter is already available."
else
  log "📥 Installing system package for tkinter..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt install -y python3-tk
  elif [[ "$PKG_MANAGER" == "dnf" ]]; then
    sudo dnf install -y python3-tkinter
  elif [[ "$PKG_MANAGER" == "pacman" ]]; then
    sudo pacman -S --noconfirm tk
  else
    log "❌ Could not determine how to install tkinter on this system."
    exit 1
  fi
fi


# ====== Check & Install Python GUI Dependencies ======
log "📦 Checking Python packages..."
for pkg in "${GUI_REQUIREMENTS[@]}"; do
  if ! python3 -c "import $pkg" &>/dev/null; then
    log "📥 Installing Python package: $pkg"
    pip3 install "$pkg" | tee -a "$LOG_FILE"
  else
    log "✔️ Python package '$pkg' is already installed."
  fi
done

# ====== Check Node.js Dependencies ======
if [ -d "$SRC_DIR" ]; then
  if [ ! -d "$SRC_DIR/node_modules" ]; then
    log "📦 Installing Node.js dependencies in $SRC_DIR..."
    (cd "$SRC_DIR" && npm install) | tee -a "$LOG_FILE"
    log "✅ Node.js packages installed."
  else
    log "✔️ Node.js packages already installed."
  fi
else
  log "⚠️ Warning: '$SRC_DIR' folder not found. Skipping npm install."
fi

# ====== Complete ======
log "✅ All dependencies verified and installed."
echo ""
