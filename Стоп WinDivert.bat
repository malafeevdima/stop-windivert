@echo off
chcp 1251 >nul
title Discord WinDivert Manager
color 07

:: Check administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo   ERROR: ADMINISTRATOR RIGHTS REQUIRED
    echo ========================================
    echo.
    echo   This script requires administrator privileges.
    echo   It was started in normal user mode.
    echo.
    echo   How to fix:
    echo   1. Close this window
    echo   2. Right-click on the file
    echo   3. Select "Run as administrator"
    echo   4. Confirm in UAC window if prompted
    echo.
    echo ========================================
    echo   Press any key to exit...
    pause >nul
    exit /b
)

echo =========================================
echo   Discord and WinDivert Service Manager
echo =========================================
echo.
echo [STATUS] Starting operation...
echo.

:: ========== Discord ==========
echo [STEP 1] Processing Discord...
set "discord_status=not running"

tasklist | findstr /i "discord.exe" >nul
if %errorlevel% equ 0 (
    echo   Closing Discord...
    taskkill /f /im discord.exe >nul 2>&1
    timeout /t 2 >nul
    echo   Discord stopped.
    set "discord_status=closed"
) else (
    echo   Discord not running.
)

echo.

:: ========== DiscordFix ==========
echo [STEP 2] Force closing DiscordFix windows...

set "cmd_closed=0"
set "terminal_closed=0"

:: Close CMD windows with DiscordFix
echo   Closing DiscordFix CMD windows...
taskkill /fi "WindowTitle eq *service*" /fi "IMAGENAME eq cmd.exe" /f >nul 2>&1 && set /a cmd_closed+=1
taskkill /fi "WindowTitle eq *check_updates*" /fi "IMAGENAME eq cmd.exe" /f >nul 2>&1 && set /a cmd_closed+=1
taskkill /fi "WindowTitle eq *DiscordFix*" /fi "IMAGENAME eq cmd.exe" /f >nul 2>&1 && set /a cmd_closed+=1

:: Close Windows Terminal
echo   Closing Windows Terminal...
taskkill /f /im WindowsTerminal.exe >nul 2>&1 && set /a terminal_closed+=1
taskkill /f /im wt.exe >nul 2>&1 && set /a terminal_closed+=1

:: DiscordFix summary
set /a total_closed=cmd_closed + terminal_closed

if %total_closed% equ 0 (
    set "discordfix_status=not found"
    echo   No DiscordFix windows found.
) else if %total_closed% equ 1 (
    set "discordfix_status=closed (1 window)"
    echo   Closed 1 DiscordFix window.
) else (
    set "discordfix_status=closed (%total_closed% windows)"
    echo   Closed %total_closed% DiscordFix windows.
)

echo.

:: ========== zapret ==========
echo [STEP 3] Processing zapret (winws.exe)...
set "zapret_status=not running"

tasklist | findstr /i "winws.exe" >nul
if %errorlevel% equ 0 (
    echo   Closing zapret...
    taskkill /f /im winws.exe >nul 2>&1
    timeout /t 2 >nul
    echo   zapret stopped.
    set "zapret_status=closed"
) else (
    echo   zapret not running.
)

echo.

:: ========== WinDivert ==========
echo [STEP 4] Processing WinDivert service...
set "windivert_status="

sc query WinDivert >nul 2>&1
if %errorlevel% neq 0 (
    echo   Result: WinDivert service not found or already removed.
    set "windivert_status=not installed"
    goto :END
)

echo   Stopping WinDivert service...
sc stop WinDivert >nul
timeout /t 2 >nul

sc query WinDivert >nul 2>&1
if %errorlevel% neq 0 (
    echo   Result: WinDivert service successfully stopped and removed.
    set "windivert_status=stopped and removed"
    goto :END
)

for /f "tokens=3,4 delims=: " %%a in ('sc query WinDivert ^| find "STATE"') do (
    set "state_code=%%a"
    set "state_text=%%b"
)

if "%state_code%"=="1" (
    echo   Result: SUCCESS - WinDivert is STOPPED (%state_text%)
    set "windivert_status=stopped (%state_text%)"
) else if "%state_code%"=="4" (
    echo   Result: WARNING - WinDivert is still RUNNING (%state_text%)
    set "windivert_status=running (%state_text%)"
) else (
    echo   Result: WinDivert status: %state_text% (code: %state_code%)
    set "windivert_status=%state_text% (code: %state_code%)"
)

:END
echo.
echo ========================================
echo          OPERATION COMPLETED
echo ========================================
echo.
echo Summary:
echo 1. Discord app      : %discord_status%
echo 2. DiscordFix windows: %discordfix_status%
if %cmd_closed% equ 0 (
    echo    - CMD windows: not found
) else if %cmd_closed% equ 1 (
    echo    - CMD windows: 1 closed
) else (
    echo    - CMD windows: %cmd_closed% closed
)
if %terminal_closed% equ 0 (
    echo    - Terminal windows: not found
) else if %terminal_closed% equ 1 (
    echo    - Terminal windows: 1 closed
) else (
    echo    - Terminal windows: %terminal_closed% closed
)
echo 3. zapret process   : %zapret_status%
echo 4. WinDivert service: %windivert_status%
echo.
echo ========================================
pause