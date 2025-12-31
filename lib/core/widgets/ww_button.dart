import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WWButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool outlined;

  const WWButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    final filledStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(text, style: const TextStyle(color: AppColors.primaryGreen)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: filledStyle,
              child: Text(text),
            ),
    );
  }
}
