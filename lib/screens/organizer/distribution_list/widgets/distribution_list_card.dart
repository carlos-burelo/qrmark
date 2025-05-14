import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/distribution_list.dart';
import 'package:qrmark/core/widgets/column.dart';

class DistributionListCard extends StatelessWidget {
  final DistributionList list;
  final VoidCallback onTap;
  final Widget? trailingWidget;
  final bool isLoading;
  final String? heroTag;

  const DistributionListCard({
    super.key,
    required this.list,
    required this.onTap,
    this.isLoading = false,
    this.heroTag,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: isLoading ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        leading: Hero(
          tag: heroTag ?? 'list-${list.name}',
          child: CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(20),
            radius: 30.0,
            child: Text(
              overflow: TextOverflow.ellipsis,
              list.name.isNotEmpty ? list.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
        ),
        title: Text(
          list.name,
          style: AppTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Col(
          gap: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.description != null) ...[
              Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                list.description!,
                style: AppTheme.contentStyle,
              ),
            ],
            if (list.memberCount != null) ...[
              Text(
                '${list.memberCount} miembros',
                style: AppTheme.smallContentStyle.copyWith(color: AppColors.primaryForeground),
              ),
            ],
          ],
        ),
        trailing: isLoading ? const CircularProgressIndicator() : trailingWidget,
      ),
    );
  }
}

class DistributionListCardActions {
  static Widget action({required VoidCallback onPromote, String tooltip = 'Promover a moderador'}) {
    return IconButton(
      icon: const Icon(Icons.arrow_upward, color: AppColors.successColor),
      tooltip: tooltip,
      onPressed: onPromote,
    );
  }

  static Widget checkbox({required bool value, ValueChanged<bool?>? onChanged}) {
    return Checkbox(value: value, onChanged: onChanged);
  }
}
