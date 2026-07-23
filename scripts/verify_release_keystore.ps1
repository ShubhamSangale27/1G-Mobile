# Verify release keystore SHA1. By default checks Play Console upload key.
# After upload key reset, run with -SkipPlayMatch to only print fingerprint.
param([switch]$SkipPlayMatch)

$ErrorActionPreference = 'Stop'

$expectedSha1 = 'C1:B0:27:47:A4:C7:1D:E3:99:77:3E:E6:BC:A6:33:5F:7C:67:86:0B'
$projectRoot = Split-Path -Parent $PSScriptRoot
$keyProps = Join-Path $projectRoot 'android\key.properties'
$jdkKeytool = 'D:\DevSoftwares\jdk17\bin\keytool.exe'

if (-not (Test-Path $keyProps)) {
    Write-Error "Missing android/key.properties. Copy android/key.properties.example and fill in credentials."
}

$props = @{}
Get-Content $keyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $props[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$storeFile = Join-Path $projectRoot "android\$($props['storeFile'])"
if (-not (Test-Path $storeFile)) {
    Write-Error "Keystore not found: $storeFile"
}

$alias = $props['keyAlias']
$storePass = $props['storePassword']

Write-Host "Keystore: $storeFile"
Write-Host "Alias:    $alias"
Write-Host ""

$output = & $jdkKeytool -list -v -keystore $storeFile -storepass $storePass -alias $alias 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "keytool failed. Check storePassword, keyPassword, and keyAlias in key.properties."
}

$sha1Line = $output | Select-String 'SHA1:' | Select-Object -First 1
if (-not $sha1Line) {
    Write-Error 'Could not read SHA1 from keystore.'
}

$actualSha1 = ($sha1Line -replace '.*SHA1:\s*', '').Trim()
Write-Host "Expected SHA1 (old Play upload key): $expectedSha1"
Write-Host "Actual SHA1:                       $actualSha1"
Write-Host ""

if ($SkipPlayMatch) {
    Write-Host 'Fingerprint recorded. Use this keystore after Google approves upload key reset.' -ForegroundColor Yellow
    exit 0
}

if ($actualSha1 -eq $expectedSha1) {
    Write-Host 'OK — keystore matches Play Console upload key. Safe to build release AAB.' -ForegroundColor Green
    exit 0
}

Write-Host 'MISMATCH — do not upload. Use the original one-guntha-release.jks from the first Play Store upload.' -ForegroundColor Red
exit 1
