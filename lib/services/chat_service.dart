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
      'status': 'sent', // Initial status: Single tick
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
      // 1. Reset unread count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount_$currentUserId': 0,
      });

      // 2. Update all messages from the other user to 'seen'
      try {
        final unreadMessages = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isEqualTo: receiverId)
            .where('status', isNotEqualTo: 'seen')
            .get();

        if (unreadMessages.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in unreadMessages.docs) {
            batch.update(doc.reference, {'status': 'seen'});
          }
          await batch.commit();
        }
      } catch (e) {
        print(
          'DEBUG: Seen status update failed (likely missing index or permission): $e',
        );
      }
    } catch (e) {
      print('DEBUG: markAsRead main error: $e');
    }
  }

  // Mark messages as delivered (Double Grey Tick)
  Future<void> markAsDelivered() async {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    try {
      // PRO TIP: Collection Group queries find ALL 'messages' subcollections at once
      final messagesSnapshot = await _firestore
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'sent')
          .get();

      if (messagesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'status': 'delivered'});
      }

      await batch.commit();
      print(
        'DEBUG: Successfully marked ${messagesSnapshot.docs.length} messages as delivered',
      );
    } catch (e) {
      // If you see an error here, check if you need to create a Collection Group index in Firebase Console
      print('DEBUG: markAsDelivered error: $e');
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

            // Map Firestore status to MessageStatus
            MessageStatus status = MessageStatus.none;
            if (data['senderId'] == currentUserId) {
              final statusStr = data['status'] ?? 'sent';
              if (statusStr == 'seen') {
                status = MessageStatus.read;
              } else if (statusStr == 'delivered') {
                status = MessageStatus.received;
              } else {
                status = MessageStatus
                    .pending; // We'll use pending for sent (single tick)
              }
            }

            return ChatMessage(
              text: data['text'] ?? '',
              user: ChatUser(
                id: data['senderId'],
                firstName: data['user']['firstName'],
                profileImage: data['user']['profileImage'],
              ),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: status,
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

          // Sort client-side to avoid requiring a Firestore composite index
          chats.sort((a, b) {
            final aTime =
                (a['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime =
                (b['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime); // Latest first
          });

          return chats;
        });
  }
}
