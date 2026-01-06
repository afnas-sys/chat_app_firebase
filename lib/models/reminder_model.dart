import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String message;
  final DateTime dateTime;
  final String userId;
  final bool isShown;

  ReminderModel({
    required this.id,
    required this.message,
    required this.dateTime,
    required this.userId,
    this.isShown = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'dateTime': Timestamp.fromDate(dateTime),
      'userId': userId,
      'isShown': isShown,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      isShown: map['isShown'] ?? false,
    );
  }

  ReminderModel copyWith({
    String? id,
    String? message,
    DateTime? dateTime,
    String? userId,
    bool? isShown,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      userId: userId ?? this.userId,
      isShown: isShown ?? this.isShown,
    );
  }
}
