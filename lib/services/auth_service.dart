// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Update FCM token in Firestore
  Future<void> updateFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        print('---------------------------------------------');
        print('FIRESTORE SYNC - FCM Token: $token');
        print('---------------------------------------------');
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('DEBUG: Error updating FCM token: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // 1. Check if display name is already taken (case-insensitive)
      if (displayName != null && displayName.isNotEmpty) {
        final String searchName = displayName.toLowerCase();
        final querySnapshot = await _firestore
            .collection('users')
            .where('searchName', isEqualTo: searchName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return {
            'success': false,
            'message': 'This username is already taken. Please choose another.',
          };
        }
      }

      // 2. Normalize and Capitalize display name
      String? normalizedDisplayName;
      if (displayName != null && displayName.isNotEmpty) {
        normalizedDisplayName = _capitalize(displayName.trim());
      }

      // 3. Create user with email and password
      print('DEBUG: Attempting to create user in Auth...');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      print('DEBUG: Auth account created: ${userCredential.user?.uid}');

      // 4. Update display name if provided
      if (normalizedDisplayName != null) {
        await userCredential.user?.updateDisplayName(normalizedDisplayName);
      }

      // 5. Store user data in Firestore
      try {
        print('DEBUG: Attempting to save to Firestore...');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'displayName': normalizedDisplayName ?? '',
          'searchName': (normalizedDisplayName ?? '').toLowerCase(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
        print('DEBUG: Firestore document saved successfully');
      } catch (e) {
        print('DEBUG: Firestore Error: $e');
        return {
          'success': false,
          'message': 'Auth succeeded but Database failed: $e',
        };
      }

      // 6. Update FCM Token
      await updateFcmToken();

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Firebase Auth Error: ${e.code}');
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      print('DEBUG: General Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Update user's online status
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastSeen': FieldValue.serverTimestamp(), 'isOnline': true},
      );

      // Update FCM Token
      await updateFcmToken();

      return {
        'success': true,
        'message': 'Signed in successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update user's online status before signing out
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': false,
        });
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (displayName != null) {
        final String capitalizedName = _capitalize(displayName.trim());
        // 1. Check if name is taken by another user
        final String searchName = capitalizedName.toLowerCase();
        final querySnapshot = await _firestore
            .collection('users')
            .where('searchName', isEqualTo: searchName)
            .get();

        // Check if any document found belongs to a DIFFERENT user
        final isTaken = querySnapshot.docs.any((doc) => doc.id != uid);

        if (isTaken) {
          print(
            'DEBUG: Name $capitalizedName is already taken by another user',
          );
          return false;
        }

        updates['displayName'] = capitalizedName;
        updates['searchName'] = searchName;
        await currentUser?.updateDisplayName(capitalizedName);
      }

      if (photoUrl != null) {
        updates['photoURL'] = photoUrl;
        updates['image'] = photoUrl; // For compatibility with older widgets
        await currentUser?.updatePhotoURL(photoUrl);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }

      return true;
    } catch (e) {
      print('DEBUG: Update Profile Error: $e');
      return false;
    }
  }

  // Search users by display name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      print('DEBUG: Searching for users with query: $query');

      // 1. Try searching by lowercase searchName (new users)
      final lowercaseQuery = query.toLowerCase();
      final searchNameSnapshot = await _firestore
          .collection('users')
          .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .get();

      // 2. Try searching by original displayName (old users - case sensitive)
      final displayNameSnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Combine and filter duplicates/current user
      final allDocs = [...searchNameSnapshot.docs, ...displayNameSnapshot.docs];
      final seenUids = <String>{};
      final results = <Map<String, dynamic>>[];

      for (var doc in allDocs) {
        final data = doc.data();
        final uid = data['uid'] as String;
        if (uid != currentUser?.uid && !seenUids.contains(uid)) {
          seenUids.add(uid);
          results.add(data);
        }
      }

      print('DEBUG: Search found ${results.length} users');
      return results;
    } catch (e) {
      print('DEBUG: Search error: $e');
      return [];
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      print('DEBUG: Attempting password reset for: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('DEBUG: Password reset email sent successfully');
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Firebase Auth Reset Error: ${e.code}');
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      print('DEBUG: General Reset Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Helper method to capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is disabled in the Firebase Console.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
