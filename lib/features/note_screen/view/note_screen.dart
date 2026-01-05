import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/note_screen/view/note_add_screen.dart';
import 'package:support_chat/models/note_model.dart';
import 'package:support_chat/providers/note_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_bottom_bar.dart';
import 'package:intl/intl.dart';

class NoteScreen extends ConsumerStatefulWidget {
  const NoteScreen({super.key});

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesStreamProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        foregroundColor: AppColors.primaryColor,
        backgroundColor: AppColors.fifthColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteAddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomBottomBar(),
                            ),
                          );
                        },
                      ),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleLargePrimary,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          height: 44,
                          width: 44,
                          child: Image.asset(
                            AppImage.profile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: notesAsyncValue.when(
                    data: (notes) => notes.isEmpty
                        ? Center(
                            child: Text(
                              'No notes yet. Tap + to add one!',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMediumPrimary,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return NoteCard(note: note);
                            },
                          ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final NoteModel note;
  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteAddScreen(note: note)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.tenthColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, y').format(note.timestamp),
              style: TextStyle(
                color: AppColors.primaryColor.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
