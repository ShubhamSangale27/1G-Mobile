# One-time environment setup for building 1Guntha Mobile on Windows.
# Run in PowerShell before flutter build / flutter run:
#   . .\scripts\setup_env.ps1

$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
$jdk = "$env:LOCALAPPDATA\jdk-17"

$env:ANDROID_HOME = $sdkRoot
if (Test-Path "$jdk\bin\java.exe") {
    $env:JAVA_HOME = $jdk
    $env:Path = "$jdk\bin;$env:Path"
}
$env:Path = "$sdkRoot\platform-tools;$sdkRoot\cmdline-tools\latest\bin;$env:Path"

Write-Host "ANDROID_HOME=$env:ANDROID_HOME"
Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "Ready. Use: C:\Users\admin\Documents\flutter\bin\flutter.bat devices"
