import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user data provider
final currentUserDataProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final authService = ref.watch(authServiceProvider);
  return await authService.getUserData(user.uid);
});

// Auth state notifier for handling auth operations
class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data({}));

  // Sign in
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();

    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result['success']) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result['message'], StackTrace.current);
    }
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();

    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (result['success']) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result['message'], StackTrace.current);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data({'success': true});
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    final result = await _authService.resetPassword(email);

    if (result['success']) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result['message'], StackTrace.current);
    }
  }

  // Reset state
  void resetState() {
    state = const AsyncValue.data({});
  }
}

// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>>>((
      ref,
    ) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });
