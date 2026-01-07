// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/glass_container.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final userId = userData['uid'];
    final isGroup = userData['isGroup'] == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isGroup ? 'Group Info' : 'Contact Info',
          style: Theme.of(context).textTheme.titleLargePrimary,
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.fifthColor),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading user data',
                    style: Theme.of(context).textTheme.bodyMediumPrimary,
                  ),
                );
              }

              // Get fresh user data from Firestore
              final freshUserData =
                  snapshot.data?.data() as Map<String, dynamic>? ?? userData;

              // Format dates
              String joinedDateStr = 'Unknown';
              if (freshUserData['createdAt'] != null) {
                final joinedDate = (freshUserData['createdAt'] is Timestamp)
                    ? (freshUserData['createdAt'] as Timestamp).toDate()
                    : (freshUserData['createdAt'] as DateTime);
                joinedDateStr = DateFormat('dd MMM yyyy').format(joinedDate);
              }

              String lastActiveStr = 'Unknown';
              if (freshUserData['isOnline'] == true ||
                  freshUserData['isOnline'] == 'Online') {
                lastActiveStr = 'Online now';
              } else if (freshUserData['lastSeen'] != null) {
                final lastSeen = (freshUserData['lastSeen'] is Timestamp)
                    ? (freshUserData['lastSeen'] as Timestamp).toDate()
                    : (freshUserData['lastSeen'] as DateTime);
                lastActiveStr = DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(lastSeen);
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Hero Profile Image
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.fifthColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: AppColors.tertiaryColor,
                          backgroundImage: _getImageProvider(
                            freshUserData['photoURL'] ?? freshUserData['image'],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      freshUserData['displayName'] ??
                          freshUserData['user'] ??
                          'User',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGroup ? 'Group' : (freshUserData['email'] ?? ''),
                      style: Theme.of(context).textTheme.bodyMediumFourth,
                    ),
                    const SizedBox(height: 30),

                    // Details Section
                    GlassContainer(
                      child: Column(
                        children: [
                          _buildDetailItem(
                            context,
                            icon: Icons.info_outline,
                            label: 'About',
                            value:
                                freshUserData['about'] ??
                                'Hey there! I am using Support Chat.',
                          ),
                          const Divider(color: Colors.white10),
                          _buildDetailItem(
                            context,
                            icon: Icons.phone_android,
                            label: 'Mobile Number',
                            value:
                                freshUserData['phoneNumber'] ??
                                freshUserData['mobile'] ??
                                'Not Available',
                          ),
                          const Divider(color: Colors.white10),
                          _buildDetailItem(
                            context,
                            icon: Icons.business_center_outlined,
                            label: 'Business Info',
                            value:
                                freshUserData['businessInfo'] ??
                                'No business info shared.',
                          ),
                          const Divider(color: Colors.white10),
                          _buildDetailItem(
                            context,
                            icon: Icons.calendar_today_outlined,
                            label: 'Joined Date',
                            value: joinedDateStr,
                          ),
                          const Divider(color: Colors.white10),
                          _buildDetailItem(
                            context,
                            icon: Icons.access_time,
                            label: 'Last Active',
                            value: lastActiveStr,
                          ),
                          const Divider(color: Colors.white10),
                          _buildDetailItem(
                            context,
                            icon: Icons.fingerprint,
                            label: 'User ID',
                            value: freshUserData['uid'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.fifthColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.fifthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const AssetImage(AppImage.user1);
    }

    final photoStr = photo.toString();

    if (photoStr.startsWith('http')) {
      return NetworkImage(photoStr);
    }

    // Safety: strip file:/// if present in asset path strings
    final assetPath = photoStr.startsWith('file:///')
        ? photoStr.replaceFirst('file:///', '')
        : photoStr;

    return AssetImage(assetPath);
  }
}
