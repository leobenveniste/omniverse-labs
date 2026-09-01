<#
.SYNOPSIS
    Central Command Hub for Android / Flutter App Creation, Building, Testing, and Deployment.
.DESCRIPTION
    Supports one-command app scaffolding, local device testing, automated signing,
    production App Bundle (AAB) & APK compilation, and Google Play Console publishing.
.EXAMPLE
    .\scripts\app-manager.ps1 create -Name "crypto_tracker" -Org "com.mycompany"
    .\scripts\app-manager.ps1 run -App "crypto_tracker"
    .\scripts\app-manager.ps1 build -App "crypto_tracker" -Target aab -Config release
    .\scripts\app-manager.ps1 deploy-playstore -App "crypto_tracker" -Track internal
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("doctor", "create", "list", "run", "build", "test", "install", "deploy-playstore", "status")]
    [string]$Command = "list",

    [Parameter(Position=1, Mandatory=$false)]
    [string]$Name,

    [Parameter(Mandatory=$false)]
    [string]$App,

    [Parameter(Mandatory=$false)]
    [string]$Org = "com.omniverselabs",

    [Parameter(Mandatory=$false)]
    [ValidateSet("apk", "aab")]
    [string]$Target = "aab",

    [Parameter(Mandatory=$false)]
    [ValidateSet("release", "debug", "profile")]
    [string]$Config = "release",

    [Parameter(Mandatory=$false)]
    [ValidateSet("internal", "alpha", "beta", "production")]
    [string]$Track = "internal",

    [Parameter(Mandatory=$false)]
    [string]$Device = "",

    [Parameter(Mandatory=$false)]
    [switch]$Bump = $false
)

$ErrorActionPreference = "Stop"
$workspaceRoot = (Get-Item $PSScriptRoot).Parent.FullName
$appsDir = Join-Path $workspaceRoot "apps"
$flutterBin = "C:\Projects\flutter\bin\flutter.bat"
$adbBin = "C:\Users\leobe\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# If -Name was given instead of -App or vice-versa, normalize
if ([string]::IsNullOrWhiteSpace($App) -and -not [string]::IsNullOrWhiteSpace($Name)) {
    $App = $Name
}

# Helper: Find App Directory
function Get-AppPath {
    param([string]$AppName)
    if ([string]::IsNullOrWhiteSpace($AppName)) {
        Write-Error "Please specify an app name using -App <app_name>"
        return $null
    }
    $candidate = Join-Path $appsDir $AppName
    if (Test-Path $candidate) { return $candidate }
    $candidateRoot = Join-Path $workspaceRoot $AppName
    if (Test-Path $candidateRoot) { return $candidateRoot }
    Write-Error "App '$AppName' not found in '$appsDir'."
    return $null
}

# Helper: Configure Android Signing in build.gradle / build.gradle.kts
function Set-AndroidSigning {
    param([string]$TargetAppDir)
    $appGradleFile = Join-Path $TargetAppDir "android\app\build.gradle"
    $appGradleKtsFile = Join-Path $TargetAppDir "android\app\build.gradle.kts"

    if (Test-Path $appGradleKtsFile) {
        $content = Get-Content $appGradleKtsFile -Raw
        if ($content -notmatch "keystoreProperties") {
            Write-Host "Configuring Kotlin DSL release signing in build.gradle.kts..." -ForegroundColor Cyan
            $imports = @"
import java.util.Properties
import java.io.FileInputStream

"@
            $signingSetup = @"
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let {
                val f = file(it)
                if (f.exists()) f else rootProject.file(it)
            }
            storePassword = keystoreProperties.getProperty("storePassword") 
                ?: keystoreProperties.getProperty("password")
        }
    }
"@
            $content = $imports + $content
            $content = $content -replace "android\s*\{", $signingSetup
            $content = $content -replace 'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")'
            Set-Content -Path $appGradleKtsFile -Value $content -Encoding UTF8
        }
    } elseif (Test-Path $appGradleFile) {
        $content = Get-Content $appGradleFile -Raw
        if ($content -notmatch "keyProperties") {
            Write-Host "Configuring Groovy release signing in build.gradle..." -ForegroundColor Cyan
            $signingSetup = @"
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
                storeFile = file(keystoreProperties['storeFile'])
                storePassword = keystoreProperties['password']
            }
        }
    }
"@
            $content = $content -replace "android\s*\{", $signingSetup
            $content = $content -replace 'signingConfig\s*=\s*signingConfigs\.debug', 'signingConfig = signingConfigs.release'
            Set-Content -Path $appGradleFile -Value $content -Encoding UTF8
        }
    }
}

switch ($Command) {
    "doctor" {
        & "$PSScriptRoot\setup-env.ps1"
    }

    "list" {
        Write-Host "`n=== Omniverse Labs Workspace ===" -ForegroundColor Cyan
        if (-not (Test-Path $appsDir)) {
            Write-Host "No 'apps' directory found yet." -ForegroundColor Gray
            return
        }
        $appFolders = Get-ChildItem -Path $appsDir -Directory
        if ($appFolders.Count -eq 0) {
            Write-Host "No applications created yet. Run: .\scripts\app-manager.ps1 create -Name <app_name>" -ForegroundColor Yellow
            return
        }

        foreach ($folder in $appFolders) {
            $pubspec = Join-Path $folder.FullName "pubspec.yaml"
            $version = "N/A"
            if (Test-Path $pubspec) {
                $verLine = (Get-Content $pubspec | Where-Object { $_ -match "^version:\s*(.+)$" })
                if ($verLine -match "^version:\s*(.+)$") {
                    $version = $Matches[1].Trim()
                }
            }
            $hasKeyProps = Test-Path (Join-Path $folder.FullName "android\key.properties")
            $hasAab = Test-Path (Join-Path $folder.FullName "build\app\outputs\bundle\release\app-release.aab")
            $hasApk = Test-Path (Join-Path $folder.FullName "build\app\outputs\flutter-apk\app-release.apk")

            Write-Host "• $($folder.Name) (Version: $version)" -ForegroundColor Green
            Write-Host "  - Release Signing Key : $(if ($hasKeyProps) { '[OK] Configured' } else { '[!] Missing (Run generate-keystore.ps1)' })" -ForegroundColor $(if ($hasKeyProps) {'Green'} else {'Yellow'})
            Write-Host "  - Release Bundle (.aab): $(if ($hasAab) { '[OK] Ready for Google Play' } else { 'Not built' })" -ForegroundColor $(if ($hasAab) {'Green'} else {'Gray'})
            Write-Host "  - Release APK (.apk)   : $(if ($hasApk) { '[OK] Built' } else { 'Not built' })" -ForegroundColor $(if ($hasApk) {'Green'} else {'Gray'})
            Write-Host ""
        }
    }

    "create" {
        if ([string]::IsNullOrWhiteSpace($App)) {
            Write-Error "Please specify the app name: .\scripts\app-manager.ps1 create -Name <app_name> [-Org <org.domain>]"
            return
        }

        if (-not (Test-Path $appsDir)) {
            New-Item -ItemType Directory -Path $appsDir -Force | Out-Null
        }

        $targetAppPath = Join-Path $appsDir $App
        if (Test-Path $targetAppPath) {
            Write-Error "App '$App' already exists at '$targetAppPath'."
            return
        }

        Write-Host "Scaffolding new Flutter application '$App' (Org: $Org)..." -ForegroundColor Cyan
        & $flutterBin create --org $Org --platforms android,ios,web $targetAppPath

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create Flutter application."
            return
        }

        Write-Host "`nGenerating production signing keystore for '$App'..." -ForegroundColor Cyan
        & "$PSScriptRoot\generate-keystore.ps1" -AppName $App

        Set-AndroidSigning -TargetAppDir $targetAppPath

        Write-Host "`n============================================================" -ForegroundColor Green
        Write-Host " [SUCCESS] Application '$App' created and configured!       " -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "To test locally : .\scripts\app-manager.ps1 run -App $App" -ForegroundColor Yellow
        Write-Host "To build bundle : .\scripts\app-manager.ps1 build -App $App -Target aab" -ForegroundColor Yellow
    }

    "run" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        Push-Location $targetAppPath
        try {
            $deviceArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($Device)) {
                $deviceArgs += @("-d", $Device)
            }
            Write-Host "Running '$App' on local device/emulator..." -ForegroundColor Cyan
            & $flutterBin run @deviceArgs
        } finally {
            Pop-Location
        }
    }

    "build" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        $pubspecPath = Join-Path $targetAppPath "pubspec.yaml"
        if (Test-Path $pubspecPath) {
            $pubContent = Get-Content $pubspecPath -Raw
            if ($pubContent -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
                $verName = $Matches[1]
                $buildNum = [int]$Matches[2]
                if ($Bump) {
                    $buildNum++
                    $newVerStr = "version: $verName+$buildNum"
                    $pubContent = $pubContent -replace "version:\s*(\d+\.\d+\.\d+)\+(\d+)", $newVerStr
                    Set-Content -Path $pubspecPath -Value $pubContent -Encoding UTF8
                    Write-Host "Auto-incremented version to: $verName+$buildNum (Version code: $buildNum)" -ForegroundColor Green
                } else {
                    Write-Host "Building version: $verName+$buildNum (Version code: $buildNum)" -ForegroundColor Cyan
                }
            }
        }

        Push-Location $targetAppPath
        try {
            Write-Host "Building '$App' [Target: $Target, Config: $Config]..." -ForegroundColor Cyan
            if ($Target -eq "aab") {
                & $flutterBin build appbundle --$Config
                $outBundle = Join-Path $targetAppPath "build\app\outputs\bundle\$Config\app-$Config.aab"
                if (Test-Path $outBundle) {
                    $sizeMb = [math]::Round((Get-Item $outBundle).Length / 1MB, 2)
                    Write-Host "`n[SUCCESS] Android App Bundle (.aab) created ($sizeMb MB):" -ForegroundColor Green
                    Write-Host "$outBundle" -ForegroundColor Yellow
                }
            } else {
                & $flutterBin build apk --$Config
                $outApk = Join-Path $targetAppPath "build\app\outputs\flutter-apk\app-$Config.apk"
                if (Test-Path $outApk) {
                    $sizeMb = [math]::Round((Get-Item $outApk).Length / 1MB, 2)
                    Write-Host "`n[SUCCESS] Android APK (.apk) created ($sizeMb MB):" -ForegroundColor Green
                    Write-Host "$outApk" -ForegroundColor Yellow
                }
            }
        } finally {
            Pop-Location
        }
    }

    "test" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        Push-Location $targetAppPath
        try {
            Write-Host "Running automated tests for '$App'..." -ForegroundColor Cyan
            & $flutterBin test
        } finally {
            Pop-Location
        }
    }

    "install" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        $apkPath = Join-Path $targetAppPath "build\app\outputs\flutter-apk\app-$Config.apk"
        if (-not (Test-Path $apkPath)) {
            Write-Host "APK not found. Building first..." -ForegroundColor Cyan
            & $flutterBin build apk --$Config
        }

        Write-Host "Installing $apkPath to connected device..." -ForegroundColor Cyan
        & $adbBin install -r $apkPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] App installed to device!" -ForegroundColor Green
        }
    }

    "deploy-playstore" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        $aabPath = Join-Path $targetAppPath "build\app\outputs\bundle\release\app-release.aab"
        if (-not (Test-Path $aabPath)) {
            Write-Host "App Bundle not found. Compiling release AAB..." -ForegroundColor Cyan
            Push-Location $targetAppPath
            & $flutterBin build appbundle --release
            Pop-Location
        }

        $serviceAccountPath = Join-Path $workspaceRoot "service_account.json"
        if (-not (Test-Path $serviceAccountPath)) {
            $serviceAccountPath = Join-Path $targetAppPath "android\service_account.json"
        }

        if (-not (Test-Path $serviceAccountPath)) {
            Write-Host "`n[ACTION REQUIRED] Google Play Developer Service Account Key missing!" -ForegroundColor Yellow
            Write-Host "To automatically upload to Google Play Console:" -ForegroundColor Cyan
            Write-Host "1. Create a Service Account in Google Cloud Console with Google Play Developer permissions."
            Write-Host "2. Download the JSON key file and place it at: $workspaceRoot\service_account.json"
            Write-Host "3. Alternatively, you can upload the signed bundle directly to Play Console:" -ForegroundColor Cyan
            Write-Host "   -> $aabPath" -ForegroundColor Green
            return
        }

        Write-Host "Publishing '$App' to Google Play Console track '$Track'..." -ForegroundColor Cyan
        # If fastlane is present in the app, run fastlane supply
        $fastlaneDir = Join-Path $targetAppPath "android\fastlane"
        if (Test-Path $fastlaneDir) {
            Push-Location (Join-Path $targetAppPath "android")
            try {
                fastlane deploy_playstore track:$Track
            } finally {
                Pop-Location
            }
        } else {
            Write-Host "Fastlane not initialized for '$App'. Bundle is ready at: $aabPath" -ForegroundColor Green
        }
    }

    "status" {
        $targetAppPath = Get-AppPath -AppName $App
        if (-not $targetAppPath) { return }

        $checkerScript = Join-Path $PSScriptRoot "check-play-status.mjs"
        $pkgName = "com.omniverselabs.$App"
        if ($App -eq "anotador_de_juegos") { $pkgName = "com.omniverselabs.anotadordejuegos" }

        & node $checkerScript $pkgName
    }
}
