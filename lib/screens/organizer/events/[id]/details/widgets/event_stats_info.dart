import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/models/event.dart';

class StatCard extends StatelessWidget {
  final String title;
  final Color color;
  final String value;

  const StatCard({super.key, required this.title, required this.color, this.value = '0'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.0, color: color),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class EventStatsInfo extends StatelessWidget {
  final Event event;

  const EventStatsInfo({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Asistencias',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatCard(title: 'Total', value: 0.toString(), color: AppColors.primary),
                StatCard(title: 'Check-in', value: 0.toString(), color: AppColors.successColor),
                if (event.requiresCheckout)
                  StatCard(title: 'Check-out', value: 0.toString(), color: AppColors.warningColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
