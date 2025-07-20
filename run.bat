@echo off
setlocal enabledelayedexpansion

:: ---------------- SETTINGS ----------------
set "DEBUG_CONSOLE=true"  :: Set to false to suppress console output

:: ---------------- INITIAL CONFIG ----------------
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_DIR=%SCRIPT_DIR%"

set "LOG_DIR=%PROJECT_DIR%\log"
set "LOG_FOLDER=%LOG_DIR%\run_file"
set "LOG_FILE=%LOG_FOLDER%\run_bat.log"
set "ENV_FILE=%PROJECT_DIR%\.env"
set "SETUP_SCRIPT=%PROJECT_DIR%\scripts\windows\setup.bat"

set "DEFAULT_PORT=5000"
set "PORT=%DEFAULT_PORT%"
set "SERVER_FILE=%PROJECT_DIR%\src\server.js"
set "GUI_FILE=%PROJECT_DIR%\gui\gui.py"

:: ---------------- ENSURE LOG DIR ----------------
if not exist "%LOG_FOLDER%" mkdir "%LOG_FOLDER%"
echo [%DATE% %TIME%] Starting run.bat script >> "%LOG_FILE%"

:: ---------------- DETECT HOST IP ----------------
for /f "tokens=2 delims=:" %%f in ('ipconfig ^| findstr "IPv4"') do (
    set "HOST_IP=%%f"
    set "HOST_IP=!HOST_IP: =!"
)
if not defined HOST_IP (
    echo ❌ Unable to detect host IP >> "%LOG_FILE%"
    echo Unable to detect host IP.
    pause
    exit /b 1
)

echo [%DATE% %TIME%] Detected HOST_IP: !HOST_IP! >> "%LOG_FILE%"

:: ---------------- WRITE .ENV ----------------
(
    echo :: AUTO-GENERATED CONFIGURATION
    echo SCRIPT_DIR=%SCRIPT_DIR%
    echo SHARE_HOST=http://!HOST_IP!
    echo PROJECT_DIR=%PROJECT_DIR%
    echo LOG_DIR=%LOG_DIR%
    echo DEFAULT_PORT=%DEFAULT_PORT%
    echo PORT=%PORT%
    echo SERVER_FILE=%SERVER_FILE%
    echo GUI_FILE=%GUI_FILE%
    echo SETUP_SCRIPT=%SETUP_SCRIPT%
) > "%ENV_FILE%"

echo [%DATE% %TIME%] Wrote .env file at %ENV_FILE% >> "%LOG_FILE%"
echo .env created with all config values.

:: ---------------- CALL SETUP ----------------
echo [%DATE% %TIME%] Calling %SETUP_SCRIPT% with %ENV_FILE% >> "%LOG_FILE%"

if /i "%DEBUG_CONSOLE%"=="true" (
    call "%SETUP_SCRIPT%" "%ENV_FILE%"
) else (
    call "%SETUP_SCRIPT%" "%ENV_FILE%" >> "%LOG_FILE%" 2>&1
)

echo [%DATE% %TIME%] Finished run.bat >> "%LOG_FILE%"
exit /b
