@echo off
setlocal enabledelayedexpansion

:: ---------------- CONFIGURATION ----------------
set "DEFAULT_PORT=5000"
set "PORT=%DEFAULT_PORT%"
set "SERVER_FILE=server.js"
set "GUI_FILE=gui.py"
set "PROJECT_DIR=%~dp0"
:: ------------------------------------------------

:: Move to project directory
cd /d "%PROJECT_DIR%" || (
  echo ❌ Failed to switch to project directory.
  pause
  exit /b 1
)

:: ---------------- PORT CHECK ----------------

:check_port
set "PORT_PID="
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R /C:":%PORT%\>" ^| find "LISTENING"') do (
    set "PORT_PID=%%a"
)

if defined PORT_PID (
    echo ⚠️ Port %PORT% is in use by PID %PORT_PID%.
    echo.
    echo [K] Kill process
    echo [C] Choose another port
    echo [E] Exit
    set /p choice="Enter your choice (K/C/E): "

    if /i "%choice%"=="K" (
        echo Killing process %PORT_PID%...
        taskkill /PID %PORT_PID% /F
        timeout /t 1 >nul
        goto check_port
    ) else if /i "%choice%"=="C" (
        call :find_available_port
    ) else (
        echo Exiting...
        exit /b
    )
)

goto after_port_choice

:find_available_port
set /a PORT=PORT + 1
call :check_port
if defined PORT_PID goto find_available_port
exit /b

:after_port_choice

:: ---------------- DEPENDENCY CHECK ----------------

echo.
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH.
    pause
    exit /b 1
)

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Python is not installed or not in PATH.
    pause
    exit /b 1
)

:: Install Node.js dependencies if missing
if not exist node_modules (
    echo Installing Node.js dependencies...
    npm install || (
        echo ❌ npm install failed.
        pause
        exit /b 1
    )
)

:: Check if Python 'requests' module is installed
python -c "import requests" 2>nul
if errorlevel 1 (
    echo Installing Python 'requests' module...
    python -m pip install --user requests
)

:: ---------------- START SERVER ----------------

echo.
echo 🚀 Starting server on port %PORT%...
start "File Sharing Server" cmd /k "cd /d %PROJECT_DIR% && set PORT=%PORT% && node %SERVER_FILE%"

:: Wait a moment and get the PID
timeout /t 2 >nul
set "PORT_PID="
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R /C:":%PORT%\>" ^| find "LISTENING"') do (
    set "PORT_PID=%%a"
)

if not defined PORT_PID (
    echo ❌ ERROR: Server failed to start.
    pause
    exit /b 1
)

echo ✅ Server started with PID %PORT_PID%.
echo.

:: ---------------- LAUNCH GUI ----------------

if exist "%GUI_FILE%" (
    echo 🖥️ Launching GUI...
    start "File Sharing GUI" cmd /k "python %GUI_FILE% %PORT%"
) else (
    echo ⚠️ GUI file '%GUI_FILE%' not found.
    pause
)

:: ---------------- MENU ----------------

:menu_loop
echo.
echo --- File Sharing Server (PORT: %PORT%, PID: %PORT_PID%) ---
echo.
echo 1. Open in browser
echo 2. Stop server and exit
echo 3. Exit (leave server running)
set /p user_choice="Enter your choice (1/2/3): "

if "%user_choice%"=="1" (
    start "" "http://localhost:%PORT%/files"
    goto menu_loop
) else if "%user_choice%"=="2" (
    echo Stopping server...
    taskkill /PID %PORT_PID% /F
    goto end
) else if "%user_choice%"=="3" (
    echo Leaving server running in background...
    goto end
) else (
    echo ❌ Invalid choice.
    goto menu_loop
)

:end
echo Exiting script.
pause
exit /b
