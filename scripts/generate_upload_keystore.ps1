# Generate a NEW upload keystore + PEM for Google Play upload key reset.
# Run once after losing the old keystore. Requires JDK keytool.

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot 'android'
$appDir = Join-Path $androidDir 'app'
$jksPath = Join-Path $appDir 'one-guntha-release.jks'
$pemPath = Join-Path $androidDir 'upload-certificate.pem'
$credsPath = Join-Path $androidDir 'KEYSTORE_CREDENTIALS.txt'
$keyPropsPath = Join-Path $androidDir 'key.properties'
$keytool = 'D:\DevSoftwares\jdk17\bin\keytool.exe'

if (-not (Test-Path $keytool)) {
    Write-Error "keytool not found at $keytool - install JDK 17 or edit this script."
}

if (Test-Path $jksPath) {
    Write-Error "Keystore already exists: $jksPath`nDelete it first only if you intend to regenerate."
}

# Strong random passwords (save in KEYSTORE_CREDENTIALS.txt)
function New-RandomPassword {
    param([int]$Length = 24)
    -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $Length | ForEach-Object { [char]$_ })
}

$storePass = New-RandomPassword
$keyPass = New-RandomPassword
$alias = 'one-guntha'
$dname = 'CN=1Guntha, OU=Mobile, O=1Guntha, L=Pune, ST=Maharashtra, C=IN'

New-Item -ItemType Directory -Force -Path $appDir | Out-Null

Write-Host "Creating upload keystore..."
& $keytool -genkeypair -v `
    -keystore $jksPath `
    -alias $alias `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $storePass -keypass $keyPass `
    -dname $dname

Write-Host "Exporting upload certificate (PEM) for Play Console..."
& $keytool -export -rfc `
    -alias $alias `
    -file $pemPath `
    -keystore $jksPath `
    -storepass $storePass

$sha1 = (& $keytool -list -v -keystore $jksPath -storepass $storePass -alias $alias 2>&1 | Select-String 'SHA1:' | Select-Object -First 1) -replace '.*SHA1:\s*', ''

@"
1Guntha Android upload keystore - GENERATED $(Get-Date -Format 'yyyy-MM-dd HH:mm')
KEEP OFFLINE. Do not commit to git.

Keystore file: android/app/one-guntha-release.jks
Upload cert:   android/upload-certificate.pem  (submit to Play Console for upload key reset)

keyAlias=one-guntha
storePassword=$storePass
keyPassword=$keyPass

SHA1 fingerprint: $sha1

Play Console OLD expected upload SHA1 (lost):
  C1:B0:27:47:A4:C7:1D:E3:99:77:3E:E6:BC:A6:33:5F:7C:67:86:0B

After Google approves upload key reset, sign releases with THIS keystore only.
"@ | Set-Content -Path $credsPath -Encoding UTF8

@"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=$alias
storeFile=app/one-guntha-release.jks
"@ | Set-Content -Path $keyPropsPath -Encoding UTF8

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Keystore:     $jksPath"
Write-Host "  PEM (upload): $pemPath"
Write-Host "  Credentials:  $credsPath"
Write-Host "  key.properties created for local release builds after Google approval."
Write-Host ""
Write-Host "Next: Play Console -> App integrity -> Request upload key reset -> upload upload-certificate.pem"
Write-Host "See docs/PLAY_UPLOAD_KEY_RESET.md"
