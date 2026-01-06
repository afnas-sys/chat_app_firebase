// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/status_model.dart';
import 'package:uuid/uuid.dart';

final statusRepositoryProvider = Provider(
  (ref) => StatusRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  StatusRepository({required this.firestore, required this.auth});

  Future<void> uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required String imageUrl,
    required String caption,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = auth.currentUser!.uid;

      // Expire after 2 hours
      DateTime now = DateTime.now();
      DateTime expiresAt = now.add(const Duration(hours: 24));

      Status status = Status(
        uid: uid,
        username: username,
        phoneNumber: phoneNumber,
        profilePic: profilePic,
        statusId: statusId,
        imageUrl: imageUrl,
        caption: caption,
        timestamp: now,
        expiresAt: expiresAt,
        viewers: [],
        reactions: {},
      );

      await firestore.collection('status').doc(statusId).set(status.toMap());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get statuses that are NOT expired
  Stream<List<Status>> getStatuses() {
    return firestore
        .collection('status')
        .where(
          'expiresAt',
          isGreaterThan: DateTime.now().millisecondsSinceEpoch,
        )
        .orderBy(
          'expiresAt',
          descending: true,
        ) // This ensures newer expiration (latest 2h window) came last? No.
        // We probably want to order by timestamp. But we need a composite index for that.
        // Let's rely on client side sorting if data is small, or strictly follow index rules.
        // where expiresAt > now, order by expiresAt.
        // Then client-side sort by timestamp.
        .snapshots()
        .map((snapshot) {
          List<Status> statuses = [];
          for (var doc in snapshot.docs) {
            statuses.add(Status.fromMap(doc.data()));
          }
          return statuses;
        });
  }

  Future<void> markStatusSeen(String statusId) async {
    try {
      String uid = auth.currentUser!.uid;
      final docRef = firestore.collection('status').doc(statusId);
      final doc = await docRef.get();

      if (doc.exists) {
        List<dynamic> viewers = doc.data()?['viewers'] ?? [];
        bool alreadyViewed = false;

        for (var v in viewers) {
          if (v is String && v == uid) {
            alreadyViewed = true;
            break;
          } else if (v is Map && v['uid'] == uid) {
            alreadyViewed = true;
            break;
          }
        }

        if (!alreadyViewed) {
          await docRef.update({
            'viewers': FieldValue.arrayUnion([
              {'uid': uid, 'timestamp': DateTime.now().millisecondsSinceEpoch},
            ]),
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteStatus(String statusId) async {
    try {
      await firestore.collection('status').doc(statusId).delete();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reactToStatus(String statusId, String reaction) async {
    try {
      String uid = auth.currentUser!.uid;
      await firestore.collection('status').doc(statusId).update({
        'reactions.$uid': reaction,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
