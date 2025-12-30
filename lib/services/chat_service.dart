// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat ID by sorting UIDs to ensure consistency between two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  // Send message
  Future<void> sendMessage(String receiverId, ChatMessage message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);

    final messageData = {
      'text': message.text,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'createdAt': FieldValue.serverTimestamp(),
      'user': {
        'id': currentUserId,
        'firstName': message.user.firstName ?? '',
        'profileImage': message.user.profileImage ?? '',
      },
    };

    // Add message to chat collection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update last message and increment unread count for receiver
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'users': [currentUserId, receiverId],
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Mark messages as read
  Future<void> markAsRead(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount_$currentUserId': 0,
      });
    } catch (e) {
      // If document doesn't exist yet, it's fine
      print('DEBUG: markAsRead error (safe if new chat): $e');
    }
  }

  // Get messages stream
  Stream<List<ChatMessage>> getMessages(String receiverId) {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              text: data['text'] ?? '',
              user: ChatUser(
                id: data['senderId'],
                firstName: data['user']['firstName'],
                profileImage: data['user']['profileImage'],
              ),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  // Get list of active chats for the current user
  Stream<List<Map<String, dynamic>>> getMyChats() {
    final String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> chats = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final List<String> userIds = List<String>.from(data['users']);
            final String receiverId = userIds.firstWhere(
              (id) => id != currentUserId,
            );

            // Fetch receiver's info from users collection
            Map<String, dynamic> userData = {};
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(receiverId)
                  .get();
              userData = userDoc.data() ?? {};
            } catch (e) {
              print('DEBUG: Failed to fetch user $receiverId: $e');
            }

            chats.add({
              ...data,
              'uid': receiverId,
              'displayName':
                  userData['displayName'] ??
                  'User ${receiverId.substring(0, 5)}',
              'photoURL': userData['photoURL'],
              'isOnline': userData['isOnline'] ?? false,
              'id': doc.id,
              'unreadCount': data['unreadCount_$currentUserId'] ?? 0,
            });
          }

          return chats;
        });
  }
}
