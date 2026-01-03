// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  File? _groupImageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final file = await cloudinaryService.pickImage(ImageSource.gallery);
    if (file != null) {
      setState(() {
        _groupImageFile = file;
      });
    }
  }

  void _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }
    if (_groupImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image to Cloudinary
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      final imageUrl = await cloudinaryService.uploadFile(
        _groupImageFile!,
        folder: 'group_images',
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload group image');
      }

      // Create group with image URL
      await ref
          .read(chatServiceProvider)
          .createGroup(
            _groupNameController.text.trim(),
            _selectedUsers.keys.toList(),
            imageUrl,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userListAsync = ref.watch(usersSearchProvider);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('New Group', style: TextStyle(color: Colors.white)),
      //   backgroundColor: AppColors.primaryColor,
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
      floatingActionButton: _isUploading
          ? null
          : FloatingActionButton(
              onPressed: _createGroup,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(
                Icons.check,
                color: Colors.black,
                size: 24,
                fontWeight: FontWeight.bold,
              ),
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
          child: _isUploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryColor),
                      SizedBox(height: 16),
                      Text('Creating group...'),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Group Image Picker
                      GestureDetector(
                        onTap: _pickGroupImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor.withOpacity(0.1),
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: _groupImageFile != null
                              ? ClipOval(
                                  child: Image.file(
                                    _groupImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: AppColors.primaryColor,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _groupImageFile == null
                            ? 'Tap to select group image *'
                            : 'Tap to change image',
                        style: TextStyle(
                          color: _groupImageFile == null
                              ? AppColors.seventhColor
                              : AppColors.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Group Name Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomTextFormField(
                          controller: _groupNameController,
                          hintText: 'Group Name',
                          textColor: AppColors.primaryColor,
                          prefixWidget: const Icon(
                            Icons.group,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Users
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomTextFormField(
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
                      ),
                      const SizedBox(height: 16),

                      // Selected Members List
                      if (_selectedUsers.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selected Members',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedUsers.length,
                            itemBuilder: (context, index) {
                              final user = _selectedUsers.values.elementAt(
                                index,
                              );
                              final uid = user['uid'] ?? '';
                              final String? photoUrl =
                                  (user['photoURL'] != null &&
                                      user['photoURL'].toString().isNotEmpty)
                                  ? user['photoURL']
                                  : (user['image'] != null &&
                                        user['image'].toString().isNotEmpty)
                                  ? user['image']
                                  : null;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 35,
                                          backgroundImage:
                                              (photoUrl != null &&
                                                  photoUrl.isNotEmpty)
                                              ? (photoUrl.startsWith('http')
                                                    ? NetworkImage(photoUrl)
                                                    : AssetImage(photoUrl)
                                                          as ImageProvider)
                                              : const AssetImage(
                                                  AppImage.profile,
                                                ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            (user['displayName'] ?? 'Unknown')
                                                .split(' ')[0],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedUsers.remove(uid);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // User List
                      Expanded(
                        child: userListAsync.when(
                          data: (users) {
                            if (users.isEmpty) {
                              return const Center(
                                child: Text('No users found'),
                              );
                            }

                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final uid = user['uid'];
                                final isSelected = _selectedUsers.containsKey(
                                  uid,
                                );

                                final String? photoUrl =
                                    (user['photoURL'] != null &&
                                        user['photoURL'].toString().isNotEmpty)
                                    ? user['photoURL']
                                    : (user['image'] != null &&
                                          user['image'].toString().isNotEmpty)
                                    ? user['image']
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
                                    user['displayName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user['email'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedUsers[uid] = user;
                                        } else {
                                          _selectedUsers.remove(uid);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primaryColor,
                                    checkColor: Colors.black,
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : AppColors.primaryColor.withOpacity(
                                              0.6,
                                            ),
                                      width: 2,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUsers.remove(uid);
                                      } else {
                                        _selectedUsers[uid] = user;
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
      ),
    );
  }
}
