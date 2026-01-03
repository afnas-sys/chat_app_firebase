// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveGroupMembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> existingMemberIds;

  const RemoveGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.existingMemberIds,
  });

  @override
  ConsumerState<RemoveGroupMembersScreen> createState() =>
      _RemoveGroupMembersScreenState();
}

class _RemoveGroupMembersScreenState
    extends ConsumerState<RemoveGroupMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isRemoving = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _removeMembers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() {
      _isRemoving = true;
    });

    try {
      await ref
          .read(chatServiceProvider)
          .removeMembersFromGroup(widget.groupId, _selectedUserIds.toList());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing members: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isRemoving
          ? null
          : FloatingActionButton(
              onPressed: _removeMembers,
              backgroundColor: AppColors.seventhColor,
              child: const Icon(Icons.person_remove, color: Colors.white),
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
          child: _isRemoving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryColor),
                      SizedBox(height: 16),
                      Text('Removing members...'),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Remove Members from ${widget.groupName}',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Users
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primaryColor.withOpacity(0.1),
                        ),
                        child: CustomTextFormField(
                          controller: _searchController,
                          hintText: 'Search Members',
                          textColor: AppColors.primaryColor,
                          prefixWidget: const Icon(
                            Icons.search,
                            color: AppColors.primaryColor,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Member List
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getMembersStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final members = snapshot.data ?? [];

                            // Filter members based on search query
                            final filteredMembers = members.where((member) {
                              final displayName = (member['displayName'] ?? '')
                                  .toLowerCase();
                              final email = (member['email'] ?? '')
                                  .toLowerCase();
                              return displayName.contains(_searchQuery) ||
                                  email.contains(_searchQuery);
                            }).toList();

                            if (filteredMembers.isEmpty) {
                              return const Center(
                                child: Text('No members to remove'),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                final member = filteredMembers[index];
                                final uid = member['uid'];
                                final isSelected = _selectedUserIds.contains(
                                  uid,
                                );

                                final String? photoUrl =
                                    (member['photoURL'] != null &&
                                        member['photoURL']
                                            .toString()
                                            .isNotEmpty)
                                    ? member['photoURL']
                                    : (member['image'] != null &&
                                          member['image'].toString().isNotEmpty)
                                    ? member['image']
                                    : null;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        (photoUrl != null &&
                                            photoUrl.isNotEmpty)
                                        ? (photoUrl.startsWith('http')
                                              ? NetworkImage(photoUrl)
                                              : AssetImage(photoUrl)
                                                    as ImageProvider)
                                        : const AssetImage(AppImage.profile),
                                  ),
                                  title: Text(
                                    member['displayName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    member['email'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedUserIds.add(uid);
                                        } else {
                                          _selectedUserIds.remove(uid);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.seventhColor,
                                    checkColor: Colors.black,
                                    side: isSelected
                                        ? BorderSide(
                                            color: AppColors.seventhColor,
                                          )
                                        : BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUserIds.remove(uid);
                                      } else {
                                        _selectedUserIds.add(uid);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getMembersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: widget.existingMemberIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'uid': doc.id, ...doc.data()};
          }).toList();
        });
  }
}
