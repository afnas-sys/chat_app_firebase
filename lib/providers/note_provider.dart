import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/note_model.dart';
import 'package:support_chat/services/note_service.dart';

final noteServiceProvider = Provider((ref) => NoteService());

final notesStreamProvider = StreamProvider<List<NoteModel>>((ref) {
  return ref.watch(noteServiceProvider).getNotes();
});
