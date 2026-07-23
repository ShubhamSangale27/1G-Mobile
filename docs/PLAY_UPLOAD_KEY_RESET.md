# Request a new Play Store upload key (old machine / keystore lost)
#
# You CANNOT upload until Google approves the new upload certificate.
# Play expects SHA1: C1:B0:27:47:A4:C7:1D:E3:99:77:3E:E6:BC:A6:33:5F:7C:67:86:0B
# That key is gone — Google must register a replacement.

## Step 1 — Generate a new upload keystore (this machine)

```powershell
cd D:\DevSoftwares\1Guntha\1G-Mobile
powershell -ExecutionPolicy Bypass -File scripts\generate_upload_keystore.ps1
```

This creates:
- `android/app/one-guntha-release.jks`
- `android/upload-certificate.pem` (send this to Google)
- `android/KEYSTORE_CREDENTIALS.txt` (passwords — back up offline, never commit)

## Step 2 — Request upload key reset in Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Select **1Guntha** app
3. Go to **Setup → App integrity** (or **Release → Setup → App signing**)
4. Under **Upload key**, choose **Request upload key reset**
5. Select reason: **I lost my upload key**
6. Upload `android/upload-certificate.pem` from Step 1
7. Submit and wait for Google (usually **1–2 business days**, sometimes faster)

Google help: https://support.google.com/googleplay/android-developer/answer/9842756

## Step 3 — After Google approves

1. Create `android/key.properties` from the example (or the script does it):

```properties
storePassword=<from KEYSTORE_CREDENTIALS.txt>
keyPassword=<from KEYSTORE_CREDENTIALS.txt>
keyAlias=one-guntha
storeFile=app/one-guntha-release.jks
```

2. Verify fingerprint (will NOT match the old C1:B0:27… — that is expected; Google switched upload key):

```powershell
powershell -File scripts\verify_release_keystore.ps1 -SkipPlayMatch
```

3. Build signed AAB:

```powershell
D:\DevSoftwares\flutter\bin\flutter.bat clean
D:\DevSoftwares\flutter\bin\flutter.bat build appbundle --release
```

4. Upload `build/app/outputs/bundle/release/app-release.aab`

## Important

- **Do not** publish a new app with a different package name unless Google denies the reset.
- **Back up** `one-guntha-release.jks` and `KEYSTORE_CREDENTIALS.txt` to cloud/USB/password manager today.
- **Do not commit** `.jks`, `key.properties`, or credentials to git (already gitignored).

## If upload key reset is denied

Contact [Play Console support](https://support.google.com/googleplay/android-developer/contact/other) with proof of account ownership. Last resort: new listing with a new `applicationId` (users must reinstall; you lose reviews/history).
