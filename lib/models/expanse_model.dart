import 'package:cloud_firestore/cloud_firestore.dart';

class ExpanseModel {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime timestamp;
  final String userId;
  final String type; // 'income' or 'expense'

  ExpanseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'type': type,
    };
  }

  factory ExpanseModel.fromMap(Map<String, dynamic> map) {
    return ExpanseModel(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'expense',
    );
  }

  ExpanseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    DateTime? timestamp,
    String? userId,
    String? type,
  }) {
    return ExpanseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      type: type ?? this.type,
    );
  }
}
