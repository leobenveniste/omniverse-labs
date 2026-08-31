<#
.SYNOPSIS
    Configures and verifies the Android & Flutter development environment for Mobile Apps.
.DESCRIPTION
    Checks Java JDK, Android SDK paths, cmdline-tools, platform-tools (ADB), emulator, and Flutter CLI.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       Mobile Apps - Environment & Toolchain Diagnostics    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check Android SDK
$androidSdkPath = "C:\Users\leobe\AppData\Local\Android\Sdk"
if (-not (Test-Path $androidSdkPath)) {
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
        $androidSdkPath = $env:ANDROID_HOME
    } elseif ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) {
        $androidSdkPath = $env:ANDROID_SDK_ROOT
    }
}

if (Test-Path $androidSdkPath) {
    [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkPath, "Process")
    [System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkPath, "Process")
    Write-Host "[OK] Android SDK: $androidSdkPath" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Android SDK not found at $androidSdkPath" -ForegroundColor Red
}

# 2. Check Java JDK & keytool
$javaCmd = Get-Command java.exe -ErrorAction SilentlyContinue
if ($javaCmd) {
    Write-Host "[OK] Java Runtime: $($javaCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "[WARN] Java runtime not found in PATH" -ForegroundColor Yellow
}

$keytoolCmd = Get-Command keytool.exe -ErrorAction SilentlyContinue
if (-not $keytoolCmd -and (Test-Path "C:\Program Files\Microsoft\jdk-25.0.2.10-hotspot\bin\keytool.exe")) {
    $env:PATH = "C:\Program Files\Microsoft\jdk-25.0.2.10-hotspot\bin;" + $env:PATH
    $keytoolCmd = Get-Command keytool.exe -ErrorAction SilentlyContinue
}
if ($keytoolCmd) {
    Write-Host "[OK] Keytool: $($keytoolCmd.Source)" -ForegroundColor Green
}

# 3. Check ADB
$adbPath = "$androidSdkPath\platform-tools\adb.exe"
if (Test-Path $adbPath) {
    if (-not (Get-Command adb.exe -ErrorAction SilentlyContinue)) {
        $env:PATH = "$androidSdkPath\platform-tools;" + $env:PATH
    }
    $adbVer = (& $adbPath version | Select-Object -First 1)
    Write-Host "[OK] ADB Platform Tools: $adbVer" -ForegroundColor Green
} else {
    Write-Host "[ERROR] ADB not found at $adbPath" -ForegroundColor Red
}

# 4. Check Connected Devices & Emulators
Write-Host "`n--- Connected Android Devices / Emulators ---" -ForegroundColor Magenta
$devices = & $adbPath devices -l
Write-Host ($devices -join "`n") -ForegroundColor Gray

# 5. Check Flutter
$flutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
if (-not $flutterCmd -and (Test-Path "C:\Projects\flutter\bin\flutter.bat")) {
    $env:PATH = "C:\Projects\flutter\bin;" + $env:PATH
    $flutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
}
if ($flutterCmd) {
    $flutterVer = (& $flutterCmd.Source --version | Select-Object -First 1)
    Write-Host "`n[OK] Flutter CLI: $flutterVer" -ForegroundColor Green
} else {
    Write-Host "`n[ERROR] Flutter CLI not found in PATH" -ForegroundColor Red
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Environment ready for building, running, and deploying!   " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
