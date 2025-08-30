import 'package:flutter/material.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final Color hintColor;
  final bool showBorder;
  final double height;
  final double width;
  final Color backgroundColor;
  final Color textColor;
  final double textSize;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;
  final Widget? prefixWidget;
  final Widget? suffixWidget;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    this.hintColor = Colors.grey,
    this.showBorder = false,
    this.height = 32,
    this.width = double.infinity,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.black,
    this.textSize = 14,
    this.padding = const EdgeInsets.all(8),
    this.contentPadding = const EdgeInsets.all(1),
    this.prefixWidget,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        width: width,
        child: TextFormField(
          cursorColor: AppColors.primaryColor,
          style: TextStyle(color: textColor, fontSize: textSize),
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundColor,
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: textSize),
            contentPadding: contentPadding,
            prefixIcon: prefixWidget,
            suffixIcon: suffixWidget,
            border: showBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  )
                : InputBorder.none,
            enabledBorder: showBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  )
                : InputBorder.none,
            focusedBorder: showBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  )
                : InputBorder.none,
            errorBorder: showBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  )
                : InputBorder.none,
          ),
        ),
      ),
    );
  }
}
