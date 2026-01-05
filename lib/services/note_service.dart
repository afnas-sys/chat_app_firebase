import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:support_chat/models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notes => _firestore.collection('notes');

  Future<void> addNote(String title, String description) async {
    final userId = _auth.currentUser!.uid;
    final docRef = _notes.doc();
    final note = NoteModel(
      id: docRef.id,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await docRef.set(note.toMap());
  }

  Future<void> updateNote(String id, String title, String description) async {
    await _notes.doc(id).update({
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteNote(String id) async {
    await _notes.doc(id).delete();
  }

  Stream<List<NoteModel>> getNotes() {
    final userId = _auth.currentUser!.uid;
    return _notes
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => NoteModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }
}
