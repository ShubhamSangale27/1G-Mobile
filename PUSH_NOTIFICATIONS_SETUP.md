# Push Notifications Setup (FCM)

Admin-triggered push notifications use **Firebase Cloud Messaging (FCM)** — free for standard usage.

## 1. Create Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/) → **Add project** (e.g. `one-guntha`).
2. Enable **Google Analytics** (optional).

## 2. Register Android app

1. Firebase → **Project settings** → **Your apps** → Add **Android**.
2. Package name: `com.oneguntha.one_guntha` (must match [`android/app/build.gradle.kts`](android/app/build.gradle.kts)).
3. Download **`google-services.json`** → replace [`android/app/google-services.json`](android/app/google-services.json).
4. Run FlutterFire (recommended):
   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure --project=YOUR_PROJECT_ID
   ```
   This regenerates [`lib/firebase_options.dart`](lib/firebase_options.dart).

## 3. Register iOS app (optional, for iPhone push)

1. Add **iOS** app in Firebase with your Xcode bundle ID.
2. Download **`GoogleService-Info.plist`** → `ios/Runner/`.
3. In Apple Developer → create **APNs Auth Key** → upload to Firebase → Cloud Messaging.
4. Enable **Push Notifications** capability in Xcode.

## 4. Backend service account (required to send push)

1. Firebase → **Project settings** → **Service accounts** → **Generate new private key**.
2. Save JSON outside the repo (e.g. `D:\secrets\one-guntha-firebase-adminsdk.json`).

### Local development (file path)

```powershell
$env:FIREBASE_ENABLED="true"
$env:FIREBASE_CREDENTIALS_PATH="D:\secrets\one-guntha-firebase-adminsdk.json"
```

### Heroku (env JSON — recommended)

Heroku has no filesystem for secrets. Set the JSON contents as env vars instead:

**Option A — Base64 (recommended; avoids newline issues in `private_key`):**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("D:\secrets\one-guntha-firebase-adminsdk.json"))
```

```powershell
heroku config:set FIREBASE_ENABLED=true -a YOUR_HEROKU_APP
heroku config:set FIREBASE_CREDENTIALS_BASE64="PASTE_BASE64_HERE" -a YOUR_HEROKU_APP
```

**Option B — Raw JSON string:**

```powershell
heroku config:set FIREBASE_ENABLED=true -a YOUR_HEROKU_APP
heroku config:set FIREBASE_CREDENTIALS_JSON='{"type":"service_account",...}' -a YOUR_HEROKU_APP
```

Credential source priority: `FIREBASE_CREDENTIALS_JSON` → `FIREBASE_CREDENTIALS_BASE64` → `FIREBASE_CREDENTIALS_PATH`.

3. Restart the backend (or redeploy on Heroku).
4. Confirm startup log: `Firebase Admin SDK initialized for push notifications`.

## 5. Test end-to-end

1. Build and install mobile app on a physical device (emulators may not receive FCM reliably).
2. Log in as **USER** or **AGENT** → grant notification permission.
3. Log in to **web admin** → **Push Notifications (Mobile)** section.
4. Send a test with title + message; optional image URL (HTTPS) and link:
   - In-app: `/property/123`, `/blog/slug`, `/search?city=Pune`
   - Browser: set link behavior to **Open in browser** or use external URL
5. Tap notification → app opens route or browser.

## 6. Admin panel location

Web app → **Admin** → scroll to **Push Notifications (Mobile)**.

API (ADMIN JWT):

- `POST /api/admin/push-notifications/send`
- `GET /api/admin/push-notifications`

Mobile registers token:

- `POST /api/devices/fcm-token` (after login)

## 7. Costs

| Item | Cost |
|------|------|
| FCM message delivery | **Free** |
| Firebase Spark plan | **Free** (sufficient for FCM) |
| Apple Developer (iOS push) | $99/year |
| Google Play (Android publish) | $25 one-time |

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Campaign saved but 0 sent | Set `FIREBASE_ENABLED=true` and one of `FIREBASE_CREDENTIALS_JSON`, `FIREBASE_CREDENTIALS_BASE64` (Heroku), or `FIREBASE_CREDENTIALS_PATH` (local) |
| No token in DB | User must log in on mobile and accept notification permission |
| Image not shown | Use public HTTPS image URL; Android shows rich image when app is in background |
| Link does not open in app | Use `/property/id` or set link behavior to **Open in app** |

Replace placeholder files before production:

- [`android/app/google-services.json`](android/app/google-services.json)
- [`lib/firebase_options.dart`](lib/firebase_options.dart)
