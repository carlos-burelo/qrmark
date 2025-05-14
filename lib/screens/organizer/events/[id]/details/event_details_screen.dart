import 'package:flutter/material.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/utils/date.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/badge.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/confirm.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/organizer/events/%5Bid%5D/details/widgets/event_main_info.dart';
import 'package:qrmark/screens/organizer/events/%5Bid%5D/details/widgets/event_menu.dart';
import 'package:qrmark/screens/organizer/events/%5Bid%5D/details/widgets/event_stats_info.dart';

class OrganizerEventDetailsScreen extends StatefulWidget {
  static const String path = '/organizer/events/:id/details';

  final int eventId;

  const OrganizerEventDetailsScreen({super.key, required this.eventId});

  @override
  State<OrganizerEventDetailsScreen> createState() => _OrganizerEventDetailsScreenState();
}

class _OrganizerEventDetailsScreenState extends State<OrganizerEventDetailsScreen> {
  Event? _event;

  Future<Event> _loadEventDetails() async {
    final event = await service.event.getEventById(widget.eventId);
    return event;
  }

  Future<void> _publishEvent() async {
    if (_event == null || _event!.isPublished) return;
    final confirmed = await showConfirm(
      context,
      title: 'Publicar evento',
      content:
          '¿Estás seguro de publicar el evento "${_event!.title}"? Los asistentes podrán verlo.',
      confirmText: 'Publicar',
      cancelText: 'Cancelar',
    );

    if (confirmed != true) return;

    try {
      final success = await service.event.publishEvent(_event!.id);

      if (success) {
        Sonner.success('Evento publicado correctamente');
      } else {
        Sonner.error('Error al publicar el evento');
      }
    } catch (e) {
      Sonner.error('Error: $e');
    }
  }

  Future<void> _deleteEvent() async {
    if (_event == null) return;
    final confirmed = await showConfirm(
      context,
      title: 'Eliminar evento',
      content:
          '¿Estás seguro de eliminar el evento "${_event!.title}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    );

    if (confirmed != true) return;

    try {
      final success = await service.event.deleteEvent(_event!.id);

      if (success) {
        Sonner.success('Evento eliminado correctamente');

        Navigator.pop(context);
      } else {
        throw Exception('Error al eliminar evento');
      }
    } catch (e) {
      Sonner.error('Error: $e');
    }
  }

  void _sendInvitations() {
    Navigate.to('', arguments: _event!.id);
  }

  void _editEvent() {
    Navigate.to('', arguments: _event!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      scrollable: true,
      appBar: AppBarWidget(
        title: 'Detalles del evento',
        actions: [
          EventMenu(
            event: _event,
            onEdit: _editEvent,
            onDelete: _deleteEvent,
            onSend: _sendInvitations,
            onPublish: _publishEvent,
          ),
        ],
      ),
      body: Async(
        wait: _loadEventDetails,
        builder: (ctx, event) {
          return Col(
            children: [
              Row(
                children: [
                  PublishBadge(status: event.isPublished),
                  const Spacer(),
                  Text(DateTimeFmt.date(event.startTime), style: const TextStyle(fontSize: 14.0)),
                ],
              ),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),

              Text(
                event.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.0),
              ),
              EventMainInfo(event: event),
              EventStatsInfo(event: event),
            ],
          );
        },
      ),
      bottomNavigationBar: ElevatedButton.icon(
        onPressed: _publishEvent,
        icon: const Icon(Icons.publish),
        label: const Text('Publicar evento'),
      ),
    );
  }
}
