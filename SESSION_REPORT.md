# Mizan App Web, GitHub, and Firebase Session Report

Generated: 2026-08-30 (Asia/Kuwait)

## 1. Executive summary

This session took the existing Ahmed OS Flutter application and made it usable
as a hosted web app from a phone. The project was connected to GitHub and to the
Firebase project `mizan-app-7fa3f`. Firebase Authentication, Cloud Firestore,
security rules, account-specific local caching, offline write recovery, and
Firebase Hosting were added.

The deployed app initially failed during Firebase startup. The final root cause
was a stale Flutter-generated web plugin registrant that did not register the
Firebase web plugins. A clean regeneration then exposed a package compatibility
problem between the newest FlutterFire packages and the installed Flutter/Dart
toolchain. The dependencies were pinned to compatible releases, the self-hosted
Firebase JavaScript SDK was aligned to version `11.9.1`, the app was rebuilt,
tested, deployed, and pushed to GitHub.

Final live app:

<https://mizan-app-7fa3f.web.app>

Final GitHub repository:

<https://github.com/ahmedmoreco-lab/mizanapp>

## 2. Goals covered during the session

1. Build the Flutter application for the web.
2. Make it available through a public link instead of `localhost`.
3. Make the link usable from a phone.
4. Upload and maintain the source in the requested GitHub repository.
5. Connect the application to the requested Firebase project.
6. Clarify whether phone edits are device-local or permanently saved.
7. Implement a free-tier-friendly cloud persistence approach.
8. Diagnose and repair the hosted app when it did not load.
9. Verify and redeploy the final repair.

## 3. Final system state

| Item | Final value |
| --- | --- |
| Product name shown in the app | Ahmed OS |
| Repository name | `mizanapp` |
| Git branch | `main` |
| Final session commit | `340e9b5` |
| Firebase project | `mizan-app-7fa3f` |
| Firebase web app ID | `1:55199742804:web:b3f204b94b715263e066c1` |
| Hosting URL | <https://mizan-app-7fa3f.web.app> |
| Firestore database | `(default)` |
| Firestore location | `me-central2` |
| Authentication | Email and password |
| Cloud data location | `users/{uid}/state/app` |
| Device cache | `shared_preferences`, separated by Firebase user ID |
| Flutter used for final build | `3.29.3` |
| Dart used for final build | `3.7.2` |
| Self-hosted Firebase JS SDK | `11.9.1` |
| Final Hosting release ID | `cdd9c4475faded33` |

## 4. Application brought into the repository

The Flutter application source was added to the repository in commit
`6db543a`. It includes:

- Home and daily focus suggestions.
- Goals and task management.
- Training plans and workout logging.
- Strength, skill, conditioning, and running records.
- Workout templates and exercise history.
- Progress calculations and charts.
- Pillar settings and theme settings.
- Notion snapshot and training plan import data.
- Complete JSON export and erase-everything actions.
- Responsive Flutter web UI and a standalone web manifest.
- Unit tests for the focus engine, progress, streaks, tasks, workouts,
  document persistence, imports, and training plan integrity.

The web page includes mobile viewport metadata, portrait orientation, light and
dark theme colors, and standalone display settings so it can be opened in a
mobile browser and added to a phone home screen when the browser supports it.

## 5. GitHub work

The local project was connected to:

```text
https://github.com/ahmedmoreco-lab/mizanapp.git
```

The existing repository history was preserved and merged rather than replaced.
All session changes were pushed to the `main` branch. Generated build output,
Flutter tool caches, Firebase CLI state, IDE files, and debug logs remain
excluded through `.gitignore`.

## 6. Firebase configuration

The Flutter project was registered with Firebase project
`mizan-app-7fa3f`. The generated Flutter options are stored in
`lib/firebase_options.dart`, and `.firebaserc` makes this project the default
Firebase CLI target.

The following Firebase services were configured:

- Firebase Hosting for the public Flutter web build.
- Firebase Authentication with email/password accounts.
- Cloud Firestore for cross-device application state.
- Firestore security rules for per-account ownership.

The approach is suitable for the Firebase no-cost tier while usage remains
inside its quotas. It does not guarantee that every future usage level or
Firebase feature will remain free, so Firebase usage and billing settings
should still be monitored.

## 7. Authentication experience

An authentication screen was added with:

- Sign-in mode.
- Create-account mode.
- Email validation.
- Password validation and show/hide control.
- Password reset email support.
- Friendly messages for common Firebase Authentication errors.
- Sign-out support from the profile/session flow.

The app does not open account data until Firebase reports the authenticated
user. Signing into the same account on another phone or computer points both
devices at the same Firestore document.

## 8. Data storage and synchronization

Before the Firebase work, application state was stored only in the browser or
device through `shared_preferences`. That data was local to that device and
browser profile.

The final design is local-first with cloud synchronization:

1. Each signed-in account gets a separate device cache using a key containing
   the Firebase user ID.
2. An edit is saved to the local cache first.
3. A pending `save` marker is recorded before the Firestore write.
4. If Firestore is reachable, the complete app document is written to
   `users/{uid}/state/app`.
5. If the connection is unavailable or times out, the local edit remains and
   the app reports an offline sync state.
6. The pending operation is retried after Firestore reconnects or during the
   next load.
7. Live Firestore snapshots update the local cache while the app is open.
8. Erasing data records a pending `delete`, so cloud deletion is also retried
   after reconnection.

The Firestore envelope contains only:

```text
schemaVersion: 1
updatedAt: server timestamp
document: complete Ahmed OS JSON document
```

The first Firebase account used on a device can claim the old device-only
document. After it is copied into the account-specific cache and queued for
cloud upload, the legacy local copy is removed.

### What this means on a phone

- Edits are not limited to that phone after cloud sync succeeds.
- The same account can retrieve the data on another supported device.
- Temporary connection loss does not discard an edit already written locally.
- A brand-new device with no local cache needs a connection to retrieve the
  account document.
- Because the cloud representation is one complete document, concurrent edits
  from multiple devices use last-write-wins behavior at the document level.
- Clearing browser site data removes that device's cache, but it does not erase
  an already-synced Firestore document.
- The in-app Erase everything action intentionally clears both the local cache
  and the account's Firestore document.

## 9. Firestore security

The deployed rules only allow an authenticated user to access their own path:

```text
users/{their Firebase user ID}/state/app
```

Reads and deletes require the authenticated user ID to match the path user ID.
Creates and updates also require:

- The document ID to be exactly `app`.
- Only `schemaVersion`, `updatedAt`, and `document` at the top level.
- `schemaVersion` to equal `1`.
- `document` to be a map.

This prevents one signed-in account from reading or overwriting another
account's application state through the client.

## 10. Hosting configuration

Firebase Hosting serves `build/web` and rewrites unknown routes to
`index.html`, which is required for a single-page Flutter application.

No-cache response headers were configured for the deployment entry points:

- `/`
- `/index.html`
- `/flutter_bootstrap.js`
- `/firebase_loader.js`
- `/flutter_service_worker.js`
- `/main.dart.js`

This reduces the chance of an older service worker or bootstrap file keeping a
broken release active after a new deployment.

## 11. Loading problem and troubleshooting timeline

### First symptom: generic connection failure

The hosted URL displayed `Could not connect` and asked the user to check the
connection. At this point it was unclear whether Firebase, the browser network,
or the Flutter bootstrap was responsible.

The bootstrap was updated to:

- Time out Firebase initialization after 20 seconds.
- Show the actual Firebase exception instead of only a generic message.
- Provide a Retry action.
- Recover when Firebase core initialized but the following auth connection was
  slow or failed.
- Show a separate message when account cloud data is unavailable.

### Second symptom: Firebase web modules

Firebase JavaScript modules were made part of the hosted application instead
of being fetched from an external CDN at every startup. The loader imports the
local Core, Auth, and Firestore modules, exposes them for FlutterFire, and only
then starts `flutter_bootstrap.js`.

If those modules or Flutter fail to load, the plain HTML loader shows a usable
error screen and Retry button even before Flutter starts.

### Final diagnostic error

The improved error screen exposed the exact failure:

```text
PlatformException(channel-error, Unable to establish connection on channel:
dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore)
```

Inspection of Flutter's generated
`.dart_tool/flutter_build/.../web_plugin_registrant.dart` showed that it only
registered `shared_preferences_web`. It did not register Firebase Core, Auth,
or Firestore. Therefore Dart called the Firebase platform channel, but no
Firebase web plugin was attached to answer it.

This matched the stale generated registrant behavior tracked in Flutter issue
[#189128](https://github.com/flutter/flutter/issues/189128).

### Final repair

The following repair sequence was completed:

1. Ran `flutter clean` to remove stale Flutter generated files.
2. Ran `flutter pub get` to regenerate package and plugin metadata.
3. Attempted a fresh release build.
4. Found a second issue: the newest selected `firebase_core_web` used
   `Object.isA<JSObject>()`, which was unavailable in Dart `3.7.2`.
5. Pinned FlutterFire packages compatible with the installed Flutter/Dart
   toolchain.
6. Updated the self-hosted Firebase JavaScript modules to the matching SDK
   version `11.9.1`.
7. Replaced `firebase-firestore-pipelines.js` with the correct full
   `firebase-firestore.js` module.
8. Updated `firebase_loader.js` to import the correct Firestore module.
9. Rebuilt the web app from the clean generated state.
10. Confirmed that the new generated registrant registers Firebase Core,
    Firebase Auth, Cloud Firestore, and Shared Preferences.
11. Redeployed Firebase Hosting.
12. Pushed the repair to GitHub.

## 12. Final dependency alignment

Direct FlutterFire dependencies:

```yaml
firebase_core: 3.15.2
firebase_auth: 5.7.0
cloud_firestore: 5.6.12
```

Resolved web implementations:

```text
firebase_core_web 2.24.1
firebase_auth_web 5.15.3
cloud_firestore_web 4.4.12
```

The self-hosted JavaScript modules must remain compatible with these packages.
When FlutterFire is upgraded later, the JavaScript modules and a completely
clean web build should be reviewed together.

## 13. Verification completed

The final release passed the following checks:

- `flutter build web --release`: successful.
- `flutter analyze`: no issues found.
- `flutter test`: all 43 tests passed.
- Generated web registrant includes Firebase Core, Auth, Firestore, and Shared
  Preferences registrations.
- Node module evaluation reported Firebase JS SDK `11.9.1` and callable
  `initializeApp`, `getAuth`, and `getFirestore` exports.
- The live `main.dart.js` SHA-256 matched the local release build exactly.
- The live Firebase loader, Core, Auth, and Firestore module SHA-256 hashes each
  matched the local release build exactly.
- All live JavaScript modules were served as `text/javascript`.
- The final hosting URL returned HTTP `200` with `text/html`.
- The Git working tree was clean after the final push.

The last cache-busting link given for testing was:

<https://mizan-app-7fa3f.web.app/?v=4>

Automated build, asset, module, and HTTP verification was completed. Final
interactive behavior on the user's physical phone remains a real-device check.

## 14. Important project files

| File | Purpose |
| --- | --- |
| `lib/main.dart` | Application entry point. |
| `lib/bootstrap.dart` | Firebase startup, auth session handling, loading, retry, and error states. |
| `lib/firebase_options.dart` | Firebase web project configuration generated for FlutterFire. |
| `lib/data/local_store.dart` | Legacy and per-account device cache. |
| `lib/data/cloud_store.dart` | Local-first Firestore synchronization and pending operation recovery. |
| `lib/state/app_state.dart` | Central application state, mutations, persistence, import, export, and erase behavior. |
| `lib/ui/auth/auth_page.dart` | Sign in, account creation, and password reset UI. |
| `firestore.rules` | Per-user Firestore access policy and document shape validation. |
| `firebase.json` | Firebase Auth, Firestore, Hosting, cache headers, and rewrite configuration. |
| `.firebaserc` | Default Firebase project selection. |
| `web/index.html` | Mobile web shell and pre-Flutter error styling. |
| `web/firebase_loader.js` | Loads self-hosted Firebase modules before Flutter. |
| `web/firebase/` | Self-hosted Firebase Core, Auth, and Firestore JavaScript modules. |
| `web/manifest.json` | Standalone mobile web app metadata. |
| `pubspec.yaml` | Flutter dependencies, assets, and font configuration. |
| `test/` | Logic, import, training plan, and document storage tests. |

## 15. Session commit history

| Commit | Time (Asia/Kuwait) | Purpose |
| --- | --- | --- |
| `048804c` | 2026-07-16 07:54 | Pre-existing initial repository commit. |
| `6db543a` | 2026-08-30 19:15 | Added the Ahmed OS Flutter application. |
| `3c35ce2` | 2026-08-30 19:15 | Merged the existing repository history. |
| `432c5a3` | 2026-08-30 20:49 | Added Firebase account authentication and cloud synchronization. |
| `3840cc3` | 2026-08-30 21:12 | Added self-hosted Firebase web modules and the loader. |
| `dae9f09` | 2026-08-30 21:30 | Added recovery and diagnostics for slow Firebase auth startup. |
| `340e9b5` | 2026-08-30 21:38 | Regenerated Firebase plugin registration and aligned SDK versions. |

## 16. Standard build and deployment procedure

Run these commands from the project root:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase deploy --only hosting
```

If `firestore.rules` changes, deploy it as well:

```powershell
firebase deploy --only firestore:rules,hosting
```

After deployment:

1. Open the live URL with a new query value such as `?v=5`.
2. On desktop, use `Ctrl+Shift+R` if an old version remains visible.
3. On a phone, close the old tab and reopen the link.
4. If the browser still holds a broken service worker, clear site data for the
   hosting domain once and reopen it.
5. Sign in with the same Firebase account to verify cross-device data.

## 17. Operational notes

- Do not run a normal web build from stale `.dart_tool` plugin metadata after
  adding or removing Flutter plugins. Use `flutter clean` first.
- Keep the pinned FlutterFire versions until the Flutter SDK is deliberately
  upgraded and the complete clean build is tested.
- Keep all three self-hosted Firebase JS modules on the same SDK version.
- Test sign-in, one edit, a refresh, sign-out/sign-in, and a second device after
  changing authentication, Firestore, or persistence code.
- Firestore client configuration is delivered to browsers by design; security
  depends on Authentication and Firestore rules, so rule changes must always be
  reviewed and deployed.
- Monitor Firebase quotas as usage grows.

## 18. Final outcome

At the end of the session, the project was committed and pushed to GitHub, the
Flutter release was hosted on Firebase, Firebase account login and Firestore
sync were implemented, offline device caching was retained, owner-only rules
were deployed, and the Firebase web startup failure shown in the screenshots
was repaired in the deployed build.
