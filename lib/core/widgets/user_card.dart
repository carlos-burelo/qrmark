import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? heroTag;
  const UserCard({
    super.key,
    required this.user,
    this.trailingWidget,
    this.onTap,
    this.isLoading = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role;
    final name = user.fullName;
    final email = user.email;
    final String effectiveHeroTag = heroTag ?? 'avatar-$email';

    return Card(
      child: ListTile(
        onTap: isLoading ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        leading: Hero(
          tag: effectiveHeroTag,
          child: CircleAvatar(
            backgroundColor: role.color.withAlpha(20),
            radius: 30.0,
            child: Text(
              overflow: TextOverflow.ellipsis,
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: role.color, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: role.color.withAlpha(20),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(role.displayName, style: TextStyle(fontSize: 12.0, color: role.color)),
            ),
          ],
        ),
        trailing: isLoading ? const CircularProgressIndicator() : trailingWidget,
      ),
    );
  }
}

class UserCardActions {
  static Widget promoteButton({
    required User user,
    required VoidCallback onPromote,
    String tooltip = 'Promover a moderador',
  }) {
    final isMod = user.role == UserRole.moderator;
    final icon = isMod ? LucideIcons.shieldOff : LucideIcons.shieldPlus;
    final color = isMod ? AppColors.errorColor : AppColors.successColor;
    final tooltip = isMod ? 'Despromover usuario' : 'Promover a moderador';

    return IconButton(icon: Icon(icon, color: color), tooltip: tooltip, onPressed: onPromote);
  }

  static Widget checkbox({required bool value, ValueChanged<bool?>? onChanged}) {
    return Checkbox(value: value, onChanged: onChanged);
  }
}
