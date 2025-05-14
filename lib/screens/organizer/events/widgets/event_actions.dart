import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/confirm.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/organizer/invitations/send-invitations/send_invitation_screen.dart';

class EventActions {
  final BuildContext context;
  final Event event;

  final Function() onRefresh;

  const EventActions({
    Key? key,
    required this.context,
    required this.event,

    required this.onRefresh,
  });

  Future<void> onPublish(Event event) async {
    Navigate.to(OrganizerSendInvitationsScreen.path, arguments: {'eventId': event.id});
  }

  Future<void> onDelete(Event event) async {
    final confirmed = await showConfirm(
      context,
      title: 'Eliminar evento',
      content:
          '¿Estás seguro de eliminar el evento "${event.title}"? Esta acción no se puede deshacer.',
      cancelText: 'Cancelar',
      confirmText: 'Eliminar',
    );

    if (confirmed != true) return;

    try {
      final result = await service.event.deleteEvent(event.id);
      if (!result) {
        Sonner.error('Error al eliminar el evento');
        return;
      }
      Sonner.success('Evento eliminado correctamente');
      onRefresh();
    } catch (e) {
      Sonner.error('Error: $e');
    }
  }

  void onEdit(Event event) {}

  List<Widget> build() {
    return [
      IconButton(
        icon: Icon(LucideIcons.trash2),
        tooltip: 'Eliminar',
        onPressed: () {
          onDelete(event);
        },
        color: AppColors.errorColor,
      ),
      IconButton(
        icon: const Icon(LucideIcons.squarePen),
        color: AppColors.warningColor,
        onPressed: () {
          onEdit(event);
        },
      ),
      IconButton(
        icon: const Icon(LucideIcons.ticketCheck),
        onPressed:
            event.isFinished
                ? null
                : () {
                  onPublish(event);
                },
        style: TextButton.styleFrom(foregroundColor: AppColors.successColor),
      ),
    ];
  }
}
