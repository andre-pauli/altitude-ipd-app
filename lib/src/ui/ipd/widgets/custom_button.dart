import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final String? icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double? heightIcon;
  final TextStyle textStyle;

  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.onPressed,
    required this.width,
    required this.height,
    this.heightIcon,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? SvgPicture.asset(
                icon!,
                height: heightIcon,
              )
            : null,
        label: Text(
          label,
          style: textStyle,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          elevation: 1,
        ),
      ),
    );
  }
}
