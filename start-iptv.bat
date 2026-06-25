@echo off
title IPTV Player Server
cd /d "%~dp0"

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    python3 --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [!] Python not detected. Installing...
        echo.

        :: Try winget first (Windows 10/11)
        winget --version >nul 2>&1
        if %errorlevel% equ 0 (
            echo [*] Installing Python via winget...
            winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
            if %errorlevel% equ 0 (
                echo [OK] Python installed! Refreshing PATH...
                set "PATH=%LOCALAPPDATA%\Programs\Python\Python312\;%LOCALAPPDATA%\Programs\Python\Python312\Scripts\;%PATH%"
                goto :check_done
            )
        )

        :: Fallback: download installer
        echo [*] Downloading Python installer...
        set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
        set "PY_EXE=%TEMP%\python_installer.exe"
        powershell -Command "Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_EXE%'" >nul 2>&1

        if not exist "%PY_EXE%" (
            echo [ERROR] Download failed! Install manually from python.org
            pause
            exit /b 1
        )

        echo [*] Installing Python (silent)...
        "%PY_EXE%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
        timeout /t 10 >nul

        :: Refresh PATH
        set "PATH=%LOCALAPPDATA%\Programs\Python\Python312\;%LOCALAPPDATA%\Programs\Python\Python312\Scripts\;%PATH%"
        del "%PY_EXE%" >nul 2>&1

        :: Verify
        python --version >nul 2>&1
        if %errorlevel% neq 0 (
            echo [ERROR] Install failed. Download manually from python.org
            pause
            exit /b 1
        )
        echo [OK] Python installed successfully!
    ) else (
        set PYTHON=python3
    )
) else (
    set PYTHON=python
)

:check_done
:: Re-check after install
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON=python
) else (
    python3 --version >nul 2>&1
    if %errorlevel% equ 0 (
        set PYTHON=python3
    ) else (
        echo [ERROR] Python still not found after install.
        pause
        exit /b 1
    )
)

echo ========================================
echo    IPTV Player Server
echo    http://localhost:8099
echo ========================================
echo.
echo Starting server...
start "" http://localhost:8099
%PYTHON% server.py
pause
