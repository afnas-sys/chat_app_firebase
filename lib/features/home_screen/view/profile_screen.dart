// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_bottom_bar.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPhoto;
  bool _isUploading = false;

  ImageProvider _getImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const AssetImage(AppImage.user1);
    }
    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }
    return AssetImage(photo);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final file = await cloudinaryService.pickImage(source);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final url = await cloudinaryService.uploadFile(
          file,
          folder: 'profiles',
        );
        if (url != null) {
          setState(() {
            _selectedPhoto = url;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fourthColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.fifthColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change Profile Picture',
                    style: Theme.of(context).textTheme.titleMediumPrimary,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fourteenthColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.photo_library,
                        color: AppColors.primaryColor,
                      ),
                      title: Text(
                        'Gallery',
                        style: Theme.of(context).textTheme.bodyMediumPrimary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fourteenthColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.camera_alt,
                        color: AppColors.primaryColor,
                      ),
                      title: Text(
                        'Camera',
                        style: Theme.of(context).textTheme.bodyMediumPrimary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = ref.read(currentUserDataProvider).value;
      if (userData != null) {
        _nameController.text = userData['displayName'] ?? '';
        setState(() {
          _selectedPhoto =
              userData['photoURL'] ?? userData['image'] ?? AppImage.user1;
        });
      }
    });
  }

  final List<String> _availablePhotos = [
    AppImage.user1,
    AppImage.user2,
    AppImage.user3,
    AppImage.user4,
    AppImage.user5,
    AppImage.user6,
    AppImage.user7,
    AppImage.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: Theme.of(context).textTheme.titleLargePrimary,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomBottomBar()),
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: userDataAsync.when(
              data: (userData) {
                if (userData == null) {
                  return const Center(child: Text('User not found'));
                }

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    // Current Profile Pic with selection
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.tertiaryColor,
                            backgroundImage: _getImageProvider(_selectedPhoto),
                            child: _isUploading
                                ? CircularProgressIndicator(
                                    color: AppColors.fifthColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.fifthColor,
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 30,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fourthColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.tertiaryColor.withOpacity(0.5),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Display Name',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallPrimary,
                              ),
                              const SizedBox(height: 8),
                              CustomTextFormField(
                                controller: _nameController,
                                hintText: 'Enter your name',
                                textColor: AppColors.primaryColor,
                                backgroundColor: AppColors.tertiaryColor
                                    .withOpacity(0.1),
                                showBorder: true,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Email',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallPrimary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData['email'] ?? '',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMediumPrimary,
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Choose Avatar',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallPrimary,
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 15,
                                      crossAxisSpacing: 15,
                                    ),
                                itemCount: _availablePhotos.length,
                                itemBuilder: (context, index) {
                                  final photo = _availablePhotos[index];
                                  final isSelected = _selectedPhoto == photo;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedPhoto = photo),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.fifthColor
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: AssetImage(photo),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.fifthColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final authService = ref.read(
                                      authServiceProvider,
                                    );
                                    final success = await authService
                                        .updateUserProfile(
                                          uid: userData['uid'],
                                          displayName: _nameController.text,
                                          photoUrl: _selectedPhoto,
                                        );
                                    if (success) {
                                      ref.invalidate(currentUserDataProvider);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile updated successfully!',
                                          ),
                                        ),
                                      );
                                      // Return to the previous screen after saving
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'This name is already taken. Please choose another.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ),
    );
  }
}
