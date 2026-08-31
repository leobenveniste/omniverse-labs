<#
.SYNOPSIS
    Generates a secure release keystore and configures key.properties for an Android Flutter app.
.PARAMETER AppName
    The directory name of the Flutter app under 'apps/'.
.PARAMETER KeyAlias
    The key alias (defaults to '<appname>_key').
.PARAMETER Password
    Optional password for the keystore and key. If not provided, a secure random password is generated.
.PARAMETER DName
    Certificate distinguished name (defaults to "CN=AppDeveloper, OU=Mobile, O=Apps, C=US").
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$AppName,

    [Parameter(Mandatory=$false)]
    [string]$KeyAlias = "",

    [Parameter(Mandatory=$false)]
    [string]$Password = "",

    [Parameter(Mandatory=$false)]
    [string]$DName = "CN=AppDeveloper, OU=Mobile, O=Apps, C=US"
)

$ErrorActionPreference = "Stop"

$workspaceRoot = (Get-Item $PSScriptRoot).Parent.FullName
$appDir = Join-Path $workspaceRoot "apps\$AppName"

if (-not (Test-Path $appDir)) {
    # Check if app is directly in workspace root
    if (Test-Path (Join-Path $workspaceRoot $AppName)) {
        $appDir = Join-Path $workspaceRoot $AppName
    } else {
        Write-Error "App directory not found for '$AppName'. Searched at '$appDir'."
        return
    }
}

$androidDir = Join-Path $appDir "android"
if (-not (Test-Path $androidDir)) {
    Write-Error "Android folder not found in '$appDir'. Is this a valid Flutter application?"
    return
}

# Locate keytool
$keytool = Get-Command keytool.exe -ErrorAction SilentlyContinue
if (-not $keytool) {
    $jdkKeytool = "C:\Program Files\Microsoft\jdk-25.0.2.10-hotspot\bin\keytool.exe"
    if (Test-Path $jdkKeytool) {
        $keytool = $jdkKeytool
    } else {
        Write-Error "keytool.exe not found in PATH or standard JDK directories."
        return
    }
} else {
    $keytool = $keytool.Source
}

if ([string]::IsNullOrWhiteSpace($KeyAlias)) {
    $KeyAlias = "$($AppName.Replace('-', '_'))_key"
}

# Generate secure password if not provided
if ([string]::IsNullOrWhiteSpace($Password)) {
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*"
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 16
    $rng.GetBytes($bytes)
    $Password = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

# Ensure keystores root directory
$keystoresDir = Join-Path $workspaceRoot "keystores"
if (-not (Test-Path $keystoresDir)) {
    New-Item -ItemType Directory -Path $keystoresDir -Force | Out-Null
}

$keystoreFile = Join-Path $keystoresDir "$AppName-release.jks"
$appKeystoreFile = Join-Path $androidDir "app\release.jks"

Write-Host "Creating release keystore for '$AppName'..." -ForegroundColor Cyan

# Generate JKS using keytool
$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", $keystoreFile,
    "-alias", $KeyAlias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-storepass", $Password,
    "-keypass", $Password,
    "-dname", $DName
)

if (Test-Path $keystoreFile) {
    Write-Warning "Keystore already exists at $keystoreFile. Backing up..."
    Copy-Item $keystoreFile "$keystoreFile.bak" -Force
    Remove-Item $keystoreFile -Force
}

& $keytool $keytoolArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate keystore."
    return
}

# Copy to app android/app folder as well
Copy-Item $keystoreFile $appKeystoreFile -Force

# Create android/key.properties
$keyPropertiesPath = Join-Path $androidDir "key.properties"
$keyPropsContent = @"
storePassword=$Password
password=$Password
keyPassword=$Password
keyAlias=$KeyAlias
storeFile=release.jks
"@

Set-Content -Path $keyPropertiesPath -Value $keyPropsContent -Encoding UTF8

Write-Host "`n[SUCCESS] Release Keystore configured!" -ForegroundColor Green
Write-Host "Keystore Location : $keystoreFile" -ForegroundColor Yellow
Write-Host "Key Properties    : $keyPropertiesPath" -ForegroundColor Yellow
Write-Host "Key Alias         : $KeyAlias" -ForegroundColor Yellow
Write-Host "Password          : $Password" -ForegroundColor Yellow
Write-Host "`nNote: Keystore passwords have been safely written to $keyPropertiesPath (gitignored)." -ForegroundColor Gray
