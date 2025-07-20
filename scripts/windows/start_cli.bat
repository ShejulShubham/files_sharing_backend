@echo off
setlocal enabledelayedexpansion

:: ---------------- SETTINGS ----------------
set "DEBUG_CONSOLE=true"  :: Set to false to suppress console output

:: --------- Accept .env File Path Argument ----------
if "%~1"=="" (
    set "ENV_FILE=%~dp0\..\..\..\.env"
) else (
    set "ENV_FILE=%~1"
)

:: --------- Load .env Variables ----------
for /f "usebackq delims=" %%A in ("%ENV_FILE%") do (
    set "line=%%A"
    if "!line!:~0,2!"=="::" (
        rem This is a comment line, skip it
    ) else (
        for /f "tokens=1,* delims==" %%B in ("!line!") do set "%%B=%%C"
    )
)

:: --------- Setup Logging Paths ----------
set "BASE_LOG_DIR=%PROJECT_DIR%\log"
set "LOG_DIR=%BASE_LOG_DIR%\start_cli"
set "LOG_FILE=%LOG_DIR%\start_cli_bat.log"
set "BACKEND_URL=http://localhost:%PORT%"

:: Create log folders if missing
if not exist "%BASE_LOG_DIR%" (
    mkdir "%BASE_LOG_DIR%"
)
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

echo [%DATE% %TIME%] start_cli.bat started. >> "%LOG_FILE%"

if not defined PORT (
    set "PORT=5000"
)

:MENU_LOOP
cls
echo =============================
echo Select an option:
echo   1. Enter folder path manually
echo   2. Exit application
echo =============================
set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="1" (
    goto ENTER_PATH
) else if "%choice%"=="2" (
    call :log "❌ User chose to exit."
    exit /b
) else (
    echo ❌ Invalid input. Please try again.
    timeout /t 1 >nul
    goto MENU_LOOP
)

:ENTER_PATH
set /p folder="Enter full path to the folder: "
if "%folder%"=="" (
    echo ❌ No path entered. Try again.
    call :log "❌ No path entered. Try again."
    timeout /t 1 >nul
    goto MENU_LOOP
)

if not exist "%folder%" (
    echo ❌ The folder "%folder%" does not exist. Try again.
    call :log "❌ The folder \"%folder%\" does not exist."
    timeout /t 1 >nul
    goto MENU_LOOP
)

call :log "✅ Valid path selected: %folder%"

:: ---------- Share folder with backend ----------
call :log "📤 Sending folder to backend..."

powershell -NoProfile -Command ^
    "$headers = @{ 'Accept' = 'application/json' }; " ^
    "$body = @{ path = '%folder%' } | ConvertTo-Json -Compress; " ^
    "$response = Invoke-WebRequest -Uri '%BACKEND_URL%/pick-folder' -Method POST -Body $body -Headers $headers -ContentType 'application/json' -UseBasicParsing; " ^
    "$json = $response.Content | ConvertFrom-Json; " ^
    "if ($response.StatusCode -eq 200 -and $json.success) { " ^
        "Write-Host '✅ Folder successfully shared with backend.'; exit 0 } else { " ^
        "Write-Host '❌ Server rejected the folder. Try again.'; exit 1 }"


if errorlevel 1 (
    call :log "❌ Failed to share folder with backend."
    timeout /t 1 >nul
    goto MENU_LOOP
)

:: ---------- Open browser and exit ----------
call :log "🌐 Opening browser at %SHARE_HOST%:%PORT%"
start "" "%SHARE_HOST%:%PORT%"
exit /b


:: ---------- Logging function ----------
:log
echo [%DATE% %TIME%] %~1 >> "%LOG_FILE%"
exit /b

:MENU_LOOP



