import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/utils/date.dart';

class EventMainInfo extends StatelessWidget {
  final Event event;

  const EventMainInfo({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InfoRow(
              icon: LucideIcons.flag,
              label: "Estado del evento",
              value: event.status.displayName,
            ),
            const SizedBox(height: 16.0),

            InfoRow(
              icon: LucideIcons.calendarFold,
              label: 'Fecha',
              value: DateTimeFmt.date(event.startTime),
            ),
            const SizedBox(height: 16.0),

            InfoRow(
              icon: LucideIcons.clock,
              label: 'Hora',
              value: DateTimeFmt.timeRange(event.startTime, event.endTime),
            ),
            const SizedBox(height: 16.0),

            InfoRow(
              icon: LucideIcons.mapPin,
              label: 'Ubicación',
              value: event.location?.name ?? 'No especificada',
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24.0),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14.0)),
              const SizedBox(height: 4.0),
              Text(value, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
