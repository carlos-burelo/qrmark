import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/widgets/badge.dart';
import 'package:qrmark/core/widgets/column.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Col(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: user.role.color.withAlpha(20),
              foregroundColor: user.role.color,
              child: Text(
                user.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Col(
                gap: 4,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 16),
                  ),
                  RoleBadge(role: user.role),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}


        // CircleAvatar(
        //   radius: 60,
        //   child: Text(
        //     user.fullName.substring(0, 1).toUpperCase(),
        //     style: const TextStyle(fontSize: 40),
        //   ),
        // ),
        // Col(
        //   crossAxisAlignment: CrossAxisAlignment.stretch,
        //   gap: 1,
        //   children: [
        //     Text(user.fullName, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),

        //     Text(user.email, style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 16)),
        //   ],
        // ),