import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/status_screen/repository/status_repository.dart';
import 'package:support_chat/models/status_model.dart';
import 'package:support_chat/services/auth_service.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:support_chat/services/chat_service.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

final statusControllerProvider = Provider((ref) {
  final statusRepository = ref.watch(statusRepositoryProvider);
  final cloudinaryService = ref.watch(cloudinaryServiceProvider);
  final chatService = ref.watch(chatServiceProvider);
  return StatusController(
    statusRepository: statusRepository,
    cloudinaryService: cloudinaryService,
    chatService: chatService,
    ref: ref,
  );
});

final statusStreamProvider = StreamProvider((ref) {
  final statusController = ref.watch(statusControllerProvider);
  return statusController.getStatuses();
});

class StatusController {
  final StatusRepository statusRepository;
  final CloudinaryService cloudinaryService;
  final ChatService chatService;
  final Ref ref;

  StatusController({
    required this.statusRepository,
    required this.cloudinaryService,
    required this.chatService,
    required this.ref,
  });

  Future<void> addStatus(
    BuildContext context,
    File file,
    String caption,
  ) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      final userData = await AuthService().getUserData(user.uid);
      String username = userData?['displayName'] ?? 'User';
      String profilePic = userData?['photoURL'] ?? '';
      String phoneNumber = userData?['phoneNumber'] ?? '';

      // Upload image
      String? imageUrl = await cloudinaryService.uploadFile(
        file,
        folder: 'status',
      );

      if (imageUrl != null) {
        await statusRepository.uploadStatus(
          username: username,
          profilePic: profilePic,
          phoneNumber: phoneNumber,
          imageUrl: imageUrl,
          caption: caption,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Stream<List<Status>> getStatuses() {
    return statusRepository.getStatuses();
  }

  Future<void> markStatusSeen(String statusId) async {
    await statusRepository.markStatusSeen(statusId);
  }

  Future<void> deleteStatus(BuildContext context, String statusId) async {
    try {
      await statusRepository.deleteStatus(statusId);
      if (context.mounted) {
        Navigator.pop(context); // Close the view screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> reactToStatus(String statusId, String reaction) async {
    await statusRepository.reactToStatus(statusId, reaction);
  }

  Future<void> sendReply({
    required BuildContext context,
    required String receiverId,
    required String text,
    required String statusImageUrl,
  }) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      final userData = await AuthService().getUserData(user.uid);

      final chatUser = ChatUser(
        id: user.uid,
        firstName: userData?['displayName'] ?? 'User',
        profileImage: userData?['photoURL'] ?? userData?['image'] ?? '',
      );

      final message = ChatMessage(
        text: "Status Reply: $text",
        user: chatUser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: statusImageUrl,
            fileName: 'status_reply.jpg',
            type: MediaType.image,
          ),
        ],
      );

      await chatService.sendMessage(receiverId, message);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reply sent!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
