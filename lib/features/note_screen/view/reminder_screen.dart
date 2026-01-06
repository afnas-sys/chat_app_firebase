// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/models/reminder_model.dart';
import 'package:support_chat/providers/reminder_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  bool _isDragging = false;

  void _showDeleteConfirmation(BuildContext context, ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.thirteenthColor,
        title: const Text(
          'Delete Reminder?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this reminder?',
          style: TextStyle(color: Colors.white70),
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
              final deletedReminder = reminder;
              ref.read(reminderServiceProvider).deleteReminder(reminder.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.thirteenthColor,
                  content: const Text(
                    'Reminder deleted',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: AppColors.fifthColor,
                    onPressed: () {
                      ref
                          .read(reminderServiceProvider)
                          .restoreReminder(deletedReminder);
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

  Widget _buildReminderCard(ReminderModel reminder) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showAddReminderDialog(context, reminder: reminder),
        title: Text(
          reminder.message,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          DateFormat('MMM d, y - hh:mm a').format(reminder.dateTime),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fifthColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddReminderDialog(context),
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
              remindersAsync.when(
                data: (reminders) {
                  if (reminders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No reminders set.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return Draggable<ReminderModel>(
                        data: reminder,
                        onDragStarted: () => setState(() => _isDragging = true),
                        onDragEnd: (_) => setState(() => _isDragging = false),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.tenthColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryColor),
                            ),
                            child: Text(
                              reminder.message,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildReminderCard(reminder),
                        ),
                        child: _buildReminderCard(reminder),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),

              // Delete Area
              if (_isDragging)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DragTarget<ReminderModel>(
                      onWillAccept: (data) => true,
                      onAccept: (reminder) {
                        _showDeleteConfirmation(context, reminder);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red,
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

  void _showAddReminderDialog(BuildContext context, {ReminderModel? reminder}) {
    final messageController = TextEditingController(
      text: reminder?.message ?? '',
    );
    DateTime selectedDate = reminder?.dateTime ?? DateTime.now();
    TimeOfDay selectedTime = reminder != null
        ? TimeOfDay.fromDateTime(reminder.dateTime)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.thirteenthColor,
          title: Text(
            reminder != null ? 'Edit Reminder' : 'New Reminder',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Reminder message',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedTime.format(context),
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
            ],
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
                final reminderDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (reminder != null) {
                  ref
                      .read(reminderServiceProvider)
                      .updateReminder(
                        reminder.id,
                        messageController.text,
                        reminderDateTime,
                      );
                } else {
                  ref
                      .read(reminderServiceProvider)
                      .addReminder(messageController.text, reminderDateTime);
                }
                Navigator.pop(context);
              },
              child: Text(
                reminder != null ? 'Update' : 'Save',
                style: TextStyle(color: AppColors.fifthColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
