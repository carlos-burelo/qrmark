import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/models/invitation.dart';
import 'package:qrmark/core/models/user.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: role.color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.RADIUS),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(color: role.color, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
    this.textColor,
    this.fontSize = 12.0,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: filled ? null : Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor ?? (color),
        ),
      ),
    );
  }
}

class EventStatusBadge extends StatelessWidget {
  final EventStatus status;
  final bool filled;
  final double fontSize;

  const EventStatusBadge({
    super.key,
    required this.status,
    this.filled = true,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      status: status.name,
      color: status.color,
      filled: filled,
      fontSize: fontSize,
    );
  }
}

class InvitationStatusBadge extends StatelessWidget {
  final InvitationStatus status;
  final bool filled;
  final double fontSize;

  const InvitationStatusBadge({
    super.key,
    required this.status,
    this.filled = true,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      status: status.name,

      color: status.color,
      filled: filled,
      fontSize: fontSize,
    );
  }
}

class CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.color = AppColors.primary,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: AppColors.foregroundColor,
        ),
      ),
    );
  }
}

class TimeBadge extends StatelessWidget {
  final DateTime datetime;
  final bool isUpcoming;
  final bool filled;

  const TimeBadge({super.key, required this.datetime, this.isUpcoming = true, this.filled = true});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = isUpcoming ? datetime.difference(now) : now.difference(datetime);

    String text;
    Color color;

    if (difference.inDays > 0) {
      text = '${difference.inDays} día${difference.inDays != 1 ? 's' : ''}';
      color = isUpcoming ? AppColors.infoColor : AppColors.primary;
    } else if (difference.inHours > 0) {
      text = '${difference.inHours} hora${difference.inHours != 1 ? 's' : ''}';
      color = isUpcoming ? AppColors.warningColor : AppColors.primary;
    } else if (difference.inMinutes > 0) {
      text = '${difference.inMinutes} min';
      color = isUpcoming ? AppColors.errorColor : AppColors.primary;
    } else {
      text = 'Ahora';
      color = AppColors.successColor;
    }

    text = isUpcoming ? 'En $text' : 'Hace $text';

    return StatusBadge(status: text, color: color, filled: filled);
  }
}

class PublishBadge extends StatelessWidget {
  final bool status;

  final Color? textColor;
  final double fontSize;
  final bool filled;

  const PublishBadge({
    super.key,
    required this.status,

    this.textColor,
    this.fontSize = 12.0,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(16.0),
        border: filled ? null : Border.all(color: AppColors.primary),
      ),
      child: Text(
        status ? 'Publicado' : 'No Publicado',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}
