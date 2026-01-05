import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/note_model.dart';
import 'package:support_chat/providers/note_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

class NoteAddScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  const NoteAddScreen({super.key, this.note});

  @override
  ConsumerState<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends ConsumerState<NoteAddScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_isSaved) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty && description.isEmpty) return;

    // Check if the content has changed
    if (widget.note != null &&
        widget.note!.title == title &&
        widget.note!.description == description) {
      return;
    }

    _isSaved = true;
    final noteService = ref.read(noteServiceProvider);

    if (widget.note == null) {
      await noteService.addNote(title, description);
    } else {
      await noteService.updateNote(widget.note!.id, title, description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _saveNote();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImage.appBg),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Text(
                        widget.note == null ? 'Add Note' : 'Edit Note',
                        style: Theme.of(context).textTheme.titleLargePrimary,
                      ),
                      const SizedBox(width: 44), // Spacer for balance
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note Title',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        color: AppColors.tertiaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Description',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.tertiaryColor,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
