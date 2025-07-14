@echo off
setlocal EnableDelayedExpansion

set "DEFAULT_PORT=5000"
set "PORT=%DEFAULT_PORT%"

:checkPort
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%PORT% ^| findstr LISTENING') do (
    set "PID=%%a"
)

if defined PID (
    echo [⚠] Port %PORT% is already in use by PID %PID%
    echo.
    echo [1] Use another port
    echo [2] Kill the process on this port
    echo [3] Exit
    set /p CHOICE="Choose an option (1/2/3): "

    if "%CHOICE%"=="1" (
        echo [a] Auto select port
        echo [b] Enter manually
        set /p SUB="Choose (a/b): "
        if /i "!SUB!"=="a" (
            for /L %%i in (10000,1,20000) do (
                netstat -aon | findstr :%%i | findstr LISTENING >nul || (
                    set "PORT=%%i"
                    goto portFree
                )
            )
        ) else (
            set /p "PORT=Enter new port: "
        )
        goto checkPort
    )

    if "%CHOICE%"=="2" (
        echo Killing PID %PID%...
        taskkill /PID %PID% /F
        timeout /t 1 >nul
        goto checkPort
    )

    if "%CHOICE%"=="3" (
        echo Exiting...
        exit /b
    )
    goto checkPort
)

:portFree
set "URL=http://localhost:%PORT%/home"
echo ✅ Using port: %PORT%
echo.

REM Start browser
start "" "%URL%"

REM Start server
set PORT=%PORT%
node server.js
