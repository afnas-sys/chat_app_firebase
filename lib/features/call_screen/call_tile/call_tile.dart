import 'package:flutter/material.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/theme.dart';

class CallTile extends StatelessWidget {
  final List<Map<String, dynamic>> datas;
  const CallTile({super.key, required this.datas});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) =>
          const Padding(padding: EdgeInsets.only(left: 80), child: Divider()),
      itemCount: datas.length,
      itemBuilder: (context, index) {
        final data = datas[index];
        return ListTile(
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
        );
      },
    );
  }
}
