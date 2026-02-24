@echo off
setlocal enabledelayedexpansion
title CYBER-FORENSIC ANDROID ANALYZER v5.8
mode con: cols=110 lines=45
color 0A

:: ====================================================
:: ADB SMART PATH SETUP
:: ====================================================
if exist "bin\adb.exe" (
    set "ADB=bin\adb.exe"
) else if exist "adb.exe" (
    set "ADB=adb.exe"
) else (
    set "ADB=adb"
)

set "LOG_DIR=Forensic_Reports"
set "SCREEN_DIR=Screenshots"
set "OUT_DIR=Extracted_Apps"
set "PULL_DIR=Pulled_Data"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%SCREEN_DIR%" mkdir "%SCREEN_DIR%"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if not exist "%PULL_DIR%" mkdir "%PULL_DIR%"

:CHECK_DEVICE
cls
echo ==========================================================================
echo    [+] SYSTEM STATUS: WAITING FOR DEVICE... (Ensure USB Debugging is ON)
echo ==========================================================================
%ADB% version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [ERROR] ADB not found! 
    echo Please ensure adb.exe is in the 'bin' folder or system PATH.
    pause
    exit
)

%ADB% wait-for-device
for /f "tokens=1" %%i in ('%ADB% get-serialno') do set serial=%%i
echo    [+] DEVICE DETECTED: %serial%
timeout /t 2 >nul

:MAIN_MENU
cls
color 0A
echo ==========================================================================
echo                 CYBER-SECURITY ANDROID ANALYZER - DASHBOARD
echo ==========================================================================
echo    CONNECTED AS: %serial%         REPORTS: %LOG_DIR%
echo --------------------------------------------------------------------------
echo    [1]  QUICK AUDIT        [6]  PROCESS MANAGER
echo    [2]  NETWORK SCAN       [7]  SECURE WIPE (SDCARD)
echo    [3]  ADVANCED APPS      [8]  EXTRACT USER APKs
echo    [4]  SYSTEM INTEGRITY   [9]  REBOOT OPTIONS
echo    [5]  LIVE LOGCAT        [C]  CUSTOM ADB SHELL
echo.
echo    --- FORENSIC DATA EXTRACTION ---
echo    [S]  CAPTURE SCREENSHOT    [M]  DUMP SMS MESSAGES
echo    [K]  DUMP CONTACT LIST     [L]  DUMP CALL LOGS
echo.
echo    --- PC-DEVICE FILE TRANSFER ---
echo    [P]  PUSH FILES (PC to Phone - Drag ^& Drop)
echo    [G]  SMART MULTI-PULL (Select Folders to Download)
echo    [0]  EXIT
echo --------------------------------------------------------------------------
set /p task="[?] SELECT ACTION: "

if /i "%task%"=="1" goto QUICK_AUDIT
if /i "%task%"=="2" goto NET_SCAN
if /i "%task%"=="3" goto APP_FORENSIC
if /i "%task%"=="4" goto SYS_INTEG
if /i "%task%"=="5" goto LOGCAT_LIVE
if /i "%task%"=="6" goto PROC_MGR
if /i "%task%"=="7" goto SANITIZER
if /i "%task%"=="8" goto EXTRACT_APK
if /i "%task%"=="9" goto REBOOT_MENU
if /i "%task%"=="S" goto CAPTURE_SCREEN
if /i "%task%"=="M" goto DUMP_SMS
if /i "%task%"=="K" goto DUMP_CONTACTS
if /i "%task%"=="L" goto DUMP_CALLS
if /i "%task%"=="P" goto DEPLOY_FILES
if /i "%task%"=="G" goto MULTI_PULL
if /i "%task%"=="C" goto CUSTOM_CMD
if /i "%task%"=="0" exit
goto MAIN_MENU

:: ====================================================
:: [8] EXTRACT APKs (FIXED)
:: ====================================================
:: ====================================================
:: [8] EXTRACT APKs (STABLE VERSION)
:: ====================================================
:EXTRACT_APK
cls
color 0E
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo [*] SCANNING FOR USER INSTALLED APPS...
echo ------------------------------------------------------------

:: Export package list to a temp file
%ADB% shell pm list packages -3 > "%temp%\pkgs.txt"

for /f "tokens=2 delims=:" %%p in ('type "%temp%\pkgs.txt"') do (
    :: Clean the package name (removes the hidden carriage return)
    set "pkg=%%p"
    set "pkg=!pkg:~0,-1!"
    
    echo [PROCESS] Package: !pkg!
    
    :: Get the path of the APK on the phone
    for /f "tokens=2 delims=:" %%a in ('%ADB% shell pm path !pkg!') do (
        set "apkpath=%%a"
        set "apkpath=!apkpath:~0,-1!"
        
        echo [PULLING] From: !apkpath!
        
        :: Execute the pull command
        %ADB% pull "!apkpath!" "%OUT_DIR%\!pkg!.apk"
        
        if exist "%OUT_DIR%\!pkg!.apk" (
            echo [+] SUCCESS: !pkg!.apk saved.
        ) else (
            echo [X] FAILED: Could not pull !pkg!. 
            echo     (This happens if the app is a 'Split APK' or Protected)
        )
    )
    echo ------------------------------------------------------------
)

del "%temp%\pkgs.txt"
echo [+] Extraction Process Finished.
pause
goto MAIN_MENU

:: ====================================================
:: [G] SMART MULTI-PULL (SELECT FOLDERS)
:: ====================================================
:MULTI_PULL
cls
color 0E
echo [*] SCANNING SDCARD DIRECTORIES...
echo ------------------------------------------------------------
set count=0
for /f "delims=" %%d in ('%ADB% shell "ls -d /sdcard/*/ 2>/dev/null"') do (
    set /a count+=1
    set "folder[!count!]=%%d"
    echo [!count!] %%d
)
echo ------------------------------------------------------------
echo [TIP] Enter folder numbers separated by SPACES (e.g. 1 3 5)
set /p "selection=[?] Select folder numbers to PULL: "
echo.
for %%n in (%selection%) do (
    set "target_path=!folder[%%n]!"
    set "target_name=!target_path:~0,-1!"
    set "target_name=!target_name:/sdcard/=!"
    echo [*] Downloading: !target_name!
    %ADB% pull "!target_path!." "%PULL_DIR%\!target_name!"
)
echo [+] Selection pulled to %PULL_DIR%
pause
goto MAIN_MENU

:: ====================================================
:: [P] PUSH FILES (DRAG ^& DROP)
:: ====================================================
:DEPLOY_FILES
cls
color 0B
echo [*] DRAG AND DROP FILE/FOLDER FROM PC INTO THIS WINDOW...
set /p "source_raw="[?] Source Path: "
set "source_path=%source_raw:"=%"
echo.
echo [1] Internal Storage (/sdcard/)
echo [2] Downloads Folder (/sdcard/Download/)
set /p "loc_choice="[?] Target Location (1-2): "
if "%loc_choice%"=="1" set "dest_phone=/sdcard/"
if "%loc_choice%"=="2" set "dest_phone=/sdcard/Download/"
echo [*] Deploying to device...
%ADB% push "%source_path%" "%dest_phone%"
if %errorlevel% equ 0 (echo [+] SUCCESS!) else (echo [X] FAILED!)
pause
goto MAIN_MENU

:: ====================================================
:: [S, M, K, L] FORENSIC TOOLS
:: ====================================================
:CAPTURE_SCREEN
cls
set "TSTAMP=%time:~0,2%%time:~3,2%%time:~6,2%"
set "TSTAMP=%TSTAMP: =0%"
set "FILE_NAME=SCR_%serial%_%TSTAMP%.png"
%ADB% shell screencap -p /sdcard/screen.png
%ADB% pull /sdcard/screen.png "%SCREEN_DIR%\%FILE_NAME%" >nul
%ADB% shell rm /sdcard/screen.png
echo [+] Saved to %SCREEN_DIR%\%FILE_NAME%
pause
goto MAIN_MENU

:DUMP_SMS
cls
%ADB% shell "content query --uri content://sms/inbox --projection address,body,date" > "%LOG_DIR%\SMS_%serial%.txt"
echo [+] SMS Dumped to %LOG_DIR%
pause
goto MAIN_MENU

:DUMP_CONTACTS
cls
%ADB% shell "content query --uri content://com.android.contacts/data --projection display_name:data1 --where 'mimetype=\"vnd.android.cursor.item/phone_v2\"'" > "%LOG_DIR%\Contacts_%serial%.txt"
echo [+] Contacts Dumped to %LOG_DIR%
pause
goto MAIN_MENU

:: ====================================================
:: [L] DUMP CALL LOGS (FIXED & HARDENED)
:: ====================================================
:DUMP_CALLS
cls
color 0D
set "CALL_FILE=%LOG_DIR%\CallLogs_%serial%.txt"

echo [*] BYPASSING SECURITY: GRANTING CALL_LOG PERMISSIONS...
:: Granting permissions to ADB shell to fix NullPointerException
%ADB% shell pm grant com.android.shell android.permission.READ_CALL_LOG >nul 2>&1
%ADB% shell pm grant com.android.providers.contacts android.permission.READ_CALL_LOG >nul 2>&1

echo [*] ATTEMPTING TO EXTRACT CALL LOGS...
echo ------------------------------------------------------------

:: Run content query and capture both output and errors
%ADB% shell "content query --uri content://call_log/calls --projection number,type,date,duration" > "%CALL_FILE%" 2>&1

:: Check if the output contains Java errors
findstr /I "Error Exception NullPointer" "%CALL_FILE%" >nul
if %errorlevel% equ 0 (
    color 0C
    echo [X] ACCESS DENIED: Android Security Blocked the Request.
    echo.
    echo [FIXES TO TRY]:
    echo     1. Unlock the phone screen and keep it awake.
    echo     2. Go to Developer Options and Enable:
    echo        - "USB Debugging (Security Settings)"
    echo        - "Disable adb authorization timeout"
    echo.
    echo [LOG] The full Java error has been saved to the report file.
) else (
    :: Verify if data was actually collected
    for /f %%A in ("%CALL_FILE%") do (
        if %%~zA equ 0 (
            echo [!] Extraction finished, but the Call Log appears to be empty.
        ) else (
            echo [+] SUCCESS: Call Log extracted successfully!
            echo [+] Report Location: %CALL_FILE%
            echo.
            echo [TIP] Column Order: Number, Type, Date, Duration
        )
    )
)
echo ------------------------------------------------------------
pause
goto MAIN_MENU

:: ====================================================
:: KEEPING YOUR ORIGINAL SYSTEM TOOLS (1-7, 9, C)
:: ====================================================
:QUICK_AUDIT
cls
echo [*] RUNNING QUICK AUDIT...
set "REPORT_FILE=%LOG_DIR%\Audit_%serial%.txt"
(
    echo --- AUDIT REPORT [%date% %time%] ---
    echo [DEVICE] : %serial%
    echo [MODEL]  : 
    %ADB% shell getprop ro.product.model
    echo [VERSION]: 
    %ADB% shell getprop ro.build.version.release
    echo [ACCOUNTS]:
    %ADB% shell dumpsys account | findstr "Account {"
    echo [BATTERY] :
    %ADB% shell dumpsys battery | findstr "level status health"
    echo [UPTIME]  :
    %ADB% shell uptime
) > "%REPORT_FILE%"
type "%REPORT_FILE%"
pause
goto MAIN_MENU

:NET_SCAN
cls
color 0B
echo [*] MONITORING LIVE CONNECTIONS...
%ADB% shell netstat -ant | findstr "ESTABLISHED"
echo [*] LISTENING PORTS:
%ADB% shell netstat -lnt
pause
goto MAIN_MENU

:APP_FORENSIC
cls
echo [A] User Apps  [B] Hidden/Disabled  [C] Permission Check
set /p sub="Select Type: "
if /i "%sub%"=="A" %ADB% shell pm list packages -3 & pause
if /i "%sub%"=="B" %ADB% shell pm list packages -d & pause
if /i "%sub%"=="C" (
    set /p pkg="Package Name: "
    %ADB% shell dumpsys package !pkg! | findstr "android.permission"
    pause
)
goto MAIN_MENU

:SYS_INTEG
cls
color 0C
echo [*] SCANNING FOR SUSPICIOUS FILES...
%ADB% shell ls -la /data/local/tmp
echo.
%ADB% shell df -h
echo.
%ADB% shell find /sdcard -maxdepth 2 -name ".*"
pause
goto MAIN_MENU

:LOGCAT_LIVE
cls
%ADB% logcat -v time
goto MAIN_MENU

:PROC_MGR
cls
color 0B
%ADB% shell "top -n 1 -m 15 -s cpu"
echo TOTAL RAM USAGE SUMMARY:
%ADB% shell "dumpsys meminfo | grep 'Used RAM'"
pause
goto MAIN_MENU

:SANITIZER
cls
color 0C
echo [!!!] WARNING: DATA DESTRUCTION PROTOCOL [!!!]
set /p confirm="Type 'DESTROY' to confirm: "
if not "%confirm%"=="DESTROY" goto MAIN_MENU
%ADB% shell "dd if=/dev/zero of=/sdcard/wipe_blob.tmp bs=1M || echo Disk_Full"
%ADB% shell "rm /sdcard/wipe_blob.tmp"
echo [+] Wipe finished successfully.
pause
goto MAIN_MENU

:REBOOT_MENU
cls
echo [1] Normal  [2] Recovery  [3] Bootloader
set /p reb="Choice: "
if "%reb%"=="1" %ADB% reboot
if "%reb%"=="2" %ADB% reboot recovery
if "%reb%"=="3" %ADB% reboot bootloader
goto MAIN_MENU

:CUSTOM_CMD
cls
color 0F
echo Type 'exit' to return.
:cmdloop
set /p "usercmd=ADB_SHELL@%serial%:~# "
if /i "%usercmd%"=="exit" goto MAIN_MENU
%ADB% shell %usercmd%
goto cmdloop