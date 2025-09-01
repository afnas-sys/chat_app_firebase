import 'package:flutter/material.dart';
import 'package:support_chat/features/chat_screen/view/chat_screen.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> datas = [
      {
        "user": "Alice",
        "image": AppImage.user1,
        "message": "Hey",
        'time': '2 min Ago',
        'msgCount': '3',
        'isOnline': 'Online',
      },
      {
        "user": "Bob",
        "image": AppImage.user2,
        "message": "How are you",
        'time': '2 min Ago',
        'msgCount': '3',
        'isOnline': 'Offline',
      },
      {
        "user": "Charlie",
        "image": AppImage.user3,
        "message": "Can we talk right now",
        'time': '2 min Ago',
        'isOnline': 'Offline',
      },
      {
        "user": "Diana",
        "image": AppImage.user4,
        "message": "10000 Received",
        'time': '2 min Ago',
        'isOnline': 'Online',
      },
      {
        "user": "Eve",
        "image": AppImage.user5,
        "message": "Are you okay",
        'time': '2 min Ago',
        'isOnline': 'Offline',
      },
      {
        "user": "Frank",
        "image": AppImage.user6,
        "message": "Congrats",
        'time': '2 min Ago',
        'isOnline': 'Online',
      },
      {
        "user": "John",
        "image": AppImage.user7,
        "message": "I will see you soon",
        'time': '2 min Ago',
        'isOnline': 'Online',
      },
      {
        "user": "Alice",
        "image": AppImage.user1,
        "message": "okay, lets see",
        'time': '2 min Ago',
        'isOnline': 'Online',
      },
      {
        "user": "Bob",
        "image": AppImage.user2,
        "message": "Thank you",
        'time': '2 min Ago',
        'isOnline': 'Online',
      },
      {
        "user": "Charlie",
        "image": AppImage.user3,
        "message": "oh",
        'time': '2 min Ago',
        'isOnline': 'Offline',
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (index) => ChatScreen(userData: data)),
            );
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
            subtitle: Text(
              data["message"],
              style: Theme.of(context).textTheme.bodySmallPrimary,
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data['time'],
                  style: Theme.of(context).textTheme.bodySmallSecondary,
                ),
                const SizedBox(height: 6),

                if (data['msgCount'] != null &&
                    data['msgCount'].toString().isNotEmpty)
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: AppColors.fifthColor,
                    ),
                    child: Center(
                      child: Text(
                        data['msgCount'],
                        style: Theme.of(context).textTheme.bodySmallPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
