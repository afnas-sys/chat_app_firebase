import 'package:flutter/material.dart';
import 'package:support_chat/features/chat_screen/view/chat_screen.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/theme.dart';

class ChatTile extends StatelessWidget {
  final List<Map<String, dynamic>> datas;
  const ChatTile({super.key, required this.datas});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) =>
          const Padding(padding: EdgeInsets.only(left: 80), child: Divider()),
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
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                height: 52,
                width: 52,
                child: Image.asset(data["image"], fit: BoxFit.cover),
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
