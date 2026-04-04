# 🤖 Copilot Prompt — Flutter Firebase In-App Update (Industry Standard)

Paste this prompt into GitHub Copilot Chat, Cursor, or any AI coding assistant.

---

## PROMPT

```
You are a senior Flutter engineer. I already have Firebase initialized and working in my Flutter project (firebase_core, google-services.json / GoogleService-Info.plist are configured).

Implement a production-grade, industry-standard in-app update system using Firebase Remote Config. Follow all the requirements below exactly.

---

### DEPENDENCIES TO ADD (pubspec.yaml)
- firebase_remote_config: latest stable
- package_info_plus: latest stable
- url_launcher: latest stable
- in_app_update: latest stable   # Android native Play Core updates
- shared_preferences: latest stable  # To persist "remind me later" snooze

---

### FIREBASE REMOTE CONFIG PARAMETERS
Assume these keys exist in the Firebase Console:
- `force_update_version`  → String  (e.g. "2.0.0")  — minimum supported version
- `latest_version`        → String  (e.g. "2.3.1")  — latest published version
- `update_message`        → String  — custom changelog/release notes text
- `android_store_url`     → String  — Play Store URL
- `ios_store_url`         → String  — App Store URL
- `snooze_duration_hours` → Int     — how many hours user can snooze optional update

---

### ARCHITECTURE REQUIREMENTS

1. **UpdateService** (`lib/services/update_service.dart`)
   - Singleton using factory constructor
   - `initialize()` — sets RemoteConfig settings:
       - fetchTimeout: 10 seconds
       - minimumFetchInterval: 1 hour (production) / 0 in debug mode using kDebugMode
   - Set safe default values for all Remote Config keys
   - `checkForUpdate()` → returns `UpdateCheckResult` model
   - `openStore()` — launches platform-correct store URL using url_launcher
   - `snoozeUpdate()` — saves snooze timestamp to SharedPreferences
   - `isSnoozed()` — returns true if current time is within snooze window
   - Version comparison must support semantic versioning: MAJOR.MINOR.PATCH
   - Gracefully handle fetch failures by falling back to cached Remote Config values

2. **Models** (`lib/models/update_check_result.dart`)
   - `UpdateCheckResult` with fields:
       - `UpdateType type` (enum: none, optional, forced)
       - `String currentVersion`
       - `String latestVersion`
       - `String updateMessage`
       - `String storeUrl`
       - `bool isSnoozed`

3. **UpdateDialog widget** (`lib/widgets/update_dialog.dart`)
   - Accepts `UpdateCheckResult`
   - For `forced` updates:
       - WillPopScope / PopScope prevents back navigation
       - No "Later" button
       - Dialog is not barrierDismissible
   - For `optional` updates:
       - Show "Update Now" and "Remind Me Later" buttons
       - "Remind Me Later" calls `UpdateService().snoozeUpdate()`
       - Do not show dialog again within the snooze window
   - Show current version, latest version, and `updateMessage` text
   - Use Material 3 design (AlertDialog with rounded corners, icon, proper typography)

4. **UpdateGuard widget** (`lib/widgets/update_guard.dart`)
   - StatefulWidget that wraps the app's home screen
   - In `initState`, uses `addPostFrameCallback` to check for updates after first frame
   - If `UpdateType.forced` → show non-dismissible dialog immediately
   - If `UpdateType.optional` and not snoozed → show dismissible dialog
   - If `UpdateType.none` or snoozed → do nothing

5. **Android Native Update** (`lib/services/play_store_update_service.dart`)
   - Platform-guard with `Platform.isAndroid`
   - Use `in_app_update` package
   - If `immediateUpdateAllowed` → use `InAppUpdate.performImmediateUpdate()`
   - If only `flexibleUpdateAllowed` → use flexible update flow + complete on finish
   - Catch all exceptions silently and log with `debugPrint`

6. **main.dart wiring**
   - After `Firebase.initializeApp(...)`, call `UpdateService().initialize()`
   - On Android, also call `PlayStoreUpdateService().checkAndUpdate()`
   - Wrap home screen with `UpdateGuard`

---

### CODE QUALITY REQUIREMENTS
- All classes must have dartdoc comments
- Use `const` constructors where possible
- No `dynamic` types — use proper typed models
- Handle all async errors with try/catch
- Never call `Navigator` without checking `mounted`
- Follow effective Dart naming conventions
- Export all public classes via a barrel file: `lib/update/update.dart`

---

### DO NOT
- Do not use any third-party update packages like `upgrader`
- Do not hardcode any version strings or URLs
- Do not skip the snooze logic
- Do not show the update dialog on every app launch if the user snoozed it

---

Generate all files with full implementation. No placeholders, no TODOs. Each file should be production-ready.
```
