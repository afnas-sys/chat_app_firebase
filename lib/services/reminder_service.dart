import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:support_chat/models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _reminders => _firestore.collection('reminders');

  Future<void> addReminder(String message, DateTime dateTime) async {
    final userId = _auth.currentUser!.uid;
    final docRef = _reminders.doc();
    final reminder = ReminderModel(
      id: docRef.id,
      message: message,
      dateTime: dateTime,
      userId: userId,
    );
    await docRef.set(reminder.toMap());
  }

  Future<void> updateReminder(
    String id,
    String message,
    DateTime dateTime,
  ) async {
    await _reminders.doc(id).update({
      'message': message,
      'dateTime': Timestamp.fromDate(dateTime),
      'isShown':
          false, // Reset so it can show again if time is changed to future
    });
  }

  Future<void> markAsShown(String id) async {
    await _reminders.doc(id).update({'isShown': true});
  }

  Future<void> deleteReminder(String id) async {
    await _reminders.doc(id).delete();
  }

  Future<void> restoreReminder(ReminderModel reminder) async {
    await _reminders.doc(reminder.id).set(reminder.toMap());
  }

  Stream<List<ReminderModel>> getReminders() {
    final userId = _auth.currentUser!.uid;
    return _reminders
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ReminderModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Stream<List<ReminderModel>> getActiveReminders() {
    final userId = _auth.currentUser!.uid;
    return _reminders
        .where('userId', isEqualTo: userId)
        .where('isShown', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ReminderModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }
}
