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
    // Format dates
    String joinedDateStr = 'Unknown';
    if (userData['createdAt'] != null) {
      final joinedDate = (userData['createdAt'] is Timestamp)
          ? (userData['createdAt'] as Timestamp).toDate()
          : (userData['createdAt'] as DateTime);
      joinedDateStr = DateFormat('dd MMM yyyy').format(joinedDate);
    }

    String lastActiveStr = 'Unknown';
    if (userData['isOnline'] == true || userData['isOnline'] == 'Online') {
      lastActiveStr = 'Online now';
    } else if (userData['lastSeen'] != null) {
      final lastSeen = (userData['lastSeen'] is Timestamp)
          ? (userData['lastSeen'] as Timestamp).toDate()
          : (userData['lastSeen'] as DateTime);
      lastActiveStr = DateFormat('dd MMM yyyy, hh:mm a').format(lastSeen);
    }

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
          child: SingleChildScrollView(
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
                        userData['photoURL'] ?? userData['image'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  userData['displayName'] ?? userData['user'] ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGroup ? 'Group' : (userData['email'] ?? ''),
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
                            userData['about'] ??
                            'Hey there! I am using Support Chat.',
                      ),
                      const Divider(color: Colors.white10),
                      _buildDetailItem(
                        context,
                        icon: Icons.phone_android,
                        label: 'Mobile Number',
                        value:
                            userData['phoneNumber'] ??
                            userData['mobile'] ??
                            'Not Available',
                      ),
                      const Divider(color: Colors.white10),
                      _buildDetailItem(
                        context,
                        icon: Icons.business_center_outlined,
                        label: 'Business Info',
                        value:
                            userData['businessInfo'] ??
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
                        value: userData['uid'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }
    return AssetImage(photo);
  }
}
