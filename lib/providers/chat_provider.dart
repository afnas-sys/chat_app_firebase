import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/services/chat_service.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  receiverId,
) {
  return ref.watch(chatServiceProvider).getMessages(receiverId);
});

// Search query state
final chatSearchProvider = StateProvider<String>((ref) => '');

// Real-time search provider for users in Firebase
final usersSearchProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final query = ref.watch(chatSearchProvider);
  final authService = ref.watch(authServiceProvider);

  // Hardcoded test user
  final testUser = {
    'uid': 'support_admin_id',
    'displayName': 'Support Admin',
    'searchName': 'support admin',
    'email': 'admin@supportchat.app',
    'photoURL': null, // Falls back to default asset
    'isOnline': true,
  };

  if (query.isEmpty) {
    return [testUser]; // Always show the test user when not searching
  }

  final results = await authService.searchUsers(query);

  // Also include test user in results if it matches query
  if (testUser['displayName'].toString().toLowerCase().contains(
    query.toLowerCase(),
  )) {
    if (!results.any((u) => u['uid'] == testUser['uid'])) {
      results.add(testUser);
    }
  }

  return results;
});

// Provider for actual existing chats (inbox)
final userChatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return Stream.value([]);

  return ref.watch(chatServiceProvider).getMyChats();
});
