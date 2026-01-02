import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/services/chat_service.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

class ChatParams {
  final String receiverId;
  final bool isGroup;

  ChatParams({required this.receiverId, this.isGroup = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParams &&
        other.receiverId == receiverId &&
        other.isGroup == isGroup;
  }

  @override
  int get hashCode => receiverId.hashCode ^ isGroup.hashCode;
}

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, ChatParams>((ref, params) {
      return ref
          .watch(chatServiceProvider)
          .getMessages(params.receiverId, isGroup: params.isGroup);
    });

// Search query state
final chatSearchProvider = StateProvider<String>((ref) => '');

// Real-time search provider for users in Firebase
final usersSearchProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final query = ref.watch(chatSearchProvider);
  final authService = ref.watch(authServiceProvider);

  if (query.isEmpty) {
    // If not searching, return list of recent users to populate the directory
    return authService.getRecentUsers();
  }

  final results = await authService.searchUsers(query);
  return results;
});

// Provider for actual existing chats (inbox)
final userChatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return Stream.value([]);

  return ref.watch(chatServiceProvider).getMyChats();
});
