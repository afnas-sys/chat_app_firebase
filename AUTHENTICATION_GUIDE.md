# Firebase Authentication Implementation

## Overview
This document describes the Firebase Authentication implementation for the Support Chat app using mobile number and password authentication.

## Architecture

### 1. **Authentication Service** (`lib/services/auth_service.dart`)
The core authentication logic is handled by the `AuthService` class which provides:

- **Sign Up**: Creates new user accounts with mobile number and password
- **Sign In**: Authenticates existing users
- **Sign Out**: Logs out users and updates their online status
- **User Data Management**: Stores and retrieves user information from Firestore
- **Password Reset**: Allows users to reset their passwords

**Key Implementation Detail**: 
Since Firebase Auth requires email-based authentication, we convert mobile numbers to email format:
```dart
final email = '$mobileNumber@supportchat.app';
```

### 2. **State Management** (`lib/providers/auth_provider.dart`)
Uses Riverpod for state management with the following providers:

- `authServiceProvider`: Provides the AuthService instance
- `authStateProvider`: Stream of authentication state changes
- `currentUserDataProvider`: Fetches current user data from Firestore
- `authNotifierProvider`: Manages authentication operations (sign in, sign up, sign out)

### 3. **User Interface**

#### Login Screen (`lib/features/login_screen/login_screen.dart`)
- Mobile number and password input fields
- Form validation
- Password visibility toggle
- Loading state during authentication
- Error handling with snackbar messages
- Navigation to registration screen

#### Registration Screen (`lib/features/register_screen/register_screen.dart`)
- Name, mobile number, password, and confirm password fields
- Form validation
- Password visibility toggles
- Loading state during registration
- Error handling with snackbar messages
- Navigation back to login screen

#### Logout Screen (`lib/features/logout_screen/logout_screen.dart`)
- Confirmation dialog
- Firebase sign out integration
- Navigation to login screen after logout

### 4. **Routing** (`lib/utils/router/`)
- Added `registerScreen` route
- Updated router to handle registration navigation
- Main app checks authentication state on startup

### 5. **Main App** (`lib/main.dart`)
- Checks authentication state on app start
- Routes authenticated users to home screen
- Routes unauthenticated users to login screen

## User Data Structure

User data is stored in Firestore under the `users` collection:

```dart
{
  'uid': String,              // Firebase Auth UID
  'mobileNumber': String,     // User's mobile number
  'displayName': String,      // User's display name
  'email': String,            // Generated email (mobile@supportchat.app)
  'createdAt': Timestamp,     // Account creation time
  'lastSeen': Timestamp,      // Last activity time
  'isOnline': bool,           // Current online status
}
```

## Authentication Flow

### Sign Up Flow:
1. User enters name, mobile number, and password
2. System validates input (mobile number length, password strength)
3. System checks if mobile number is already registered
4. Creates Firebase Auth account with email/password
5. Stores user data in Firestore
6. Navigates to home screen

### Sign In Flow:
1. User enters mobile number and password
2. System validates input
3. Converts mobile number to email format
4. Authenticates with Firebase Auth
5. Updates user's online status in Firestore
6. Navigates to home screen

### Sign Out Flow:
1. User confirms logout
2. System updates user's online status to false
3. Signs out from Firebase Auth
4. Navigates to login screen

## Security Features

1. **Password Requirements**: Minimum 6 characters
2. **Mobile Number Validation**: Minimum 10 digits
3. **Form Validation**: All fields validated before submission
4. **Error Handling**: User-friendly error messages
5. **Loading States**: Prevents multiple submissions

## Firebase Configuration

### Required Firebase Services:
- Firebase Authentication (Email/Password enabled)
- Cloud Firestore (for user data storage)

### Security Rules (Recommended):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Dependencies

```yaml
firebase_core: ^4.3.0
firebase_auth: ^6.1.3
cloud_firestore: ^6.1.1
flutter_riverpod: ^2.6.1
```

## Usage Example

### Sign Up:
```dart
await ref.read(authNotifierProvider.notifier).signUp(
  mobileNumber: '1234567890',
  password: 'securePassword',
  displayName: 'John Doe',
);
```

### Sign In:
```dart
await ref.read(authNotifierProvider.notifier).signIn(
  mobileNumber: '1234567890',
  password: 'securePassword',
);
```

### Sign Out:
```dart
await ref.read(authNotifierProvider.notifier).signOut();
```

### Check Auth State:
```dart
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) => user != null ? HomeScreen() : LoginScreen(),
  loading: () => LoadingScreen(),
  error: (error, stack) => ErrorScreen(),
);
```

## Future Enhancements

1. **Phone Number Verification**: Add OTP verification for mobile numbers
2. **Biometric Authentication**: Add fingerprint/face recognition
3. **Social Login**: Add Google/Facebook authentication
4. **Password Strength Indicator**: Visual feedback for password strength
5. **Remember Me**: Add persistent login option
6. **Profile Management**: Allow users to update their profile information

## Troubleshooting

### Common Issues:

1. **"User not found" error**: Mobile number not registered
2. **"Wrong password" error**: Incorrect password entered
3. **"Mobile number already registered"**: Account already exists
4. **"Network error"**: Check internet connection

### Debug Tips:

1. Check Firebase console for user creation
2. Verify Firestore rules allow read/write
3. Ensure Firebase Auth is enabled in console
4. Check app logs for detailed error messages
