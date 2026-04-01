---
description: Debug Android device (USB) – capture logs and apply fixes for ShapePro
---
1. **Prepare environment**
   - Verify Flutter and Android SDK installation.
   - Run `flutter doctor` to ensure all components are OK.
   - Ensure `frontend/android/local.properties` contains the correct `sdk.dir` path.
2. **Connect device**
   - Enable *Developer options* and *USB debugging* on the phone.
   - Connect the device via USB.
   - Run `adb devices` to confirm the device is listed.
3. **Clean previous builds**
   // turbo
   Run `flutter clean` to remove old artifacts.
4. **Build release bundle**
   // turbo
   Run `flutter build appbundle --release` (generates `app-release.aab`).
5. **Install on device**
   // turbo
   Run `flutter install` (or `adb install <path-to-apk>` if you prefer an APK).
6. **Capture runtime logs**
   // turbo
   Run `adb logcat -s flutter,androidruntime > logs.txt` while launching the app.
7. **Analyze logs**
   - Open `logs.txt` and look for exceptions such as:
     * Missing 64‑bit native libraries
     * `android:exported` attribute errors (API 31+)
     * Permission denials
     * Knox‑specific API level mismatches (e.g., expecting API 39).
   - Identify which source files need changes (e.g., `android/app/build.gradle`, `AndroidManifest.xml`, Dart code).
8. **Apply fixes**
   - Edit the necessary files based on log findings.
   - Re‑run steps 4‑6 to verify the app starts without crashes.
9. **Final verification**
   - Run `flutter build appbundle --release` again.
   - Ensure the generated AAB is ≤ 150 MB and includes both `armeabi‑v7a` and `arm64‑v8a` ABIs.
   - Optionally, upload the AAB to Google Play Console for a dry‑run validation.
