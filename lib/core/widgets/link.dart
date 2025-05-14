import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';

class Link extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;

  const Link({super.key, required this.text, this.onTap, this.style});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: style ?? TextStyle(color: AppColors.primaryForeground, fontSize: 16.0),
      ),
    );
  }
}
