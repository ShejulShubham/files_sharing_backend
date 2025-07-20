@echo off
setlocal

:: --- Configuration ---
set "DEFAULT_PORT=5000"
set "PROJECT_DIR=%~dp0"
set "SERVER_FILE=server.js"
set "GUI_FILE=gui.py"
set "PORT=%DEFAULT_PORT%"

:: --- Port Selection ---
:checkPort
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%PORT%" ^| find "LISTENING"') do (
    set "PID=%%a"
)

if defined PID (
    echo WARNING: Port %PORT% is in use by process %PID%.
    choice /c kce /n /m "Kill it, choose another port, or exit? (k/c/e):"
    if errorlevel 3 (exit /b 1)
    if errorlevel 2 (set /p "PORT=Enter new port: ")
    if errorlevel 1 (taskkill /F /PID %PID% && echo Process %PID% killed.)
    set "PID="
    goto checkPort
)

:: --- Dependency Installation ---
cd /d "%PROJECT_DIR%"
if not exist "node_modules" (
    echo INFO: Installing Node.js dependencies...
    npm install
)
python -c "import requests" >nul 2>&1
if %errorlevel% neq 0 (
    echo INFO: Installing Python 'requests' library...
    python -m pip install --user requests
)

:: --- Start Server ---
echo INFO: Starting server on port %PORT%...
start "File Sharing Server" /b node "%SERVER_FILE%" --port=%PORT%

:: --- Run GUI ---
echo INFO: Launching GUI...
python "%GUI_FILE%" "%PORT%"

:: --- Post-GUI Management Menu ---
:managementMenu
cls
echo --- Server is Running on Port %PORT% ---
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq node.exe" /v ^| find "File Sharing Server"') do set SERVER_PID=%%a

if not defined SERVER_PID (
    echo.
    echo WARNING: Server has stopped unexpectedly.
    pause
    goto :eof
)

echo 1. Stop Server and Exit
echo 2. Open Shared Files in Browser
echo 3. Exit (Keep Server Running)

choice /c 123 /n /m "Your choice: "

if errorlevel 3 (goto :eof)
if errorlevel 2 (start http://localhost:%PORT%/files && goto managementMenu)
if errorlevel 1 (
    echo Stopping server...
    taskkill /F /PID %SERVER_PID% >nul
    echo Server stopped.
    pause
)

endlocal
