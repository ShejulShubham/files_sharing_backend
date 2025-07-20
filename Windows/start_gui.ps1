
#Requires -Version 5.1
<#
.SYNOPSIS
  Starts the file sharing server and GUI.
.DESCRIPTION
  This script checks for dependencies, manages port allocation,
  starts the Node.js server, and launches the Python GUI.
  It provides an interactive menu for managing the server.
#>

# --- Configuration ---
$DEFAULT_PORT = 5000
$SERVER_FILE = "server.js"
$GUI_FILE = "gui.py"
$PROJECT_DIR = $PSScriptRoot
$LOGFILE = Join-Path $PROJECT_DIR "debug_log.txt"

# --- Function to check port and get process ---
function Get-ProcessOnPort {
    param (
        [int]$Port
    )
    try {
        $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop
        if ($connection) {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction Stop
            return $process
        }
    }
    catch {
        # No process found, return null
    }
    return $null
}

# --- Main Script ---

# 1. Port Selection
$port = $DEFAULT_PORT
while ($true) {
    $processOnPort = Get-ProcessOnPort -Port $port
    if (-not $processOnPort) {
        break # Port is free
    }

    Write-Host "⚠️ Port $port is in use by PID $($processOnPort.Id) ($($processOnPort.ProcessName))."
    $choice = Read-Host "Kill it (K), Choose another port (C), or Exit (E)? [K/C/E]"

    switch ($choice.ToUpper()) {
        "K" {
            Write-Host "Killing PID $($processOnPort.Id)..."
            Stop-Process -Id $processOnPort.Id -Force
            Start-Sleep -Seconds 1
            # Loop will re-check the port
        }
        "C" {
            $portChoice = Read-Host "1. Automatic port selection`n2. Manually enter port`nChoose (1/2): "
            if ($portChoice -eq "1") {
                Write-Host "Finding next available port starting from $($port + 1)..."
                $port++
                while (Get-ProcessOnPort -Port $port) {
                    $port++
                }
                Write-Host "Found available port: $port"
            }
            elseif ($portChoice -eq "2") {
                $manualPort = Read-Host "Enter custom port (leave blank for automatic)"
                if ([string]::IsNullOrWhiteSpace($manualPort)) {
                     $port++
                    while (Get-ProcessOnPort -Port $port) {
                        $port++
                    }
                    Write-Host "Found available port: $port"
                }
                else {
                    $port = [int]$manualPort
                }
            }
        }
        "E" {
            Write-Host "Exiting script."
            exit
        }
        default {
            Write-Host "Invalid choice."
        }
    }
}


# 2. Dependency Check
Set-Location $PROJECT_DIR
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing Node.js dependencies..."
    npm install
}

# Check if Python 'requests' is installed
$pythonCheck = python -c "import requests" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing Python 'requests'..."
    python -m pip install --user requests
}

# 3. Start Server
Write-Host "Starting server on port $port..."
$env:PORT = $port
$serverProcess = Start-Process node -ArgumentList $SERVER_FILE -PassThru -WindowStyle Minimized

# Give server a moment to start
Start-Sleep -Seconds 2

$serverCheckProcess = Get-ProcessOnPort -Port $port
if (-not $serverCheckProcess -or $serverCheckProcess.Id -ne $serverProcess.Id) {
    Write-Host "❌ ERROR: Server failed to start on port $port."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Server started on port $port with PID $($serverProcess.Id)."

# 4. Launch GUI
Write-Host "Launching GUI..."
Start-Process python -ArgumentList "$GUI_FILE", "$port"

# 5. Post-GUI Menu
while ($true) {
    $serverIsRunning = Get-Process -Id $serverProcess.Id -ErrorAction SilentlyContinue
    if (-not $serverIsRunning) {
        Write-Host "⚠️ Server has stopped."
        break
    }

    Write-Host "`n--- File Sharing Server (PORT: $port, PID: $($serverProcess.Id)) ---`n"
    Write-Host "1. Open shared files in browser"
    Write-host "2. Stop server and exit"
    Write-Host "3. Exit (keep server running)"
    $menuChoice = Read-Host "Enter your choice (1/2/3): "

    switch ($menuChoice) {
        "1" {
            Start-Process "http://localhost:$port/files"
        }
        "2" {
            Write-Host "Stopping server..."
            Stop-Process -Id $serverProcess.Id -Force
            break
        }
        "3" {
            Write-Host "Leaving server running in the background..."
            break
        }
        default {
            Write-Host "Invalid choice."
        }
    }
}

Write-Host "Exiting script."
