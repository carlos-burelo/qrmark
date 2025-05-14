import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/screens/auth/profile/profile_screen.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double height;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.height = kToolbarHeight + 10,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      bottom: bottom,
      actions:
          actions ??
          [
            GestureDetector(
              onTap: () {
                Navigate.to(ProfileScreen.path);
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Async(
                  builder:
                      (ctx, text) => Text(
                        text.fullName.isEmpty ? '?' : text.fullName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20, color: AppColors.primary),
                      ),
                  wait: service.user.getCurrentUser,
                ),
              ),
            ),
            SizedBox(width: 10),
          ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
