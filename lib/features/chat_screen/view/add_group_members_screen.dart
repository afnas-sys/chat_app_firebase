import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class AddGroupMembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> existingMemberIds;

  const AddGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.existingMemberIds,
  });

  @override
  ConsumerState<AddGroupMembersScreen> createState() =>
      _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends ConsumerState<AddGroupMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMembers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await ref
          .read(chatServiceProvider)
          .addMembersToGroup(widget.groupId, _selectedUserIds.toList());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding members: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userListAsync = ref.watch(usersSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Members to ${widget.groupName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: _isAdding
          ? null
          : FloatingActionButton(
              onPressed: _addMembers,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.person_add, color: Colors.white),
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
        child: _isAdding
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16),
                    Text('Adding members...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Users
                    CustomTextFormField(
                      controller: _searchController,
                      hintText: 'Search Users',
                      textColor: AppColors.primaryColor,
                      prefixWidget: const Icon(
                        Icons.search,
                        color: AppColors.primaryColor,
                      ),
                      onChanged: (value) {
                        ref.read(chatSearchProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 16),

                    // User List
                    Expanded(
                      child: userListAsync.when(
                        data: (users) {
                          // Filter out existing members
                          final availableUsers = users
                              .where(
                                (user) => !widget.existingMemberIds.contains(
                                  user['uid'],
                                ),
                              )
                              .toList();

                          if (availableUsers.isEmpty) {
                            return const Center(
                              child: Text('No new users to add'),
                            );
                          }

                          return ListView.builder(
                            itemCount: availableUsers.length,
                            itemBuilder: (context, index) {
                              final user = availableUsers[index];
                              final uid = user['uid'];
                              final isSelected = _selectedUserIds.contains(uid);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    user['photoURL'] ??
                                        user['image'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                ),
                                title: Text(
                                  user['displayName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(user['email'] ?? ''),
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
                                  activeColor: AppColors.primaryColor,
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
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
