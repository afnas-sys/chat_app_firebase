import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/reminder_model.dart';
import 'package:support_chat/services/reminder_service.dart';

final reminderServiceProvider = Provider((ref) => ReminderService());

final remindersStreamProvider = StreamProvider<List<ReminderModel>>((ref) {
  return ref.watch(reminderServiceProvider).getReminders();
});

final activeRemindersStreamProvider = StreamProvider<List<ReminderModel>>((
  ref,
) {
  return ref.watch(reminderServiceProvider).getActiveReminders();
});
