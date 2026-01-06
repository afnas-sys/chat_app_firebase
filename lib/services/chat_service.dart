// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();

  // IMPORTANT: For production, you should use a secure way to manage this key
  // or use Firebase Cloud Functions (Blaze Plan).
  // For Spark Plan testing, we send directly from the app.
  static const String _fcmServerKey =
      'AAAA62B... (REPLACE WITH YOUR SERVER KEY)';

  // Get chat ID by sorting UIDs to ensure consistency between two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  // Send message
  Future<void> sendMessage(
    String receiverId,
    ChatMessage message, {
    bool isGroup = false,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    // If group, receiverId is the Group ID (chatId).
    // If 1-on-1, receiverId is the other user's ID.
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    print('DEBUG: sendMessage called for chatId: $chatId (isGroup: $isGroup)');

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
      'medias': message.medias
          ?.map(
            (m) => {
              'url': m.url,
              'type': m.type.toString(),
              'fileName': m.fileName,
            },
          )
          .toList(),
    };

    // 1. Update/Create parent chat document FIRST
    // This ensures the chat exists so that message subcollection rules work correctly
    final updateData = {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      if (!isGroup) 'users': [currentUserId, receiverId],
      if (!isGroup) 'participants': [currentUserId, receiverId],
      'lastSenderId': currentUserId,
    };

    // For groups, we don't update 'users' array here typically, unless we want to "revive" it?
    // Groups already have 'users'.
    // However, for 1-on-1, we ensure users array.
    // Also, update unreadCount for others.

    if (isGroup) {
      // For groups, we ideally increment unreadCount for ALL other members.
      // But implementing that efficiently requires cloud functions or carefully crafted batch updates.
      // For now, let's skip complex unread count for groups or just try to increment for everyone else?
      // We can't easily filter all fields "unreadCount_*" in a simple set.
      // For MVP, we might skip group unread counts or handle later.
      // But unreadCount_${receiverId} is definitely wrong for groups since receiverId is groupId.
      // We need unreadCount_USERID for each user.
      // Let's leave unread counts for groups for now to avoid complexity/bugs.
    } else {
      updateData['unreadCount_$receiverId'] = FieldValue.increment(1);
    }

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

    // 3. Send Push Notification
    _triggerNotification(
      chatId: chatId,
      receiverId: receiverId,
      messageText: message.text,
      senderName: message.user.firstName ?? 'Someone',
      isGroup: isGroup,
    );
  }

  Future<void> _triggerNotification({
    required String chatId,
    required String receiverId,
    required String messageText,
    required String senderName,
    required bool isGroup,
  }) async {
    try {
      if (_fcmServerKey.startsWith('AAAA')) {
        // Only attempt if key looks valid
        if (isGroup) {
          // Send to all group members
          final chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();
          final List<String> userIds = List<String>.from(
            chatDoc.data()?['users'] ?? [],
          );
          final currentUserId = _auth.currentUser?.uid;

          for (String uid in userIds) {
            if (uid != currentUserId) {
              _sendToUser(
                uid,
                senderName,
                messageText,
                chatId,
                groupName: chatDoc.data()?['groupName'],
              );
            }
          }
        } else {
          // Send to 1-on-1 recipient
          _sendToUser(receiverId, senderName, messageText, chatId);
        }
      }
    } catch (e) {
      print('DEBUG: Notification trigger error: $e');
    }
  }

  Future<void> _sendToUser(
    String uid,
    String title,
    String body,
    String chatId, {
    String? groupName,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final token = userDoc.data()?['fcmToken'];

      if (token != null) {
        await _dio.post(
          'https://fcm.googleapis.com/fcm/send',
          data: {
            'to': token,
            'notification': {
              'title': groupName ?? title,
              'body': groupName != null ? '$title: $body' : body,
              'android_channel_id': 'high_importance_channel',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'data': {'chatId': chatId, 'type': 'chat'},
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$_fcmServerKey',
            },
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error sending push to $uid: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String receiverId, {bool isGroup = false}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

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
      print('DEBUG: [UID: $currentUserId] markAsDelivered error: $e');
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
  Stream<List<ChatMessage>> getMessages(
    String receiverId, {
    bool isGroup = false,
  }) {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final String currentUserId = _auth.currentUser!.uid;
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                final List<dynamic> deletedFor = data['deletedFor'] ?? [];
                return !deletedFor.contains(currentUserId);
              })
              .map((doc) {
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
                  customProperties: {'id': doc.id},
                  text: data['text'] ?? '',
                  user: ChatUser(
                    id: data['senderId'],
                    firstName: data['user']['firstName'],
                    profileImage: data['user']['profileImage'],
                  ),
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  status: status,
                  medias: data['medias'] != null
                      ? (data['medias'] as List<dynamic>).map((m) {
                          MediaType mediaType = MediaType.file;
                          final typeStr = m['type'].toString();
                          if (typeStr == MediaType.image.toString()) {
                            mediaType = MediaType.image;
                          } else if (typeStr == MediaType.video.toString()) {
                            mediaType = MediaType.video;
                          }

                          return ChatMedia(
                            url: m['url'],
                            fileName: m['fileName'] ?? '',
                            type: mediaType,
                          );
                        }).toList()
                      : null,
                );
              })
              .toList();
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

              final bool isGroup = data['isGroup'] == true;

              if (isGroup) {
                // Handle Group Chat
                chats.add({
                  ...data,
                  'uid': doc
                      .id, // Use chat ID as UID for groups to route correctly
                  'displayName': data['groupName'] ?? 'Unknown Group',
                  'photoURL':
                      data['groupImage'] ??
                      '', // Add group placeholder if empty
                  'isOnline': false,
                  'id': doc.id,
                  'isGroup': true,
                  'unreadCount': data['unreadCount_$currentUserId'] ?? 0,
                  'lastMessage': data['lastMessage'] ?? '',
                  'lastMessageTime': data['lastMessageTime'],
                });
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
                'isGroup': false,
                'unreadCount': data['unreadCount_$currentUserId'] ?? 0,
                'email': userData['email'],
                'createdAt': userData['createdAt'],
                'lastSeen': userData['lastSeen'],
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

  // Block user
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser.uid).update({
      'blockedUsers': FieldValue.arrayUnion([userId]),
    });
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser.uid).update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  // Delete Chat (handles both 1-on-1 and group chats)
  Future<void> deleteChat(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;
    String chatId;
    bool isGroup = false;

    try {
      // First, try to check if receiverId is actually a group chat ID
      final chatDoc = await _firestore
          .collection('chats')
          .doc(receiverId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data();
        isGroup = data?['isGroup'] == true;

        if (isGroup) {
          // receiverId is the group chat ID
          chatId = receiverId;
        } else {
          // It's a 1-on-1 chat, use the standard chat ID format
          chatId = getChatId(currentUserId, receiverId);
        }
      } else {
        // Document doesn't exist with receiverId, assume it's a user ID for 1-on-1
        chatId = getChatId(currentUserId, receiverId);
      }

      print('DEBUG: Attempting to delete chat $chatId (isGroup: $isGroup)');

      // 1. Delete all messages in the subcollection
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      if (messages.docs.isNotEmpty) {
        // Delete messages in batches (Firestore batch limit is 500)
        final batches = <WriteBatch>[];
        var currentBatch = _firestore.batch();
        var operationCount = 0;

        for (final doc in messages.docs) {
          currentBatch.delete(doc.reference);
          operationCount++;

          if (operationCount == 500) {
            batches.add(currentBatch);
            currentBatch = _firestore.batch();
            operationCount = 0;
          }
        }

        if (operationCount > 0) {
          batches.add(currentBatch);
        }

        for (final batch in batches) {
          await batch.commit();
        }

        print('DEBUG: Deleted ${messages.docs.length} messages from $chatId');
      }

      // 2. Delete the chat document itself
      await _firestore.collection('chats').doc(chatId).delete();
      print('DEBUG: Chat $chatId deleted successfully');
    } catch (e) {
      print('DEBUG: Error deleting chat: $e');
      rethrow;
    }
  }

  // Create Group
  Future<void> createGroup(
    String groupName,
    List<String> memberIds,
    String groupImage,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final allMembers = [...memberIds, currentUserId];

    final groupData = {
      'groupName': groupName,
      'groupImage': groupImage,
      'isGroup': true,
      'adminId': currentUserId,
      'users': allMembers,
      'participants': allMembers,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    };

    try {
      final docRef = await _firestore.collection('chats').add(groupData);
      print('DEBUG: Group created with ID: ${docRef.id}');

      // Add initial system message
      await docRef.collection('messages').add({
        'text': '$groupName created',
        'senderId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'user': {
          'id': currentUserId,
          'firstName': 'System',
          'profileImage': '',
        },
        'isSystemMessage': true,
      });
    } catch (e) {
      print('DEBUG: Error creating group: $e');
      rethrow;
    }
  }

  // Update Group Image
  Future<void> updateGroupImage(String groupId, String imageUrl) async {
    try {
      await _firestore.collection('chats').doc(groupId).update({
        'groupImage': imageUrl,
      });
      print('DEBUG: Group image updated for $groupId');
    } catch (e) {
      print('DEBUG: Error updating group image: $e');
      rethrow;
    }
  }

  // Add members to group
  Future<void> addMembersToGroup(
    String groupId,
    List<String> newMemberIds,
  ) async {
    try {
      await _firestore.collection('chats').doc(groupId).update({
        'users': FieldValue.arrayUnion(newMemberIds),
        'participants': FieldValue.arrayUnion(newMemberIds),
      });
      print('DEBUG: Added members $newMemberIds to group $groupId');

      final currentUserId = _auth.currentUser?.uid ?? '';
      // Add system message
      await _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .add({
            'text': 'New members added',
            'senderId': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'sent',
            'user': {
              'id': currentUserId,
              'firstName': 'System',
              'profileImage': '',
            },
            'isSystemMessage': true,
          });
    } catch (e) {
      print('DEBUG: Error adding members to group: $e');
      rethrow;
    }
  }

  // Remove members from group
  Future<void> removeMembersFromGroup(
    String groupId,
    List<String> memberIdsToRemove,
  ) async {
    try {
      await _firestore.collection('chats').doc(groupId).update({
        'users': FieldValue.arrayRemove(memberIdsToRemove),
        'participants': FieldValue.arrayRemove(memberIdsToRemove),
      });
      print('DEBUG: Removed members $memberIdsToRemove from group $groupId');

      final currentUserId = _auth.currentUser?.uid ?? '';
      // Add system message
      await _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .add({
            'text': 'Members removed from group',
            'senderId': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'sent',
            'user': {
              'id': currentUserId,
              'firstName': 'System',
              'profileImage': '',
            },
            'isSystemMessage': true,
          });
    } catch (e) {
      print('DEBUG: Error removing members from group: $e');
      rethrow;
    }
  }

  // Delete message for me
  Future<void> deleteMessageForMe(
    String receiverId,
    String messageId, {
    bool isGroup = false,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([currentUserId]),
          });
      print('DEBUG: Message $messageId deleted for user $currentUserId');
    } catch (e) {
      print('DEBUG: Error deleting message for me: $e');
      rethrow;
    }
  }

  // Delete message for everyone
  Future<void> deleteMessageForEveryone(
    String receiverId,
    String messageId, {
    bool isGroup = false,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'text': '🚫 This message was deleted',
            'isDeleted': true,
            'medias': null,
          });

      print('DEBUG: Message $messageId deleted for everyone');
    } catch (e) {
      print('DEBUG: Error deleting message for everyone: $e');
      rethrow;
    }
  }

  // Restore message for me (Undo)
  Future<void> restoreMessageForMe(
    String receiverId,
    String messageId,
    String currentUserId, {
    bool isGroup = false,
  }) async {
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayRemove([currentUserId]),
          });
      print('DEBUG: Message $messageId restored for user $currentUserId');
    } catch (e) {
      print('DEBUG: Error restoring message for me: $e');
      rethrow;
    }
  }

  // Restore message (for Undo)
  Future<void> restoreMessage(
    String receiverId,
    String messageId,
    Map<String, dynamic> oldData, {
    bool isGroup = false,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = isGroup
        ? receiverId
        : getChatId(currentUserId, receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(oldData);
      print('DEBUG: Message $messageId restored');
    } catch (e) {
      print('DEBUG: Error restoring message: $e');
      rethrow;
    }
  }
}
