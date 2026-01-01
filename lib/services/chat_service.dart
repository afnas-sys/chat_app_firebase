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
    print('DEBUG: sendMessage called for chatId: $chatId');

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

    // 1. Update/Create parent chat document FIRST
    // This ensures the chat exists so that message subcollection rules work correctly
    final updateData = {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'users': [currentUserId, receiverId],
      'lastSenderId': currentUserId,
      'participants': [currentUserId, receiverId],
      'unreadCount_$receiverId': FieldValue.increment(1),
    };

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(updateData, SetOptions(merge: true));
      print('DEBUG: Updated chat $chatId with lastMessage: "${message.text}"');
    } catch (e) {
      print('DEBUG: [UID: $currentUserId] Failed to update chat $chatId: $e');
    }

    // 2. Add message to chat collection
    // Now that parent exists, we can safely add the message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
  }

  // Mark messages as read
  Future<void> markAsRead(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);

    try {
      // 1. Reset unread count
      final chatDocRef = _firestore.collection('chats').doc(chatId);
      final docSnapshot = await chatDocRef.get();

      if (!docSnapshot.exists) {
        print('DEBUG: Chat $chatId does not exist yet. Skipping markAsRead.');
        return;
      }

      await chatDocRef.update({'unreadCount_$currentUserId': 0});

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

  // Fix legacy chats that use 'participants' instead of 'users'
  Future<void> fixLegacyChats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Find chats where I am a receiver via recent Messages
      // This is a workaround because we can't query the 'chats' collection efficiently for 'participants'
      // without a specific index/rule setup that might be complex.
      // Assuming legacy chats have at least one message sent to me.
      final receivedMsgs = await _firestore
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final chatRefs = receivedMsgs.docs
          .map((d) => d.reference.parent.parent!)
          .toSet();

      for (final chatRef in chatRefs) {
        final doc = await chatRef.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          // If it has 'participants' but NO 'users', migrate it.
          if (!data.containsKey('users') && data.containsKey('participants')) {
            print('DEBUG: Migrating legacy chat ${doc.id}...');
            await chatRef.update({'users': data['participants']});
          }
        }
      }
    } catch (e) {
      print('DEBUG: Legacy chat fix error: $e');
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
    print('DEBUG: Fetching chats for user: $currentUserId');

    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> chats = [];
          print('DEBUG: Found ${snapshot.docs.length} chat documents');

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              if (data['users'] == null) {
                print('DEBUG: Chat ${doc.id} missing users field');
                continue;
              }

              final List<dynamic> rawUsers = data['users'];
              final List<String> userIds = List<String>.from(rawUsers);

              // Handle case where user chat with themselves or logic fails
              String receiverId;
              try {
                receiverId = userIds.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () =>
                      currentUserId, // Fallback to self if no other user
                );
              } catch (e) {
                print('DEBUG: Could not find receiverId for chat ${doc.id}');
                continue;
              }

              // Fetch receiver's info from users collection
              Map<String, dynamic> userData = {};
              try {
                final userDoc = await _firestore
                    .collection('users')
                    .doc(receiverId)
                    .get();
                if (userDoc.exists) {
                  userData = userDoc.data() ?? {};
                } else {
                  print('DEBUG: User document $receiverId not found');
                  // Use basic info if available in chat doc, or defaults
                  userData = {'displayName': 'Unknown User'};
                }
              } catch (e) {
                print('DEBUG: Failed to fetch user $receiverId: $e');
              }

              chats.add({
                ...data,
                'uid': receiverId,
                'displayName':
                    userData['displayName'] ??
                    data['user']?['firstName'] ??
                    'User ${receiverId.substring(0, 5)}',
                'photoURL': userData['photoURL'] ?? userData['image'],
                'isOnline': userData['isOnline'] ?? false,
                'id': doc.id,
                'unreadCount': data['unreadCount_$currentUserId'] ?? 0,
              });
            } catch (e) {
              print('DEBUG: Error processing chat ${doc.id}: $e');
            }
          }

          // Sort client-side
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
