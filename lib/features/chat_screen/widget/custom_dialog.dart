import 'package:flutter/material.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_elevated_button.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String button1Text;
  final String button2Text;
  final VoidCallback button1Action;
  final VoidCallback button2Action;
  final IconData? button1Icon; // optional
  final IconData? button2Icon; // optional

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.button1Text,
    required this.button2Text,
    required this.button1Action,
    required this.button2Action,
    this.button1Icon,
    this.button2Icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 22,
          right: 22,
          top: 32,
          bottom: 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMediumSecondary,
            ),
            const SizedBox(height: 15),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMediumThird,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomElevatedButton(
                  onPressed: button1Action,
                  hasBorder: true,
                  borderColor: AppColors.fourteenthColor,
                  borderRadius: 30,
                  backgroundColor: AppColors.primaryColor,
                  height: 48,
                  width: 128,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (button1Icon != null) ...[
                        Icon(
                          button1Icon,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        button1Text,
                        style: Theme.of(context).textTheme.bodyMediumSecondary,
                      ),
                    ],
                  ),
                ),
                CustomElevatedButton(
                  onPressed: button2Action,
                  borderRadius: 30,
                  backgroundColor: AppColors.seventhColor,
                  height: 48,
                  width: 128,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (button2Icon != null) ...[
                        Icon(
                          button2Icon,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        button2Text,
                        style: Theme.of(context).textTheme.bodyMediumPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
