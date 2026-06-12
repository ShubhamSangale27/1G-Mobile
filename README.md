# 1Guntha Mobile (Flutter MVP)

Native Android + iOS client for the 1Guntha real estate platform. Consumes the **same Heroku API** as `1G-Frontend` — no backend changes.

## API

```
https://og-backend-ec80a37e82c0.herokuapp.com/api
```

## MVP Scope

| Included | Excluded |
|----------|----------|
| Auth (login, signup, OTP, forgot password) | Admin panel |
| Persistent login (until explicit logout) | Blog / Blog Studio |
| Home, search, property detail | Premium payments |
| Favorites (watchlist) | Admin / Blogger login & panels |
| Agent site visits (list, detail, OTP complete, comments) | |
| Blog reading (published articles, read-only) | Blog editing / Blog Studio |
| List / edit / delete properties (URL-only media) | |
| Site visit book / reschedule / OTP | |
| Profile + password change | |
| Dashboard + alerts | |

## Persistent Session

- Tokens and user profile are stored in **`flutter_secure_storage`** (encrypted).
- On app launch, `AuthController` restores the session if both `accessToken` and `user` exist.
- User **stays logged in** after closing and reopening the app.
- Session is cleared **only** on explicit **Logout** (Profile screen) or refresh-token failure.
- Access token refresh on 401 matches the Angular `auth-refresh` interceptor.

## Prerequisites

- Flutter SDK **3.16+** at `C:\Users\admin\Documents\flutter\bin`
- Android SDK (via Android Studio or command-line tools) for device builds
- Physical Android phone with USB debugging (no emulator required)

## Setup

```powershell
cd C:\Users\admin\Documents\1G\1G-Mobile
C:\Users\admin\Documents\flutter\bin\flutter.bat pub get
C:\Users\admin\Documents\flutter\bin\flutter.bat analyze
```

## Run on Physical Android Device

See **[ANDROID_DEVICE_SETUP.md](ANDROID_DEVICE_SETUP.md)** for full step-by-step instructions (SDK install, USB debugging, build APK, install on phone).

Quick run (after SDK + phone connected):

```powershell
C:\Users\admin\Documents\flutter\bin\flutter.bat devices
C:\Users\admin\Documents\flutter\bin\flutter.bat run -d <device-id>
```

## Tests

```powershell
# Unit + widget tests
C:\Users\admin\Documents\flutter\bin\flutter.bat test

# Live API E2E (Heroku backend)
powershell -ExecutionPolicy Bypass -File scripts/e2e_api_test.ps1
```

## Who Can Use the Mobile App

| Role | Mobile login |
|------|----------------|
| `USER` | Yes — full buyer/seller features |
| `AGENT` | Yes — site visits tab + browse properties |
| `ADMIN` | **Blocked** — use web app only |
| `BLOG` | **Blocked** — use web app only |

## Test Accounts (seed data on backend)

| Role | Email | Password |
|------|-------|----------|
| User | user@realestate.com | user123 |
| Agent | agent@realestate.com | agent123 |
| Admin | admin@realestate.com | admin123 (web only) |

## Project Structure

```
lib/
├── config/          # API URL, GoRouter
├── core/            # Dio, secure storage, theme, utils
├── features/        # auth, home, search, property, profile, ...
├── presentation/    # Main shell (bottom nav)
└── shared/          # PropertyCard, skeleton loaders
```

## Documentation

- **[`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md)** — full mobile app context (start here)
- [`BUILD_COMMANDS.md`](BUILD_COMMANDS.md) — debug/signed APK commands
- [`ANDROID_DEVICE_SETUP.md`](ANDROID_DEVICE_SETUP.md) — physical device setup
- [`../01_Project_Analysis.md`](../01_Project_Analysis.md)
- [`../02_Flutter_Migration_Plan.md`](../02_Flutter_Migration_Plan.md)
- [`../03_Flutter_Architecture.md`](../03_Flutter_Architecture.md)

## Build Release

```bash
flutter build apk --release
flutter build ios --release
```
