import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:support_chat/models/expanse_model.dart';

class ExpanseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _expanses => _firestore.collection('expanses');

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String description,
    required String type,
  }) async {
    final userId = _auth.currentUser!.uid;
    final docRef = _expanses.doc();
    final transaction = ExpanseModel(
      id: docRef.id,
      amount: amount,
      category: category,
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
      type: type,
    );
    await docRef.set(transaction.toMap());
  }

  Stream<List<ExpanseModel>> getTransactions() {
    final userId = _auth.currentUser!.uid;
    return _expanses
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ExpanseModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<void> deleteTransaction(String id) async {
    await _expanses.doc(id).delete();
  }

  Future<void> updateTransaction(ExpanseModel transaction) async {
    await _expanses.doc(transaction.id).update(transaction.toMap());
  }

  // Category Management
  CollectionReference get _categories =>
      _firestore.collection('expanse_categories');

  Future<void> addCategory(String name, String type) async {
    final userId = _auth.currentUser!.uid;
    await _categories.add({
      'name': name,
      'userId': userId,
      'type': type.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getCategories(String type) {
    final userId = _auth.currentUser!.uid;
    return _categories
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toLowerCase())
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final List<String> defaultCats = type.toLowerCase() == 'income'
              ? ['Salary']
              : ['Travel', 'Grocery', 'Food'];
          final List<String> customCats = snapshot.docs
              .map(
                (doc) => (doc.data() as Map<String, dynamic>)['name'] as String,
              )
              .toList();
          // Combine and remove duplicates
          return {...defaultCats, ...customCats}.toList();
        });
  }

  Future<void> deleteCategory(String name, String type) async {
    final userId = _auth.currentUser!.uid;
    final snapshot = await _categories
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toLowerCase())
        .where('name', isEqualTo: name)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
