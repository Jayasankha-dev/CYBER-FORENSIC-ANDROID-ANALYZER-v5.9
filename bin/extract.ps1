# Get the current folder where the script and adb.exe are located
$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $CurrentDir

# Define the ADB path (Since it's in the same bin folder)
$adb = ".\adb.exe"

# Configuration - Saving apps in a folder outside bin (Parent folder)
$ParentDir = Split-Path -Parent $CurrentDir
$outDir = Join-Path $ParentDir "EXTRACTED_APPS"

# Create output directory if it doesn't exist
if (!(Test-Path $outDir)) { 
    New-Item -ItemType Directory -Path $outDir | Out-Null 
}

Write-Host "[*] SCANNING FOR USER INSTALLED APPS..." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

# Using the full path to run ADB
try {
    $packages = & $adb shell pm list packages -3 | ForEach-Object { $_.Replace("package:", "").Trim() }
} catch {
    Write-Host "[ERROR] ADB not found in bin folder!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

foreach ($pkg in $packages) {
    if (-not [string]::IsNullOrWhiteSpace($pkg)) {
        Write-Host "[PROCESS] Package: $pkg" -ForegroundColor Cyan
        
        # Create a clean folder for the app
        $appFolder = Join-Path $outDir $pkg
        if (!(Test-Path $appFolder)) { 
            New-Item -ItemType Directory -Path $appFolder | Out-Null 
        }
        
        # Get all APK paths (handles Split APKs)
        $paths = & $adb shell pm path $pkg | ForEach-Object { $_.Replace("package:", "").Trim() }
        
        foreach ($apkPath in $paths) {
            Write-Host "  [PULLING] -> $apkPath" -ForegroundColor Gray
            & $adb pull $apkPath "$appFolder\"
        }
        
        Write-Host "[+] SUCCESS: $pkg extracted successfully." -ForegroundColor Green
        Write-Host "------------------------------------------------------------"
    }
}

Write-Host "[+] All tasks finished." -ForegroundColor Yellow
Write-Host "[+] Files saved in: $outDir"
Read-Host "Press Enter to continue..."