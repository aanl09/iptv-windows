@echo off
title IPTV Player Server
cd /d "%~dp0"

:: Auto-elevate to admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting admin access...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================
echo    IPTV Player - Setup & Launch
echo ========================================
echo.

:: Check Python
echo [1/3] Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python found!
    set PYTHON=python
    goto :run_server
)

python3 --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python3 found!
    set PYTHON=python3
    goto :run_server
)

:: Python not found - install
echo [!] Python not found. Installing...
echo.

:: Try winget first
echo [2/3] Trying winget...
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Installing Python via winget...
    winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    if %errorlevel% equ 0 (
        echo [OK] Python installed via winget!
        goto :refresh_path
    )
    echo [!] Winget failed, trying direct download...
)

:: Fallback: download installer
echo [2/3] Downloading Python 3.12...
set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "PY_EXE=%TEMP%\python_installer.exe"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_EXE%'" 2>nul

if not exist "%PY_EXE%" (
    echo [X] Download failed!
    echo.
    echo Please install Python manually:
    echo https://www.python.org/downloads/
    echo Check "Add to PATH" during install.
    echo.
    pause
    exit /b 1
)

echo [3/3] Installing Python...
"%PY_EXE%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
echo [*] Waiting for install to complete...
timeout /t 30 >nul
del "%PY_EXE%" >nul 2>&1

:refresh_path
:: Refresh PATH from registry
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%B"
set "PATH=%USER_PATH%;%PATH%"

:: Also check common install locations
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto :run_server
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :run_server
)

:: Final check
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON=python
    goto :run_server
)

echo.
echo [X] Python install may have failed.
echo Please restart this script, or install Python manually:
echo https://www.python.org/downloads/
echo.
pause
exit /b 1

:run_server
echo.
echo ========================================
echo    Starting IPTV Server...
echo    http://localhost:8099
echo ========================================
echo.
echo [OK] Server running! Browser will open automatically.
echo [!] Close this window to stop the server.
echo.

:: Wait a moment then open browser
timeout /t 3 >nul
start "" http://localhost:8099

:: Run server (keeps window open)
%PYTHON% server.py

echo.
echo [!] Server stopped.
pause
