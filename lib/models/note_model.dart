import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String userId;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    String? userId,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }
}
