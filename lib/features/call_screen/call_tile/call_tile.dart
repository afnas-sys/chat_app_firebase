import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

class CallTile extends StatelessWidget {
  const CallTile({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> datas = [
      {
        "user": "Alice",
        "image": AppImage.user1,
        'icon': Icons.arrow_outward,
        "date": "30 Aug 2025, 10:15 AM",
        'status': '12m 45s',
      },
      {
        "user": "Bob",
        "image": AppImage.user2,
        'icon': Icons.subdirectory_arrow_left_rounded,
        "date": "30 Aug 2025, 10:15 AM",
        'status': 'Missed',
      },
      {
        "user": "Charlie",
        "image": AppImage.user3,
        'icon': Icons.arrow_outward,
        "date": "30 Aug 2025, 10:15 AM",
        'status': 'Missed',
      },
      {
        "user": "Diana",
        "image": AppImage.user4,
        'icon': Icons.arrow_outward,
        "date": "30 Aug 2025, 10:15 AM",
        'status': 'Missed',
      },
      {
        "user": "Eve",
        "image": AppImage.user5,
        'icon': Icons.arrow_outward,
        "date": "30 Aug 2025, 10:15 AM",
        'status': 'Missed',
      },
      {
        "user": "Frank",
        "image": AppImage.user6,
        'icon': Icons.subdirectory_arrow_left_rounded,
        "date": "30 Aug 2025, 10:15 AM",
        'status': 'Missed',
      },
    ];
    return ListView.separated(
      separatorBuilder: (index, context) => Padding(
        padding: const EdgeInsets.only(left: 80),
        child: const Divider(),
      ),
      itemCount: datas.length,
      itemBuilder: (context, index) {
        final data = datas[index];
        return InkWell(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (index) => ChatScreen(userData: data)),
            // );
          },
          child: ListTile(
            leading: ClipRRect(
              child: SizedBox(
                height: 52,
                width: 52,
                child: Image.asset(
                  data["image"],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              data["user"],
              style: Theme.of(context).textTheme.titleMediumPrimary,
            ),
            subtitle: Row(
              children: [
                Icon(data['icon'], size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  data["date"],
                  style: Theme.of(context).textTheme.bodySmallSecondary,
                ),
              ],
            ),
            trailing: Text(
              data['status'],
              style: Theme.of(context).textTheme.bodySmallPrimary,
            ),
          ),
        );
      },
    );
  }
}
