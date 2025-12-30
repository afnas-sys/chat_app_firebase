import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
