@echo off
title IPTV Player Server
cd /d "%~dp0"

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    python3 --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Python not found! Install from python.org
        echo Make sure to check "Add to PATH" during install.
        pause
        exit /b 1
    )
    set PYTHON=python3
) else (
    set PYTHON=python
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
