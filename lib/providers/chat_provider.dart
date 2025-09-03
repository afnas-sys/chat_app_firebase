import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/utils/constants/app_image.dart';

final allChatsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      "user": "Alice",
      "image": AppImage.user1,
      "message": "Hey",
      'time': '2 min Ago',
      'msgCount': '3',
      'isOnline': 'Online',
    },
    {
      "user": "Bob",
      "image": AppImage.user2,
      "message": "How are you",
      'time': '2 min Ago',
      'msgCount': '3',
      'isOnline': 'Offline',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      "message": "Can we talk right now",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      "message": "10000 Received",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "Eve",
      "image": AppImage.user5,
      "message": "Are you okay",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Frank",
      "image": AppImage.user6,
      "message": "Congrats",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "John",
      "image": AppImage.user7,
      "message": "I will see you soon",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      "message": "Can we talk right now",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      "message": "10000 Received",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
  ];
});

final chatSearchProvider = StateProvider<String>((ref) => '');

final filteredChatsProvider = Provider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) {
  final query = ref.watch(chatSearchProvider);
  final allChats = ref.watch(allChatsProvider);
  if (query.isEmpty) return allChats;
  return allChats.where((chat) {
    final name = chat['user'].toString().toLowerCase();
    final message = chat['message'].toString().toLowerCase();
    return name.contains(query.toLowerCase()) ||
        message.contains(query.toLowerCase());
  }).toList();
});
