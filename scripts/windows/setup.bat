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

:: --------- Setup Directories ------------
set "BASE_LOG_DIR=%PROJECT_DIR%\log"
set "LOG_DIR=%BASE_LOG_DIR%\setup_file"
set "LOG_FILE=%LOG_DIR%\setup_bat.log"
set "START_GUI=%PROJECT_DIR%\scripts\windows\start_gui.bat"
set "START_CLI=%PROJECT_DIR%\scripts\windows\start_cli.bat"

:: Create log folders if missing
if not exist "%BASE_LOG_DIR%" (
    mkdir "%BASE_LOG_DIR%"
)
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

:: --------- Logging Path Debug Info --------
echo BASE_LOG_DIR = %BASE_LOG_DIR% >> "%LOG_FILE%"
echo LOG_DIR      = %LOG_DIR% >> "%LOG_FILE%"
echo LOG_FILE     = %LOG_FILE% >> "%LOG_FILE%"
echo ENV_FILE     = %ENV_FILE% >> "%LOG_FILE%"
echo [%DATE% %TIME%] Running setup.bat >> "%LOG_FILE%"

:: --------- Check Node.js ---------------
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js not found. >> "%LOG_FILE%"
    echo Node.js not found.
    exit /b 1
) else (
    echo ✅ Node.js found. >> "%LOG_FILE%"
)

:: --------- Check Python ----------------
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Python not found. >> "%LOG_FILE%"
    echo Python not found.
    exit /b 1
) else (
    echo ✅ Python found. >> "%LOG_FILE%"
)

:: --------- Install Node Modules --------
pushd "%PROJECT_DIR%\src"
if not exist node_modules (
    echo Installing Node modules... >> "%LOG_FILE%"
    npm install >> "%LOG_FILE%" 2>&1
)
popd

:: --------- Install Python Dependencies --
python -c "import requests" >nul 2>&1 || python -m pip install --user requests >> "%LOG_FILE%" 2>&1
python -c "import tkinter" >nul 2>&1 || (
    echo ❌ tkinter not available. Install a GUI-enabled Python.
    echo tkinter missing. >> "%LOG_FILE%"
    exit /b 1
)

:: --------- Check Port Availability -----
set "AVAILABLE_PORT=%PORT%"
:check_port
netstat -ano | findstr ":%AVAILABLE_PORT%" >nul
if %errorlevel% equ 0 (
    echo Port %AVAILABLE_PORT% in use. Trying next... >> "%LOG_FILE%"
    set /a AVAILABLE_PORT+=1
    goto check_port
)
echo ✅ Using port: %AVAILABLE_PORT% >> "%LOG_FILE%"

:: --------- Update PORT in .env file ---------
set "ENV_FILE=%PROJECT_DIR%\.env"
set "TEMP_ENV=%TEMP%\temp_env.txt"

if exist "%ENV_FILE%" (
    > "%TEMP_ENV%" (
        for /f "usebackq tokens=*" %%L in ("%ENV_FILE%") do (
            echo %%L | findstr /b /c:"PORT=" >nul
            if errorlevel 1 (
                echo %%L
            )
        )
        echo PORT=%AVAILABLE_PORT%
    )
    move /Y "%TEMP_ENV%" "%ENV_FILE%" >nul
) else (
    echo PORT=%AVAILABLE_PORT% > "%ENV_FILE%"
)


:: --------- Start Server -----------------
pushd "%PROJECT_DIR%"
start /min "" node "%SERVER_FILE%" %AVAILABLE_PORT% >nul 2>&1
popd

:: --------- Ask user to choose interface (GUI or CLI) ----------
echo.
echo ================================
echo     Choose Interface Mode:
echo ================================
echo 1. Graphical Interface (GUI)
echo 2. Command Line Interface (CLI)
choice /c 12 /n /m "Select interface: "

if errorlevel 2 (
    set "SELECTOR=cli"
    echo [%DATE% %TIME%] User selected CLI mode >> "%LOG_FILE%"
) else (
    set "SELECTOR=gui"
    echo [%DATE% %TIME%] User selected GUI mode >> "%LOG_FILE%"
)

:: --------- Launch the corresponding folder selector ----------
if "%SELECTOR%"=="cli" (
    call "%START_CLI%" "%ENV_FILE%"
) else (
    call "%START_GUI%" "%ENV_FILE%"
)

:: --------- Post-launch Menu ------------
:menu
echo.
echo ================================
echo    Server Running at:
echo    %SHARE_HOST%:%AVAILABLE_PORT%
echo ================================
echo 1. Open in Browser
echo 2. Stop the Server
echo 3. Exit without Stopping
echo.

choice /c 123 /n /m "Choose [1=Open, 2=Stop, 3=Exit]: "
set choice=%errorlevel%

if "%choice%"=="1" (
    start "" "%SHARE_HOST%:%AVAILABLE_PORT%"
    echo [%DATE% %TIME%] 🌐 Browser opened at %SHARE_HOST%:%AVAILABLE_PORT% >> "%LOG_FILE%"
    goto menu
) else if "%choice%"=="2" (
    echo [%DATE% %TIME%] 🛑 Stopping server... >> "%LOG_FILE%"
    curl -s -X POST "%SHARE_HOST%:%AVAILABLE_PORT%/shutdown" >nul 2>&1
    echo [%DATE% %TIME%] ✅ Server stopped. >> "%LOG_FILE%"
    goto end
) else if "%choice%"=="3" (
    echo [%DATE% %TIME%] ⚠️ Exiting without stopping the server. >> "%LOG_FILE%"
    goto end
)

:end
echo [%DATE% %TIME%] 🏁 Setup complete. >> "%LOG_FILE%"
exit /b 0
