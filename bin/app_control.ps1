$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $CurrentDir
$adb = ".\adb.exe"
$ParentDir = Split-Path -Parent $CurrentDir
$screenDir = Join-Path $ParentDir "App_Screenshots"

if (!(Test-Path $screenDir)) { New-Item -ItemType Directory -Path $screenDir | Out-Null }

Write-Host "--- ADVANCED APP CONTROL ENGINE ---" -ForegroundColor Cyan
Write-Host "[1] Automated Screenshotter (All User Apps)"
Write-Host "[2] Force Stop & Clear Data (App Reset)"
Write-Host "[3] Quick Uninstall (Bloatware Remover)"
$choice = Read-Host "Select Action"

$packages = & $adb shell pm list packages -3 | ForEach-Object { $_.Replace("package:", "").Trim() }

if ($choice -eq "1") {
    foreach ($pkg in $packages) {
        if ($pkg) {
            Write-Host "[*] Opening: $pkg" -ForegroundColor Yellow
            & $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 | Out-Null
            Start-Sleep -Seconds 3 
            
            $file = "$pkg.png"
            & $adb shell screencap -p /sdcard/s.png
            & $adb pull /sdcard/s.png "$screenDir\$file" | Out-Null
            Write-Host "[+] Captured: $file" -ForegroundColor Green
            
            & $adb shell am force-stop $pkg
        }
    }
}
elseif ($choice -eq "2") {
    $target = Read-Host "Enter Package Name to Reset"
    & $adb shell pm clear $target
    Write-Host "[+] Data Cleared for $target" -ForegroundColor Green
}
elseif ($choice -eq "3") {
    $target = Read-Host "Enter Package Name to Uninstall"
    & $adb shell pm uninstall -k --user 0 $target
    Write-Host "[+] Uninstalled: $target" -ForegroundColor Red
}
Read-Host "Done! Press Enter"