# Build & Install Commands (1Guntha Mobile)

Run these in PowerShell from the project folder.

## Setup environment (each new terminal)

```powershell
Set-Location C:\Users\admin\Documents\1G\1G-Mobile
. .\scripts\setup_env.ps1
```

## Debug APK — build

```powershell
C:\Users\admin\Documents\flutter\bin\flutter.bat pub get
C:\Users\admin\Documents\flutter\bin\flutter.bat build apk --debug
```

Output: `build\app\outputs\flutter-apk\app-debug.apk`

## Debug APK — install on connected phone

```powershell
C:\Users\admin\AppData\Local\Android\Sdk\platform-tools\adb.exe devices
C:\Users\admin\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Run directly on phone (hot reload)

```powershell
C:\Users\admin\Documents\flutter\bin\flutter.bat devices
C:\Users\admin\Documents\flutter\bin\flutter.bat run -d <device-id>
```

## Signed release APK

Release signing is **already configured** on this machine:
- Keystore: `android/app/one-guntha-release.jks`
- Config: `android/key.properties`
- Credentials backup: `android/KEYSTORE_CREDENTIALS.txt` (gitignored — keep safe)

### Build signed release APK

```powershell
. .\scripts\setup_env.ps1
C:\Users\admin\Documents\flutter\bin\flutter.bat build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk` (~58 MB)

### Install release APK

```powershell
C:\Users\admin\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk
```

## Mandatory post-change verification

**Run after every code change** (also enforced via `.cursor/rules/post-change-build-and-test.mdc`):

```powershell
. .\scripts\setup_env.ps1
C:\Users\admin\Documents\flutter\bin\flutter.bat test
powershell -ExecutionPolicy Bypass -File scripts\e2e_api_test.ps1
C:\Users\admin\Documents\flutter\bin\flutter.bat build apk --debug
C:\Users\admin\Documents\flutter\bin\flutter.bat build apk --release
```

## Tests only (quick check)

```powershell
C:\Users\admin\Documents\flutter\bin\flutter.bat test
powershell -ExecutionPolicy Bypass -File scripts\e2e_api_test.ps1
C:\Users\admin\Documents\flutter\bin\flutter.bat analyze
```
