import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(10),
      child: Icon(Icons.qr_code_rounded, size: 150, color: AppColors.foregroundColor),
    );
  }
}
