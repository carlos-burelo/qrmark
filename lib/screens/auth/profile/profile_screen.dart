import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/screens/auth/login/login_screen.dart';
import 'package:qrmark/screens/auth/profile/widgets/profile_card.dart';
import 'package:qrmark/screens/auth/profile/widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  static const String path = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(
        title: 'Perfil',
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await service.auth.logout();
              Navigate.to(LoginScreen.path);
            },
          ),
        ],
      ),
      body: Async(
        wait: service.user.getCurrentUser,
        builder: (c, user) {
          return Col(
            gap: 10,
            children: [
              ProfileHeader(user: user),
              Text('Información de la cuenta', style: AppTheme.subtitleStyle),
              ProfileCard(user: user),
            ],
          );
        },
      ),
    );
  }
}
