@echo off
setlocal enabledelayedexpansion

:: ---------------- CONFIG ----------------
set PORT=5000
set URL=http://localhost:%PORT%
set SERVER_FILE=server.js
set PROJECT_DIR=%~dp0
:: ----------------------------------------

echo.
echo 🔧 File Sharing App Setup

:: Move to project directory
cd /d "%PROJECT_DIR%" || (
  echo ❌ Failed to enter project directory.
  exit /b 1
)

:: Check if Node is available
where node >nul 2>nul
if %errorlevel% neq 0 (
  echo ❌ Node.js not found. Please install it and try again.
  exit /b 1
)

:: Show Node version
for /f %%i in ('node -v') do set NODE_VERSION=%%i
echo ✅ Node version: %NODE_VERSION%

:: Install dependencies if node_modules not present
if not exist node_modules (
  echo.
  echo 📦 Installing dependencies...
  call npm install || (
    echo ❌ npm install failed.
    exit /b 1
  )
) else (
  echo.
  echo ✅ Dependencies are already installed.
)

:: Get Local IP (basic method)
for /f "tokens=2 delims=:" %%f in ('ipconfig ^| findstr /i "IPv4"') do (
  for /f "delims=" %%a in ("%%f") do set LOCAL_IP=%%a
)
set LOCAL_IP=%LOCAL_IP: =%
set EXTERNAL_URL=http://%LOCAL_IP%:%PORT%

echo.
echo 🚀 Starting the server on port %PORT%...
echo 📂 Project Directory: %PROJECT_DIR%
echo 🌐 Access URL (local):    %URL%
echo 🌐 Access URL (external): %EXTERNAL_URL%
echo.

:: Start server in foreground
set PORT=%PORT%
call node "%SERVER_FILE%"

:: Optional: Pause before exit
echo.
echo 🛑 Server stopped.
pause
