import 'package:flutter/material.dart';
import 'package:qrmark/core/models/event.dart';

class EventMenu extends StatelessWidget {
  final Event? event;
  final Function onEdit;
  final Function onDelete;
  final Function onSend;
  final Function onPublish;

  const EventMenu({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onSend,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder:
          (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar evento')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar evento')),
            PopupMenuItem(
              value: 'send',
              enabled: event?.isFinished ?? false,
              child: Text('Enviar invitaciones'),
            ),
            PopupMenuItem(
              value: 'publish',
              enabled: event?.isFinished ?? false,
              child: Text('Publicar evento'),
            ),
          ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
          case 'send':
            onSend();
            break;
          case 'publish':
            onPublish();
            break;
        }
      },
    );
  }
}
