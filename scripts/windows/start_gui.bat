@echo off
setlocal enabledelayedexpansion

:: --------- Accept .env File Path Argument ----------
if "%~1"=="" (
    set "ENV_FILE=%~dp0\..\..\..\.env"
) else (
    set "ENV_FILE=%~1"
)

:: --------- Load .env Variables ----------
for /f "usebackq delims=" %%A in ("%ENV_FILE%") do (
    set "line=%%A"
    if "!line!"=="" (
        rem Skip empty line
    ) else if "!line:~0,1!"=="#" (
        rem Skip comment line
    ) else (
        for /f "tokens=1,* delims==" %%B in ("!line!") do set "%%B=%%C"
    )
)

:: --------- Setup Logging ----------
set "SCRIPT_NAME=start_gui"
set "BASE_LOG_DIR=%PROJECT_DIR%\log"
set "LOG_DIR=%BASE_LOG_DIR%\%SCRIPT_NAME%"
set "LOG_FILE=%LOG_DIR%\%SCRIPT_NAME%.log"

if not exist "%BASE_LOG_DIR%" (
    mkdir "%BASE_LOG_DIR%"
)
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

echo [%DATE% %TIME%] Starting GUI mode >> "%LOG_FILE%"

:: --------- Check required variables ----------
if not defined PORT (
    echo [%DATE% %TIME%] ERROR: PORT not defined in .env >> "%LOG_FILE%"
    echo PORT not defined. Exiting.
    exit /b 1
)

if not defined PROJECT_DIR (
    set "PROJECT_DIR=%~dp0\..\..\.."
)

:: --------- Launch Python GUI ----------
echo [%DATE% %TIME%] Launching GUI with port %PORT% >> "%LOG_FILE%"

pushd "%PROJECT_DIR%\gui"
python gui.py %PORT%
popd

echo [%DATE% %TIME%] GUI closed or completed >> "%LOG_FILE%"
exit /b 0
