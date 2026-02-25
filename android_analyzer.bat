@echo off
setlocal enabledelayedexpansion
title CYBER-FORENSIC ANDROID ANALYZER v5.9
mode con: cols=110 lines=9000000
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
echo    [A]  ADVANCED FORENSIC SUITE (Malware Scanner,Live Monitor)
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
if /i "%task%"=="A" goto ADVANCED_HOME
if /i "%task%"=="0" exit
goto MAIN_MENU

:EXTRACT_APK
cls
color 0E
echo ============================================================
echo           STARTING ANDROID APK EXTRACTOR (PS)
echo ============================================================
echo.

:: Pointing to the file inside the "bin" folder
powershell -ExecutionPolicy Bypass -File "bin\extract.ps1"

echo.
echo ============================================================
echo           PROCESS COMPLETED!
echo ============================================================
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
:: Methana call karanne script eke yata thiyana SIM_TYPE ekata
call :SIM_TYPE "--- INTERACTIVE ADB SHELL INTERFACE ---"
echo.
echo Type 'exit' to return to Dashboard.
echo ------------------------------------------------------------
echo.

:cmdloop
:: User input ganna thana
set "usercmd="
set /p "usercmd=ADB_SHELL@%serial%:~# "

:: 'exit' gahuwoth Main Menu ekata yanawa
if /i "%usercmd%"=="exit" goto MAIN_MENU
:: Nikanma Enter gahuwoth loop eka digata yanawa
if "%usercmd%"=="" goto cmdloop

:: ADB shell eka haraha command eka execute kireema
echo.
%ADB% shell %usercmd%
echo.
goto cmdloop

:: ====================================================
:: HELPER: SIMULATED TYPEWRITER EFFECT (Only keep ONE copy at the bottom)
:: ====================================================
:SIM_TYPE
set "text=%~1"
set "char_idx=0"
:type_loop
set "char=!text:~%char_idx%,1!"
if "!char!"=="" echo. & exit /b
<nul set /p "=!char!"
:: Delay eka (300 kiyanne normal speed ekak)
for /l %%a in (1,1,300) do rem
set /a char_idx+=1
goto type_loop

:: ====================================================
:: [A] ADVANCED FORENSIC & REAL-TIME MONITORING
:: ====================================================
:ADVANCED_HOME
cls
color 0B
echo ==========================================================================
echo           CYBER-FORENSIC ADVANCED MODULE - MULTI-PHASE ENGINE
echo ==========================================================================
echo    [1]  HYBRID MALWARE SCAN (Auto + Manual Typewriter Mode)
echo    [2]  LIVE TRAFFIC MONITOR (Netstat / Network Streams)
echo    [3]  PROCESS,RESOURCE TRACKER (CPU / RAM Live)
echo    [4]  SYSTEM OVERLAY DETECTOR (Identify Hidden Windows)
echo    [5]  CLIPBOARD FORENSICS (Extract Live Snippets)
echo    [H]  PANIC MODE: QUICK HACK-DUMP (Extract All)
echo    [J]  ADVANCED APP CONTROL (Auto-Screenshots, Reset, Uninstall)
echo    [T]  NETWORK INTELLIGENCE (Geo-IP Monitor, Reputation)
echo    [0]  RETURN TO MAIN DASHBOARD
echo --------------------------------------------------------------------------
set /p adv_choice="[?] SELECT ADVANCED ACTION: "

if "%adv_choice%"=="1" goto ADV_AUTO_SCAN
if "%adv_choice%"=="2" goto LIVE_NET_MONITOR
if "%adv_choice%"=="3" goto LIVE_PROC_MONITOR
if "%adv_choice%"=="4" goto OVERLAY_CHECK
if "%adv_choice%"=="5" goto CLIP_EXTRACT
if /i "%adv_choice%"=="H" goto QUICK_HACK
if /i "%adv_choice%"=="J" goto APP_CONTROL_ADV
if /i "%adv_choice%"=="T" goto NETWORK_INTELLIGENCE_MENU
if "%adv_choice%"=="0" goto MAIN_MENU
goto ADV_HOME

:: ====================================================
:: [1] HYBRID MALWARE SCANNER (ENHANCED & STABLE)
:: ====================================================
:ADV_AUTO_SCAN
cls
color 0A
echo ==========================================================================
echo          INTEL-CORE: MULTI-PHASE SYSTEM INTEGRITY AUDIT
echo ==========================================================================
echo  [*] INITIALIZING HEURISTIC ANALYSIS ENGINE...
echo.

:: --- PHASE A: DIRECTORY INTEGRITY ---
:: Removed '&' to prevent command-line crashes
echo [PHASE 1]: AUDITING TEMPORARY AND HIDDEN STORAGE...
set "cmd_a=adb shell ls -laR /data/local/tmp /sdcard/ ^| grep '^\.'"
call :SIM_TYPE "[EXEC_AUDIT]: !cmd_a!" 25

echo --------------------------------------------------------------------------
:: Auditing temp directory for suspicious payloads
%ADB% shell "ls -la /data/local/tmp"
echo --------------------------------------------------------------------------
echo [REPORT]: Analyzing directory for unauthorized binary executions...

echo.
echo [?] MANUAL OVERRIDE: Would you like to explore these paths manually? (Y/N)
set /p "minp=>> "
if /i "%minp%"=="Y" (
    echo.
    echo ============================================================
    echo           MANUAL FORENSIC COMMANDS (CHEATSHEET)
    echo ============================================================
    echo  1. ls -laR /sdcard/ ^| grep '^\.'  (View Hidden Files)
    echo  2. ls -F /data/local/tmp/         (View Executables)
    echo  3. exit                            (Return to Auto-Scan)
    echo ============================================================
    %ADB% shell
    echo [*] RESUMING AUTOMATED AUDIT...
)

:: --- PHASE B: DEEP APPLICATION ANALYSIS ---
echo.
echo [PHASE 2]: ANALYZING THIRD-PARTY PACKAGE SIGNATURES...
timeout /t 1 >nul

for /f "tokens=2 delims=:" %%p in ('%ADB% shell pm list packages -3') do (
    set "pkg=%%p"
    set "pkg=!pkg:~0,-1!"
    set "risk=0"
    set "reasons="
    
    :: Clean inline output for package auditing
    <nul set /p "=[AUDITING]: !pkg! "
    
    :: Logic 1: Keyword Analysis (Name Spoofing)
    echo !pkg! | findstr /i "spy stealer tracker remote hack trojan" >nul
    if !errorlevel! equ 0 (
        set /a risk+=5
        set "reasons=!reasons! [Suspicious Name]"
    )
    
    :: Logic 2: Accessibility Abuse Check
    %ADB% shell "dumpsys package !pkg! | grep BIND_ACCESSIBILITY_SERVICE" >nul
    if !errorlevel! equ 0 (
        set /a risk+=10
        set "reasons=!reasons! [Accessibility Privilege]"
    )

    :: Risk Reporting
    if !risk! geq 5 (
        echo.
        color 0C
        echo    --------------------------------------------------------
        echo    [!] CRITICAL ALERT: HIGH RISK DETECTED
        echo    [PACKAGE]: !pkg!
        echo    [SCORE  ]: !risk!/15
        echo    [REASONS]: !reasons!
        echo    --------------------------------------------------------
        echo    [1] View Permissions  [2] View Install Source  [3] Skip
        set /p "s_act=>> "
        if "!s_act!"=="1" %ADB% shell "dumpsys package !pkg! | grep android.permission" && pause
        if "!s_act!"=="2" %ADB% shell "pm get-install-source !pkg!" && pause
        color 0A
    ) else (
        echo [OK]
    )
    :: Forensic delay for visual effect
    for /l %%a in (1,1,100) do rem 
)

echo.
echo ==========================================================================
echo [+] SYSTEM AUDIT COMPLETED SUCCESSFULLY.
echo ==========================================================================
pause
goto ADVANCED_HOME

:: ====================================================
:: [2] LIVE NETWORK MONITOR (REAL-TIME SCROLL)
:: ====================================================
:LIVE_NET_MONITOR
cls
color 0B
echo.
echo  __________________________________________________________
echo ^|                                                          ^|
echo ^|    NET-TRACE : REAL-TIME NETWORK FORENSIC STREAM         ^|
echo ^|__________________________________________________________^|
echo.
echo  [*] TARGET DEVICE : %serial%
echo  [*] STREAM STATUS : ACTIVE MONITORING
echo  [*] [EXIT]        : PRESS 'Q' TO RETURN TO ADVANCED MENU
echo -----------------------------------------------------------
echo   LOCAL IP             REMOTE IP            STATE
echo -----------------------------------------------------------

:net_loop
:: Fetching live connections. Using ^| to ensure stability.
%ADB% shell "netstat -ant ^| grep ESTABLISHED"

:: Logic: Wait 1 second. If no key is pressed, default to 'C' (Continue).
:: This stops the "auto-exit" bug you had before.
choice /c qc /n /t 1 /d c >nul 2>&1

:: If 'Q' is pressed (Choice 1), exit the loop.
if %errorlevel% equ 1 (
    echo.
    echo  [!] TERMINATING DATA STREAM...
    timeout /t 1 >nul
    goto ADVANCED_HOME
)

:: Loop back for the scrolling effect
goto net_loop

:: ====================================================
:: [3] LIVE PROCESS MONITOR (FINAL STABLE VERSION)
:: ====================================================
:LIVE_PROC_MONITOR
cls
color 0B
echo ==========================================================================
echo          REAL-TIME RESOURCE AUDIT: CPU AND PROCESS MONITORING
echo ==========================================================================
echo  [*] TIMESTAMP  : %date% ^| %time%
echo  [*] ANALYZER   : CYBER-FORENSIC ENGINE v5.8
echo  [*] TARGET     : %serial%
echo --------------------------------------------------------------------------
echo  [SYSTEM LOG]: Capturing active process execution tree...
echo.

:: Just run the top command. It's the most reliable way.
%ADB% shell "top -n 1"

echo.
echo --------------------------------------------------------------------------
echo  [MEMORY USAGE SUMMARY]:
:: Using Android's internal grep to avoid "findstr not found" error
%ADB% shell "dumpsys meminfo | grep 'Used RAM'"
echo --------------------------------------------------------------------------
echo  [ACTION]: PRESS ANY KEY TO RETURN TO THE ADVANCED MENU...
pause >nul
goto ADVANCED_HOME

:OVERLAY_CHECK
cls
color 0E
echo ============================================================
echo [!] MONITORING ACTIVE WINDOW FOCUS (Overlay Detector)
echo ============================================================
echo [*] Target Device: %serial%
echo [*] Instruction  : Interact with the phone to see focus changes.
echo [*] Exit         : Press 'Q' to return to Advanced Menu.
echo ------------------------------------------------------------

:win_loop
:: Fetching only the current focused window
<nul set /p "= [LIVE FOCUS]: "
%ADB% shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'"

:: Waiting 1 second. 'Q' gahuwoth exit wenawa, nathi nam Continue (C) wenawa.
choice /c qc /n /t 1 /d c >nul 2>&1

if %errorlevel% equ 1 (
    echo.
    echo [*] Stopping Overlay Monitor...
    timeout /t 1 >nul
    goto ADVANCED_HOME
)

goto win_loop


:CLIP_EXTRACT
cls
color 0D
echo ============================================================
echo [!] ACTION: EXTRACTING LIVE CLIPBOARD DATA
echo ============================================================

:: Phone eka awake karala screen eka focus kireema
%ADB% shell input keyevent 82 >nul 2>&1

echo [*] Method 1: Checking Service State...
echo ------------------------------------------------------------

:: Method 1: Dumpsys clipboard (Meka godak welawata wada karanawa)
:: Meken clipboard eke thiyana anthima text eka hoyaganna puluwan
%ADB% shell dumpsys clipboard | findstr "mText"

echo.
echo [*] Method 2: Raw Parcel Analysis...
:: Method 2: Service call (Hex output)
%ADB% shell service call clipboard 2 | findstr "Result"

echo ------------------------------------------------------------
echo.
echo [ADVISORY]
echo 1. If 'mText' is missing, the clipboard is EMPTY.
echo 2. On Android 12+, you MUST have the screen ON and 
echo    be on the Home Screen or in an App for this to work.
echo 3. Some OEMs (Samsung/Xiaomi) block this entirely via ADB.
echo.
pause
goto ADVANCED_HOME

:: ====================================================
:: [H] ELITE DATA SNATCHER (MULTI-THREADED & DEEP SCAN)
:: ====================================================
:QUICK_HACK
cls
color 0C
echo ==========================================================================
echo            !!! WARNING: INITIATING ELITE EXTRACTION PROTOCOL !!!
echo ==========================================================================

:: Generating Secure Timestamp for Folder Naming
set "t=%time: =0%"
set "TSTAMP=%t:~0,2%%t:~3,2%%t:~6,2%"
set "HACK_DIR=ELITE_DUMP_%serial%_%TSTAMP%"
mkdir "%HACK_DIR%" 2>nul

echo [*] PHASE 1: ACQUIRING SYSTEM ^& APP DATABASE RECORDS...
:: Creating dedicated database sub-directory
mkdir "%HACK_DIR%\Databases"
echo [LOG] Extracting SMS Messages...
%ADB% shell "content query --uri content://sms/" > "%HACK_DIR%\Databases\sms.txt" 2>nul
echo [LOG] Extracting Contact Lists...
%ADB% shell "content query --uri content://com.android.contacts/data" > "%HACK_DIR%\Databases\contacts.txt" 2>nul
echo [LOG] Extracting Call Histories...
%ADB% shell "content query --uri content://call_log/calls" > "%HACK_DIR%\Databases\calls.txt" 2>nul

echo [*] PHASE 2: EXECUTING DEEP STORAGE DISCOVERY (PDF, DOCX, ZIP)...
:: Crawling the entire SDCard for high-value document types
%ADB% shell "find /sdcard/ -type f \( -name '*.pdf' -o -name '*.docx' -o -name '*.zip' \)" > "%HACK_DIR%\discovered_files.txt" 2>nul

echo [*] PHASE 3: BUNDLING MULTIMEDIA ^& ENCRYPTED APP CONTAINERS...
:: Target paths for Telegram, WhatsApp, and System Media
set "T_MEDIA=/sdcard/Android/media/org.telegram.messenger /sdcard/Telegram"
set "W_MEDIA=/sdcard/Android/media/com.whatsapp /sdcard/WhatsApp"
set "S_MEDIA=/sdcard/DCIM /sdcard/Download /sdcard/Pictures /sdcard/Movies"

echo [!] Bundling High-Capacity Stream - Do Not Disconnect Device...
:: Tar bundling handles MP4, MKV, JPG, and other extensions automatically within paths
%ADB% shell "tar -cvf /sdcard/snatch.tar %T_MEDIA% %W_MEDIA% %S_MEDIA% 2>/dev/null"
echo [!] Pulling Archive to Host PC...
%ADB% pull /sdcard/snatch.tar "%HACK_DIR%\storage_bundle.tar"
%ADB% shell "rm /sdcard/snatch.tar"

echo [*] PHASE 4: NETWORK ^& VOLATILE DATA ACQUISITION...
echo [LOG] Dumping Wi-Fi Statistics...
%ADB% shell "dumpsys wifi" > "%HACK_DIR%\wifi_dump.txt" 2>nul
echo [LOG] Attempting Clipboard Extraction...
%ADB% shell "service call clipboard 2" > "%HACK_DIR%\clipboard_raw.txt" 2>nul

echo [*] PHASE 5: CAPTURING LIVE SCREEN EVIDENCE...
%ADB% shell "screencap -p /sdcard/evid.png"
%ADB% pull /sdcard/evid.png "%HACK_DIR%\forensic_screenshot.png" >nul
%ADB% shell "rm /sdcard/evid.png"

echo [*] PHASE 6: GENERATING EXTRACTION MANIFEST...
:: List the contents of the grabbed folder for a quick summary
dir "%HACK_DIR%" /B > "%HACK_DIR%\manifest.txt"

echo ==========================================================================
echo [+] ELITE EXTRACTION SUCCESSFUL!
echo [+] DATA DIRECTORY: %HACK_DIR%
echo --------------------------------------------------------------------------
echo [ANALYSIS TIP]: Use '7-Zip' to inspect 'storage_bundle.tar'
echo [NOTICE]: Large video files (MP4/MKV) are located inside the bundle.
echo ==========================================================================
pause
goto ADVANCED_HOME

:APP_CONTROL_ADV
cls
color 0B
echo ============================================================
echo           ADVANCED APP CONTROL SYSTEM (PS)
echo ============================================================
echo.
powershell -ExecutionPolicy Bypass -File "bin\app_control.ps1"
goto MAIN_MENU

:NETWORK_INTELLIGENCE_MENU
cls
echo ==========================================================================
echo                NETWORK INTELLIGENCE ^& GEO-IP ANALYSIS
echo ==========================================================================
echo [*] Initializing Advanced Modules...

:: 1. Check if libraries are already extracted
if exist "bin\geoip2" (
    echo [+] Dependencies: READY
    timeout /t 1 >nul
    goto SHOW_NET_MENU
)

:: 2. If not extracted, check for the ZIP archive
if exist "bin\geoip2_lib.zip" (
    echo [!] Extracting local libraries... (First-time setup)
    
    :: Using Windows native tar command to extract into the bin folder
    tar -xf "bin\geoip2_lib.zip" -C "bin"
    
    if %errorlevel% equ 0 (
        echo [+] Extraction successful!
        timeout /t 2 >nul
        goto SHOW_NET_MENU
    ) else (
        color 0C
        echo [ERROR] Failed to extract libraries. Ensure 'bin\geoip2_lib.zip' is not corrupted.
        pause
        color 0B
        goto ADVANCED_HOME
    )
) else (
    color 0C
    echo [ERROR] Dependency archive (bin\geoip2_lib.zip) not found!
    echo [!] Please ensure the required library pack is in the bin directory.
    pause
    color 0B
    goto ADVANCED_HOME
)

:SHOW_NET_MENU
cls
echo ==========================================================================
echo                NETWORK INTELLIGENCE ^& GEO-IP ANALYSIS
echo ==========================================================================
echo    [1]  LIVE TRAFFIC MONITOR (With Geo-Location Tags)
echo    [2]  IP REPUTATION CHECKER (Paste ^& Analyze Origins)
echo    [3]  UID RESOLVER (Find App Name from Android UID
echo    [0]  BACK TO ADVANCED MENU
echo --------------------------------------------------------------------------
set /p net_choice="[?] SELECT ACTION: "

if "%net_choice%"=="1" goto LIVE_NET_MONITOR
if "%net_choice%"=="2" goto IP_REPUTATION_CHECKER
if "%net_choice%"=="3" goto UID_RESOLVER_TOOL
if "%net_choice%"=="0" goto ADVANCED_HOME
goto SHOW_NET_MENU


:LIVE_NET_MONITOR
:: 'cls' clears the previous table so the new one starts at the top
cls
echo ==========================================================================
echo           LIVE TRAFFIC MONITOR WITH GEOLOCATION INTELLIGENCE
echo ==========================================================================
echo [*] Fetching Network Streams from Device...

:: Logic update idea
if "!state!"=="ESTABLISHED" (
    set "owner_info=[UID:!uid!]"
) else (
    set "owner_info=[System/Kernel Handover]"
)

:: Use -tuapne to ensure the UID is included in the output
%ADB% shell "netstat -tuapne" > bin\temp_net.txt 2>nul

:: Call Python to analyze and print the results
python bin\ip_analyzer.py bin\temp_net.txt

echo --------------------------------------------------------------------------
echo [R] REFRESH STREAM   [0] RETURN TO MENU
echo --------------------------------------------------------------------------
set /p net_opt="[?] SELECT ACTION: "

:: /i makes it work for both 'r' and 'R'
if /i "%net_opt%"=="R" goto LIVE_NET_MONITOR
if "%net_opt%"=="0" goto NETWORK_INTELLIGENCE_MENU

:: If they press anything else, just refresh anyway
goto LIVE_NET_MONITOR

:IP_REPUTATION_CHECKER
cls
echo ==========================================================================
echo                      IP REPUTATION , ORIGIN CHECKER
echo ==========================================================================
echo [!] PASTE RAW LOG DATA BELOW (Right-click to Paste)
echo [!] To Process: Press ENTER, then CTRL+Z, then ENTER.
echo --------------------------------------------------------------------------
more > bin\user_input.txt
echo.
echo [*] Analyzing IP Origins and Intelligence...
python bin\ip_analyzer.py bin\user_input.txt
pause
goto NETWORK_INTELLIGENCE_MENU


:UID_RESOLVER_TOOL
cls
color 0B
echo ==========================================================================
echo                ANDROID SYSTEM UID ^& PACKAGE RESOLVER
echo ==========================================================================
echo  [STATUS] Fetching installed packages and their UIDs...
echo.
echo  %-12s ^| %-50s
echo  --------------------------------------------------------------------------

:: Loop through all packages and pull their specific userId (UID)
for /f "tokens=2 delims=:" %%P in ('%ADB% shell pm list packages') do (
    set "full_pkg=%%P"
    :: Remove any hidden carriage returns or spaces to fix the naming issue
    set "pkg=!full_pkg: =!"
    
    :: Extract the numerical UID using dumpsys for better accuracy
    for /f "tokens=1" %%U in ('%ADB% shell "dumpsys package !pkg! | grep userId="') do (
        set "uid_line=%%U"
        set "uid_val=!uid_line:userId=!"
        
        :: Print the result in a clean table format
        echo  UID: !uid_val!	^| Package: !pkg!
    )
)

echo --------------------------------------------------------------------------
echo [+] Total packages resolved.
echo.
echo [1] Search for specific UID
echo [0] Back to Network Intelligence
set /p uid_choice="[?] SELECT ACTION: "

if "%uid_choice%"=="1" (
    set /p search_uid="Enter UID to find (e.g. 10145): "
    cls
    echo Searching for UID: !search_uid!
    echo ------------------------------------------------------------
    %ADB% shell pm list packages -u | findstr "!search_uid!"
    pause
    goto UID_RESOLVER_TOOL
)
if "%uid_choice%"=="0" goto NETWORK_INTELLIGENCE_MENU
goto UID_RESOLVER_TOOL
