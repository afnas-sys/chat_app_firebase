// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/note_screen/view/note_add_screen.dart';
import 'package:support_chat/models/note_model.dart';
import 'package:support_chat/providers/note_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_bottom_bar.dart';
import 'package:support_chat/features/note_screen/view/reminder_screen.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class NoteScreen extends ConsumerStatefulWidget {
  const NoteScreen({super.key});

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  bool _isDragging = false;
  bool _isArchiveView = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showDeleteConfirmation(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fifthColor,
        title: const Text('Delete Note', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              final deletedNote = note;
              ref.read(noteServiceProvider).deleteNote(note.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.thirteenthColor,
                  content: Text(
                    'Note deleted',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: AppColors.fifthColor,
                    onPressed: () {
                      ref.read(noteServiceProvider).restoreNote(deletedNote);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesStreamProvider);
    final userAsyncValue = ref.watch(currentUserStreamProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: AppColors.thirteenthColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.fifthColor.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  'Quick Notes',
                  style: Theme.of(context).textTheme.titleLargePrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.notes,
                color: !_isArchiveView
                    ? AppColors.fifthColor
                    : AppColors.primaryColor,
              ),
              title: Text(
                'Notes',
                style: TextStyle(
                  color: !_isArchiveView
                      ? AppColors.fifthColor
                      : AppColors.primaryColor,
                ),
              ),
              onTap: () {
                setState(() => _isArchiveView = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.archive_outlined,
                color: _isArchiveView
                    ? AppColors.fifthColor
                    : AppColors.primaryColor,
              ),
              title: Text(
                'Archive',
                style: TextStyle(
                  color: _isArchiveView
                      ? AppColors.fifthColor
                      : AppColors.primaryColor,
                ),
              ),
              onTap: () {
                setState(() => _isArchiveView = true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm, color: AppColors.primaryColor),
              title: const Text(
                'Reminders',
                style: TextStyle(color: AppColors.primaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.white70),
              title: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomBottomBar(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: _isDragging || _isArchiveView
          ? null
          : FloatingActionButton(
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
          child: Stack(
            children: [
              Padding(
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
                              Icons.menu,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          Text(
                            _isArchiveView ? 'Archive' : 'Notes',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLargePrimary,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: SizedBox(
                              height: 44,
                              width: 44,
                              child: userAsyncValue.when(
                                data: (userData) {
                                  final photoUrl =
                                      userData?['image'] ??
                                      userData?['photoURL'];
                                  if (photoUrl != null && photoUrl.isNotEmpty) {
                                    if (photoUrl.toString().startsWith(
                                      'http',
                                    )) {
                                      return Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                                  AppImage.profile,
                                                  fit: BoxFit.cover,
                                                ),
                                      );
                                    } else {
                                      return Image.asset(
                                        photoUrl.toString().replaceFirst(
                                          'file:///',
                                          '',
                                        ),
                                        fit: BoxFit.cover,
                                      );
                                    }
                                  }
                                  return Image.asset(
                                    AppImage.profile,
                                    fit: BoxFit.cover,
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                error: (error, stack) => Image.asset(
                                  AppImage.profile,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: notesAsyncValue.when(
                        data: (notes) {
                          final filteredNotes = notes
                              .where((n) => n.isArchived == _isArchiveView)
                              .toList();

                          if (filteredNotes.isEmpty) {
                            return Center(
                              child: Text(
                                _isArchiveView
                                    ? 'No archived notes.'
                                    : 'No notes yet. Tap + to add one!',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumPrimary,
                              ),
                            );
                          }

                          final pinnedNotes = filteredNotes
                              .where((n) => n.isPinned)
                              .toList();
                          final unpinnedNotes = filteredNotes
                              .where((n) => !n.isPinned)
                              .toList();

                          return CustomScrollView(
                            slivers: [
                              if (pinnedNotes.isNotEmpty)
                                SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.85,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final note = pinnedNotes[index];
                                    return NoteCard(
                                      note: note,
                                      onDragStarted: () {
                                        setState(() {
                                          _isDragging = true;
                                        });
                                      },
                                      onDragEnded: () {
                                        setState(() {
                                          _isDragging = false;
                                        });
                                      },
                                    );
                                  }, childCount: pinnedNotes.length),
                                ),
                              if (pinnedNotes.isNotEmpty &&
                                  unpinnedNotes.isNotEmpty)
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 12),
                                ),
                              if (unpinnedNotes.isNotEmpty)
                                SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.85,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final note = unpinnedNotes[index];
                                    return NoteCard(
                                      note: note,
                                      onDragStarted: () {
                                        setState(() {
                                          _isDragging = true;
                                        });
                                      },
                                      onDragEnded: () {
                                        setState(() {
                                          _isDragging = false;
                                        });
                                      },
                                    );
                                  }, childCount: unpinnedNotes.length),
                                ),
                              const SliverPadding(
                                padding: EdgeInsets.only(bottom: 80),
                              ),
                            ],
                          );
                        },
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

              // Delete Area
              if (_isDragging)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DragTarget<NoteModel>(
                      onWillAccept: (data) => true,
                      onAccept: (note) {
                        _showDeleteConfirmation(context, note);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isHovering ? Colors.red : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isHovering ? 4 : 2,
                            ),
                            boxShadow: isHovering
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : [],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const NoteCard({
    super.key,
    required this.note,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<NoteModel>(
      data: note,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded?.call(),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height:
              MediaQuery.of(context).size.width *
              0.4 *
              1.17, // approximation of aspect ratio
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.tenthColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryColor),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  note.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryColor.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard(context)),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteAddScreen(note: note)),
            );
          },
          onLongPress: () {
            _showPinOption(context, ref);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tenthColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: note.isPinned
                    ? AppColors.fifthColor.withOpacity(0.5)
                    : AppColors.primaryColor.withOpacity(0.1),
                width: note.isPinned ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        color: AppColors.fifthColor,
                        size: 16,
                      ),
                  ],
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
      },
    );
  }

  void _showPinOption(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.thirteenthColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  note.isPinned ? 'Unpin Note' : 'Pin Note',
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
                onTap: () {
                  ref
                      .read(noteServiceProvider)
                      .togglePin(note.id, !note.isPinned);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  note.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  note.isArchived ? 'Unarchive Note' : 'Archive Note',
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
                onTap: () {
                  ref
                      .read(noteServiceProvider)
                      .toggleArchive(note.id, !note.isArchived);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        note.isArchived ? 'Note unarchived' : 'Note archived',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
