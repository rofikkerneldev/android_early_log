@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Android Early Log Pull by RofikKernelDev

:: =========================================================
::  Android Early Log Pull
::  Created by: RofikKernelDev (t.me/rofikkerneldev)
:: =========================================================

echo ==========================================
echo       Android Early Log Pull
echo       By: RofikKernelDev
echo       Telegram: t.me/rofikkerneldev
echo ==========================================
echo.

:: ---------------------------------------------------------
:: Check ADB Availability
:: ---------------------------------------------------------
where adb >nul 2>&1
if errorlevel 1 (
    echo [ERROR] adb not found in PATH.
    pause
    exit /b 1
)

:: ---------------------------------------------------------
:: Wait for Device (Normal or Recovery Mode)
:: ---------------------------------------------------------
:WAIT_DEVICE
cls
echo ==========================================
echo       Waiting for Android Device...
echo ==========================================
echo.
echo Connect your device with USB Debugging enabled or in Recovery mode.
echo.

set "MODE="
for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" set "MODE=device"
    if "%%B"=="recovery" set "MODE=recovery"
)

if not defined MODE (
    echo No authorized device detected.
    echo.
    echo Current ADB Status:
    adb devices
    timeout /t 3 >nul
    goto WAIT_DEVICE
)

echo Device detected in [!MODE!] mode.
echo.

:: ---------------------------------------------------------
:: Get Today's Date (Format: YYYYMMDD)
:: ---------------------------------------------------------
for /f %%i in ('wmic os get localdatetime ^| find "."') do set "dt=%%i"
set "TODAY=%dt:~0,4%%dt:~4,2%%dt:~6,2%"

set "OUTDIR=earlylog_%TODAY%"

:: If folder already exists, rename old folder to backup
if exist "%OUTDIR%" (
    echo [INFO] Folder %OUTDIR% already exists. Renaming to backup...
    
    :: Find available backup name (earlylog_YYYYMMDD_backup, _backup2, etc.)
    set "BACKUP_DIR=%OUTDIR%_backup"
    set /a count=1
    :LOOP_BACKUP
    if exist "!BACKUP_DIR!" (
        set /a count+=1
        set "BACKUP_DIR=%OUTDIR%_backup!count!"
        goto LOOP_BACKUP
    )
    
    :: earlylog_YYYYMMDD has 16 characters, skip 16 chars to get the rest of the name
    ren "%OUTDIR%" "!BACKUP_DIR:~16!" 2>nul
)

mkdir "%OUTDIR%"

:: ---------------------------------------------------------
:: Pull Early Log Data from Android
:: ---------------------------------------------------------
echo Pulling early log data...
adb pull /sys/fs/pstore "%OUTDIR%"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to pull early log data.
    pause
    exit /b 1
)

:: Enter pulled pstore directory inside earlylog folder
if exist "%OUTDIR%\pstore" (
    cd /d "%OUTDIR%\pstore"
) else (
    echo.
    echo [ERROR] Pulled early log directory not found.
    pause
    exit /b 1
)

:: ---------------------------------------------------------
:: Rename Files Safely (Format: name_YYYYMMDD.ext.txt)
:: ---------------------------------------------------------
echo.
echo Renaming files...

for %%f in (*) do (
    set "FULLNAME=%%~nxf"
    set "FILENAME=%%~nf"
    set "EXT=%%~xf"

    :: Skip already processed files
    echo "!FULLNAME!" | findstr /r "_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].*txt$" >nul
    if errorlevel 1 (
        if "!EXT!"=="" (
            ren "%%f" "!FILENAME!_%TODAY%.txt"
        ) else (
            ren "%%f" "!FILENAME!_%TODAY%!EXT!.txt"
        )
    )
)

:: ---------------------------------------------------------
:: Detect Text Editor (Notepad++ / Stock Notepad)
:: ---------------------------------------------------------
set "EDITOR_PATH=C:\Program Files\Notepad++\notepad++.exe"
if not exist "%EDITOR_PATH%" set "EDITOR_PATH=C:\Program Files (x86)\Notepad++\notepad++.exe"
if not exist "%EDITOR_PATH%" set "EDITOR_PATH=notepad.exe"

:: ---------------------------------------------------------
:: Open Ramoops Logs Automatically
:: ---------------------------------------------------------
echo.
echo Opening console-ramoops log files...

for %%f in (console-ramoops*.txt) do (
    start "" "%EDITOR_PATH%" "%%f"
)

echo.
echo Done.
pause
exit /b 0
