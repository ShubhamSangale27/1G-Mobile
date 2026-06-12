# Run 1Guntha Mobile on a Physical Android Device (Windows)

This guide covers setup from scratch on Windows when you have **no emulator** — only a USB-connected Android phone.

## What You Need

| Item | Notes |
|------|-------|
| Flutter SDK | `C:\Users\admin\Documents\flutter\bin` |
| Android SDK | Installed via Android Studio (recommended) or command-line tools |
| USB cable | Data-capable (not charge-only) |
| Android phone | Android 6.0+ with **Developer options** enabled |

---

## Part 1 — Install Android SDK (one-time)

### Option A — Android Studio (recommended)

1. Download **Android Studio**: https://developer.android.com/studio
2. Run the installer. On the setup wizard, ensure these are checked:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (optional — you are using a physical device)
3. Open Android Studio → **More Actions** → **SDK Manager** (or **Settings → Languages & Frameworks → Android SDK**).
4. On the **SDK Platforms** tab, install:
   - **Android 14.0 (API 34)** or latest stable
5. On the **SDK Tools** tab, install:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools
   - Android Emulator (optional)
6. Note the SDK path (usually):
   ```
   C:\Users\admin\AppData\Local\Android\Sdk
   ```

### Option B — Command-line tools only (no Android Studio UI)

```powershell
$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force -Path "$sdkRoot\cmdline-tools" | Out-Null

# Download latest command-line tools (check https://developer.android.com/studio#command-line-tools-only for URL updates)
$zip = "$env:TEMP\cmdline-tools.zip"
Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath "$sdkRoot\cmdline-tools\tmp" -Force
Move-Item "$sdkRoot\cmdline-tools\tmp\cmdline-tools" "$sdkRoot\cmdline-tools\latest" -Force
Remove-Item "$sdkRoot\cmdline-tools\tmp" -Recurse -Force

$env:ANDROID_HOME = $sdkRoot
$env:Path = "$sdkRoot\cmdline-tools\latest\bin;$sdkRoot\platform-tools;$env:Path"

sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
sdkmanager --licenses   # type 'y' for each prompt
```

### Point Flutter at the SDK

```powershell
$flutter = "C:\Users\admin\Documents\flutter\bin\flutter.bat"
& $flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
& $flutter doctor --android-licenses   # accept all
& $flutter doctor -v
```

You should see **Android toolchain** with a green checkmark.

### Java (required for Gradle builds)

If you do not install Android Studio, you need JDK 17+. This project setup used a portable JDK at:

```
C:\Users\admin\AppData\Local\jdk-17
```

Set `JAVA_HOME` to that folder (or your Android Studio `jbr` folder).

### Quick env script (per terminal session)

```powershell
Set-Location C:\Users\admin\Documents\1G\1G-Mobile
. .\scripts\setup_env.ps1
```

### Set environment variables (persistent)

1. Windows Search → **Edit the system environment variables**
2. **Environment Variables** → under **User variables**:
   - `ANDROID_HOME` = `C:\Users\admin\AppData\Local\Android\Sdk`
   - `JAVA_HOME` = `C:\Users\admin\AppData\Local\jdk-17` (or Android Studio JBR path)
   - Add to **Path**:
     - `%JAVA_HOME%\bin`
     - `%ANDROID_HOME%\platform-tools`
     - `%ANDROID_HOME%\cmdline-tools\latest\bin`
     - `C:\Users\admin\Documents\flutter\bin`
3. Restart PowerShell / Cursor terminal.

---

## Part 2 — Prepare Your Android Phone

1. **Enable Developer options**
   - Settings → About phone → tap **Build number** 7 times
2. **Enable USB debugging**
   - Settings → System → Developer options → **USB debugging** ON
3. **Connect via USB** to your PC
4. On the phone, when prompted, tap **Allow USB debugging** and optionally **Always allow from this computer**

### Verify connection

```powershell
adb devices
```

Expected output:
```
List of devices attached
XXXXXXXX    device
```

If you see `unauthorized`, unlock the phone and accept the debugging prompt.

If `adb` is not found, use the full path:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

---

## Part 3 — Build and Install the App

```powershell
$flutter = "C:\Users\admin\Documents\flutter\bin\flutter.bat"
Set-Location "C:\Users\admin\Documents\1G\1G-Mobile"

& $flutter pub get
& $flutter devices
```

Pick your phone's device ID from the list, then either:

### Debug build (fast iteration, hot reload)

```powershell
& $flutter run -d <your-device-id>
```

Example:
```powershell
& $flutter run -d RZ8N123ABCD
```

### Release APK (shareable / production-like)

```powershell
& $flutter build apk --release
```

APK location:
```
build\app\outputs\flutter-apk\app-release.apk
```

Install manually:
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Or copy `app-release.apk` to the phone and open it (enable **Install unknown apps** for your file manager if asked).

---

## Part 4 — Test Accounts

| Role | Email | Password | Mobile app |
|------|-------|----------|------------|
| User | user@realestate.com | user123 | Yes |
| Agent | agent@realestate.com | agent123 | Yes — **Visits** tab |
| Admin | admin@realestate.com | admin123 | **Blocked** |
| Blogger | blogger@realestate.com | blog123 | **Blocked** |

### Manual test checklist

**User flow**
- [ ] Login persists after force-closing the app
- [ ] Home carousel and featured properties load
- [ ] Search with filters works
- [ ] Property detail → add to watchlist
- [ ] Book / reschedule site visit
- [ ] Profile → logout clears session

**Agent flow**
- [ ] Login redirects to agent visits
- [ ] Bottom nav shows **Visits** instead of **Saved**
- [ ] Active / Done filters work
- [ ] Inline OTP complete on list screen
- [ ] Visit detail → property, customer, comments
- [ ] Add comment on visit detail

**Blocked roles**
- [ ] Admin login shows blocked message (not dashboard)
- [ ] Blogger login shows blocked message

---

## Part 5 — Run Automated Tests (on PC)

```powershell
$flutter = "C:\Users\admin\Documents\flutter\bin\flutter.bat"
Set-Location "C:\Users\admin\Documents\1G\1G-Mobile"

& $flutter test                          # unit + widget tests (3 tests)
powershell -ExecutionPolicy Bypass -File scripts/e2e_api_test.ps1   # live API E2E (13 checks)
& $flutter analyze
```

**Pre-built debug APK** (already built on this machine):

```
build\app\outputs\flutter-apk\app-debug.apk
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `No Android SDK found` | Install SDK (Part 1), run `flutter config --android-sdk` |
| `adb: device unauthorized` | Unlock phone, accept USB debugging prompt |
| `No devices found` | Try another USB port/cable; install OEM USB driver (Samsung/Xiaomi/etc.) |
| `INSTALL_FAILED_USER_RESTRICTED` | Enable **Install via USB** in Developer options (Xiaomi/MIUI) |
| Gradle download slow | Wait or use stable network; first build takes several minutes |
| `cleartext traffic` errors | App uses HTTPS Heroku URL — no change needed |
| Hot reload not working | Use `flutter run` debug mode, not installed release APK |

---

## API Endpoint

The app talks to the same backend as the Angular web app:

```
https://og-backend-ec80a37e82c0.herokuapp.com/api
```

No backend changes are required.
