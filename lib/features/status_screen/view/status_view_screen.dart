// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/status_screen/controller/status_controller.dart';
import 'package:support_chat/models/status_model.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/services/auth_service.dart';

class StatusViewScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> statusCollections;
  final int initialCollectionIndex;
  final int initialStatusIndex;

  const StatusViewScreen({
    super.key,
    required this.statusCollections,
    this.initialCollectionIndex = 0,
    this.initialStatusIndex = 0,
  });

  @override
  ConsumerState<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends ConsumerState<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _currentCollectionIndex;
  late int _currentIndex;
  final AuthService _authService = AuthService();
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentCollectionIndex = widget.initialCollectionIndex;
    _currentIndex = widget.initialStatusIndex;
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStatus();
            }
          });

    _startCurrentStatus();
  }

  void _startCurrentStatus() {
    _animationController.stop();
    _animationController.reset();
    _animationController.forward();

    final currentCollection = widget.statusCollections[_currentCollectionIndex];
    final statuses = currentCollection['statuses'] as List<Status>;
    final currentStatus = statuses[_currentIndex];

    // Mark as seen if it's not my own status
    if (currentStatus.uid != _authService.currentUser?.uid) {
      ref.read(statusControllerProvider).markStatusSeen(currentStatus.statusId);
    }
  }

  void _nextStatus() {
    final currentCollection = widget.statusCollections[_currentCollectionIndex];
    final statuses = currentCollection['statuses'] as List<Status>;

    if (_currentIndex < statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startCurrentStatus();
    } else {
      // End of this collection, check if there's a next collection
      if (_currentCollectionIndex < widget.statusCollections.length - 1) {
        setState(() {
          _currentCollectionIndex++;
          _currentIndex = 0;
        });
        _startCurrentStatus();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startCurrentStatus();
    } else {
      // Beginning of this collection, check if there's a previous collection
      if (_currentCollectionIndex > 0) {
        setState(() {
          _currentCollectionIndex--;
          final prevCollection =
              widget.statusCollections[_currentCollectionIndex];
          final prevStatuses = prevCollection['statuses'] as List<Status>;
          _currentIndex = prevStatuses.length - 1;
        });
        _startCurrentStatus();
      } else {
        // Restart current
        _startCurrentStatus();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply(String text, Status status) {
    ref
        .read(statusControllerProvider)
        .sendReply(
          context: context,
          receiverId: status.uid,
          text: text,
          statusImageUrl: status.imageUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (widget.statusCollections.isEmpty ||
        _currentCollectionIndex >= widget.statusCollections.length) {
      return const SizedBox();
    }

    final currentCollection = widget.statusCollections[_currentCollectionIndex];
    final statuses = currentCollection['statuses'] as List<Status>;

    if (statuses.isEmpty || _currentIndex >= statuses.length) {
      return const SizedBox();
    }

    final currentStatus = statuses[_currentIndex];
    final bool isMe = currentStatus.uid == _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width / 3) {
              _prevStatus();
            } else {
              _nextStatus();
            }
          },
          onLongPressStart: (_) => _animationController.stop(),
          onLongPressEnd: (_) => _animationController.forward(),
          child: Stack(
            children: [
              // Status Image
              Center(
                child: Image.network(
                  currentStatus.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  },
                ),
              ),

              // Progress Indicators
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(statuses.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            double value = 0.0;
                            if (index < _currentIndex) {
                              value = 1.0;
                            } else if (index == _currentIndex) {
                              value = _animationController.value;
                            }
                            return LinearProgressIndicator(
                              value: value,
                              color: Colors.white,
                              backgroundColor: Colors.grey.withOpacity(0.5),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Top Bar
              Positioned(
                top: 25,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _authService.getUserData(currentStatus.uid),
                      builder: (context, snapshot) {
                        String? profilePicUrl = currentStatus.profilePic;
                        if (snapshot.hasData && snapshot.data != null) {
                          var data = snapshot.data!;
                          if (data['photoURL'] != null &&
                              data['photoURL'].toString().isNotEmpty) {
                            profilePicUrl = data['photoURL'];
                          } else if (data['image'] != null &&
                              data['image'].toString().isNotEmpty) {
                            profilePicUrl = data['image'];
                          }
                        }

                        ImageProvider? backgroundImage;
                        if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
                          if (profilePicUrl.startsWith('http')) {
                            backgroundImage = NetworkImage(profilePicUrl);
                          } else {
                            backgroundImage = AssetImage(profilePicUrl);
                          }
                        } else {
                          backgroundImage = const AssetImage(AppImage.profile);
                        }

                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: backgroundImage,
                          onBackgroundImageError: (_, __) {
                            // Fallback handled if needed, or it just shows nothing?
                            // CircleAvatar doesn't have a simple fallback for failed network image
                            // without extra complexity.
                            // But usually NetworkImage failure just shows background color.
                            // We can use a child with Icon as fallback if we want.
                          },
                          // If we want a strictly robust fallback for *failed* loading,
                          // we might need ClipOval + Image.network(errorBuilder...).
                          // But CircleAvatar+NetworkImage is standard here.
                          // 'child' is shown if backgroundImage fails? No, child is foreground.
                          // Let's stick to the logic we used elsewhere which is just the backgroundImage.
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStatus.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTime(currentStatus.timestamp),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Caption
              if (currentStatus.caption.isNotEmpty)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      currentStatus.caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

              // Current Reactions display
              if (currentStatus.reactions.isNotEmpty)
                Positioned(
                  bottom: isMe ? 60 : 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      if (isMe) _showReactionsList(currentStatus.reactions);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...currentStatus.reactions.values
                              .toSet()
                              .take(3)
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(
                                    e.toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                          Text(
                            ' ${currentStatus.reactions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Reactions Bar - Only for others
              if (!isMe)
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _reactionIcon('❤️', currentStatus),
                        _reactionIcon('😂', currentStatus),
                        _reactionIcon('😮', currentStatus),
                        _reactionIcon('😢', currentStatus),
                        _reactionIcon('🙏', currentStatus),
                        _reactionIcon('👍', currentStatus),
                      ],
                    ),
                  ),
                ),

              // Reply Field - Only for others
              if (!isMe)
                Positioned(
                  bottom: 20,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white),
                            onTap: () => _animationController.stop(),
                            onSubmitted: (val) {
                              if (val.isNotEmpty) {
                                _sendReply(val, currentStatus);
                                _replyController.clear();
                              }
                              _animationController.forward();
                              FocusScope.of(context).unfocus();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Reply...',
                              hintStyle: TextStyle(color: Colors.white60),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.black),
                          onPressed: () {
                            if (_replyController.text.isNotEmpty) {
                              _sendReply(_replyController.text, currentStatus);
                              _replyController.clear();
                              _animationController.forward();
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Alert (Viewers) - Only for Owner
              if (isMe)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        _showViewersList();
                      }
                    },
                    onTap: _showViewersList,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                        ),
                        Text(
                          '${currentStatus.viewers.length} views',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reactionIcon(String emoji, Status status) {
    return GestureDetector(
      onTap: () {
        ref
            .read(statusControllerProvider)
            .reactToStatus(status.statusId, emoji);
        _sendReply(emoji, status);
      },
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  void _showReactionsList(Map<String, dynamic> reactions) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reactions (${reactions.length})',
                style: Theme.of(context).textTheme.titleSmallSecondary,
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: reactions.length,
                  itemBuilder: (context, index) {
                    String uid = reactions.keys.elementAt(index);
                    String emoji = reactions[uid];
                    return FutureBuilder(
                      future: AuthService().getUserData(uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        var user = snapshot.data as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['photoURL'] != null
                                ? NetworkImage(user['photoURL'])
                                : const AssetImage(AppImage.profile)
                                      as ImageProvider,
                          ),
                          title: Text(
                            user['displayName'] ?? 'User',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmallSecondary,
                          ),
                          trailing: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _animationController.forward());
  }

  void _showViewersList() {
    // Pause animation when showing bottom sheet
    _animationController.stop();

    final currentCollection = widget.statusCollections[_currentCollectionIndex];
    final statuses = currentCollection['statuses'] as List<Status>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Viewed by ${statuses[_currentIndex].viewers.length}',
                style: Theme.of(context).textTheme.titleSmallSecondary,
              ),
              const Divider(),
              Expanded(
                child: statuses[_currentIndex].viewers.isEmpty
                    ? const Center(child: Text('No views yet'))
                    : ListView.builder(
                        itemCount: statuses[_currentIndex].viewers.length,
                        itemBuilder: (context, index) {
                          // In a real app, we would fetch user details from these UIDs
                          // For now, we'll just show the UID (or FutureBuilder if we had a method)
                          // Since requirements say "show a bottom alert for which users seen their story"
                          // We will just fetch details properly if possible.
                          // But we don't have a batch fetch user method handy in AuthService yet?
                          // We have getUserData(uid).

                          // To keep it simple given the constraints, let's use a FutureBuilder per item or just show minimal info.
                          // Ideally we should update the Status model to include basic viewer info or fetch it.
                          // Let's use FutureBuilder.
                          var viewerData =
                              statuses[_currentIndex].viewers[index];
                          // Since Status model enforces List<Map<String, dynamic>>, we don't need to check for String
                          String viewerUid = viewerData['uid'];
                          int? viewerTimestamp = viewerData['timestamp'];

                          return FutureBuilder(
                            future: AuthService().getUserData(viewerUid),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              var user = snapshot.data as Map<String, dynamic>;
                              final String? photoUrl =
                                  (user['photoURL'] != null &&
                                      user['photoURL'].toString().isNotEmpty)
                                  ? user['photoURL']
                                  : (user['image'] != null &&
                                        user['image'].toString().isNotEmpty)
                                  ? user['image']
                                  : null;

                              String? timeString;
                              if (viewerTimestamp != null) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                  viewerTimestamp,
                                );
                                timeString =
                                    "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      (photoUrl != null && photoUrl.isNotEmpty)
                                      ? (photoUrl.startsWith('http')
                                            ? NetworkImage(photoUrl)
                                            : AssetImage(photoUrl)
                                                  as ImageProvider)
                                      : const AssetImage(AppImage.profile),
                                ),
                                title: Text(
                                  user['displayName'] ?? 'User',
                                  style: TextStyle(
                                    color: AppColors.eighthColor,
                                  ),
                                ),
                                subtitle: timeString != null
                                    ? Text(
                                        timeString,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Resume animation when bottom sheet closes
      _animationController.forward();
    });
  }

  String _formatTime(DateTime time) {
    // Simple formatter
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
