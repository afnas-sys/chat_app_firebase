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
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  final int? maxLines;
  final int? minLines;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    this.hintColor = Colors.grey,
    this.showBorder = false,
    this.height = 42,
    this.width = double.infinity,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.black,
    this.textSize = 14,
    this.padding = const EdgeInsets.all(8),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.prefixWidget,
    this.suffixWidget,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: maxLines != null && maxLines! > 1 ? null : height,
        width: width,
        child: TextFormField(
          controller: controller,
          cursorColor: AppColors.primaryColor,
          style: TextStyle(color: textColor, fontSize: textSize),
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
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
