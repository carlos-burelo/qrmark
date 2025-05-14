import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/invitation.dart';
import 'package:qrmark/core/widgets/column.dart';

class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? heroTag;
  final bool showActions;

  const InvitationCard({
    super.key,
    required this.invitation,
    this.trailingWidget,
    this.onTap,
    this.isLoading = false,
    this.heroTag,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final String effectiveHeroTag = heroTag ?? 'invitation-${invitation.id}';
    return Card(
      child: InkWell(
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          onTap: isLoading ? null : onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          leading: Hero(
            tag: effectiveHeroTag,
            child: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(20),
              radius: 30.0,
              child: Icon(LucideIcons.mailOpen, color: AppColors.primary, size: 30.0),
            ),
          ),
          title: Col(
            gap: 0,
            children: [
              Text(
                invitation.event!.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(invitation.event!.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (showActions) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MaterialButton(
                      onPressed: () => {},
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: const Text('Aceptar'),
                      color: AppColors.successColor,
                    ),
                    const SizedBox(width: 8.0),
                    MaterialButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      onPressed: () => {},
                      child: const Text('Rechazar'),
                      color: AppColors.errorColor,
                    ),
                  ],
                ),
              ],
            ],
          ),
          // subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          //   ],
          // ),
          trailing: isLoading ? const CircularProgressIndicator() : trailingWidget,
        ),
      ),
    );
  }
}

class InvitationActions {
  static Widget viewDetails({required VoidCallback? onTap, String tooltip = 'Ver detalles'}) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowBigRightDash, color: AppColors.primary),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }

  static Widget checkbox({required bool isChecked, VoidCallback? onTap}) {
    return Checkbox(
      value: isChecked,
      onChanged: (value) {
        if (onTap != null) {
          onTap();
        }
      },
      activeColor: AppColors.primary,
      checkColor: Colors.white,
    );
  }
}
