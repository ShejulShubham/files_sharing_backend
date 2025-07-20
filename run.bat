@echo off
setlocal enabledelayedexpansion

:: ====== Script Variables ======
set "CLI_SCRIPT=scripts\start_cli.bat"
set "GUI_SCRIPT=scripts\start_gui.bat"
set "LOG_DIR=log\run_file"
set "LOG_FILE=%LOG_DIR%\run_bat.log"

:: ====== Ensure log directory exists ======
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

:: ====== Logging Function ======
echo %date% %time% - ======== File Sharing App Started (Windows) ======== >> "%LOG_FILE%"
echo =======================================
echo    🌐 File Sharing App - Windows Mode
echo =======================================

:: ====== Interface Selection ======
echo Choose interface:
echo 1) CLI
echo 2) GUI
set /p choice=Enter your choice [1/2]:
echo %date% %time% - User selected option: %choice% >> "%LOG_FILE%"

:: ====== Launch Based on Input ======
if "%choice%"=="1" (
  echo %date% %time% - Launching CLI script: %CLI_SCRIPT% >> "%LOG_FILE%"
  call "%CLI_SCRIPT%"
) else if "%choice%"=="2" (
  echo %date% %time% - Launching GUI script: %GUI_SCRIPT% >> "%LOG_FILE%"
  call "%GUI_SCRIPT%"
) else (
  echo %date% %time% - Invalid choice. Exiting. >> "%LOG_FILE%"
  echo ❌ Invalid choice. Exiting.
  exit /b 1
)
