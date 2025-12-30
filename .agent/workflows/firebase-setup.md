---
description: Firebase Setup for Real-Time Messages
---

# Firebase Setup for Real-Time Messages

## Prerequisites
- Node.js installed
- Firebase project created at https://console.firebase.google.com/
- Flutter SDK installed

## Step-by-Step Commands

### 1. Install Firebase CLI (if not already installed)
```powershell
npm install -g firebase-tools
```

### 2. Install FlutterFire CLI (if not already installed)
```powershell
dart pub global activate flutterfire_cli
```

### 3. Login to Firebase
```powershell
firebase login
```
This opens a browser for authentication.

### 4. Configure Firebase for Your Flutter Project
```powershell
flutterfire configure
```
**What this does:**
- Lists all your Firebase projects
- Lets you select or create a project
- Generates `lib/firebase_options.dart`
- Configures platforms (Android, iOS, Web)

**During configuration, select:**
- Your Firebase project
- Platforms you want to support (Android, iOS, Web)

### 5. Add Firebase Core Package
```powershell
flutter pub add firebase_core
```

### 6. Add Cloud Firestore (Recommended for Chat)
```powershell
flutter pub add cloud_firestore
```

**Alternative: Use Realtime Database**
```powershell
flutter pub add firebase_database
```

### 7. Add Firebase Messaging (for Push Notifications)
```powershell
flutter pub add firebase_messaging
```

### 8. Get All Dependencies
```powershell
flutter pub get
```

### 9. For Android: Download google-services.json
If `flutterfire configure` didn't do this automatically:
1. Go to Firebase Console → Project Settings
2. Download `google-services.json`
3. Place it in `android/app/`

### 10. For iOS: Download GoogleService-Info.plist
1. Go to Firebase Console → Project Settings
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/`

## Initialize Firebase in Your App

After running the commands above, update your `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:support_chat/utils/router/app_router.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/constants/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: const MyApp()));
}
```

## Enable Firestore in Firebase Console

1. Go to Firebase Console
2. Navigate to **Firestore Database**
3. Click **Create Database**
4. Choose **Start in test mode** (for development)
5. Select a location

## Firestore Security Rules (for Testing)

In Firebase Console → Firestore → Rules, use this for testing:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 2, 1);
    }
  }
}
```

**⚠️ Important:** Change these rules for production!

## Test Connection

Run your app:
```powershell
flutter run
```

Check for Firebase initialization in the console output.

## Troubleshooting

### If `flutterfire` command not found:
```powershell
# Add Dart pub global bin to PATH
# Add this to your PATH: %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### If Firebase initialization fails:
1. Check `firebase_options.dart` exists
2. Verify `google-services.json` is in `android/app/`
3. Run `flutter clean` then `flutter pub get`

### For Android build errors:
Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Next Steps

After setup, you can:
1. Create Firestore collections for messages
2. Implement real-time listeners
3. Add authentication with Firebase Auth
4. Set up push notifications with FCM
