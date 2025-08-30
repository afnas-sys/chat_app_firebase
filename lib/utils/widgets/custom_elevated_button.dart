import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class CustomElevatedButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final Widget? icon;
  final double? width;
  final double? height;
  final Color borderColor;
  final bool hasBorder;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double? elevation;

  const CustomElevatedButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.icon,
    this.width,
    this.height,
    this.borderColor = AppColors.primaryColor,
    this.hasBorder = true,
    this.textColor = AppColors.primaryColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.elevation,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    Widget content =
        child ??
        Text(
          text!,
          style: GoogleFonts.roboto(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: hasBorder ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          padding: padding,
          elevation: elevation ?? 0,
        ),
        onPressed: onPressed,
        child: icon == null
            ? content
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [icon!, const SizedBox(width: 8), content],
              ),
      ),
    );
  }
}
