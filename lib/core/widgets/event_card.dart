import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/utils/date.dart';
import 'package:qrmark/core/widgets/badge.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool showStatus;
  final bool showOrganizer;
  final String? organizerName;
  final bool compact;
  final List<Widget>? actions;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showStatus = true,
    this.showOrganizer = false,
    this.organizerName,
    this.compact = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventHeader(
                event: event,
                showStatus: showStatus,
                compact: compact,
                showOrganizer: showOrganizer,
                organizerName: organizerName,
              ),
              const SizedBox(height: 12.0),
              EventDateTimeInfo(startTime: event.startTime, endTime: event.endTime),
              if (!compact) ...[
                const SizedBox(height: 8.0),
                _EventLocationInfo(location: event.location?.name),
              ],
              if (!compact) ...[
                const SizedBox(height: 12.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EventTimeBadge(event: event),
                    if (actions != null && actions!.isNotEmpty) ...[
                      const SizedBox(height: 12.0),
                      _ActionButtons(actions: actions!),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EventHeader extends StatelessWidget {
  final Event event;
  final bool showStatus;
  final bool compact;
  final bool showOrganizer;
  final String? organizerName;

  const EventHeader({
    super.key,
    required this.event,
    required this.showStatus,
    required this.compact,
    required this.showOrganizer,
    this.organizerName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStatus)
                StatusBadge(
                  status: event.isPublished ? 'Publicado' : 'No Publicado',
                  color: event.status.color,
                ),
              const SizedBox(height: 4.0),
              EventTitle(title: event.title, compact: compact),
              if (!compact) ...[
                const SizedBox(height: 4.0),
                EventDescription(description: event.description),
              ],
              const SizedBox(height: 8.0),
              if (showOrganizer && organizerName != null) _OrganizerInfo(name: organizerName!),
            ],
          ),
        ),
      ],
    );
  }
}

class EventTitle extends StatelessWidget {
  final String title;
  final bool compact;

  const EventTitle({super.key, required this.title, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: compact ? 16.0 : 18.0, fontWeight: FontWeight.bold),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class EventDescription extends StatelessWidget {
  final String description;

  const EventDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: const TextStyle(fontSize: 14.0),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _OrganizerInfo extends StatelessWidget {
  final String name;

  const _OrganizerInfo({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Organizador: $name',
      style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
    );
  }
}

class EventDateTimeInfo extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;

  const EventDateTimeInfo({super.key, required this.startTime, required this.endTime});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16.0),
        const SizedBox(width: 4.0),
        Text(
          DateTimeFmt.date(startTime),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 14.0),
        ),
        const SizedBox(width: 16.0),
        const Icon(Icons.access_time, size: 16.0),
        const SizedBox(width: 4.0),
        Text(
          DateTimeFmt.timeRange(startTime, endTime),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 14.0),
        ),
      ],
    );
  }
}

class _EventLocationInfo extends StatelessWidget {
  final String? location;

  const _EventLocationInfo({this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16.0),
        const SizedBox(width: 4.0),
        Expanded(
          child: Text(
            location ?? 'Sin ubicación',
            style: const TextStyle(fontSize: 14.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EventTimeBadge extends StatelessWidget {
  final Event event;

  const _EventTimeBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    final now = DateTime.now();

    if (event.status == EventStatus.cancelled) {
      text = 'Cancelado';
      color = AppColors.errorColor;
    } else if (now.isBefore(event.startTime)) {
      text = 'Inicia ${DateTimeFmt.getTimeUntil(event.startTime)}';
      color = AppColors.infoColor;
    } else if (now.isAfter(event.startTime) && now.isBefore(event.endTime)) {
      text = 'En curso';
      color = AppColors.successColor;
    } else {
      text = 'Finalizado';
      color = AppColors.finishColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final List<Widget> actions;

  const _ActionButtons({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: actions);
  }
}
