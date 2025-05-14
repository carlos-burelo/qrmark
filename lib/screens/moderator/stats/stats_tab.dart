import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';

class ModeratorStatsTab extends ScreenWithState {
  final IconData icon = LucideIcons.chartArea;
  final String label = 'Estadísticas';
  final String path = '/moderator/stats';

  const ModeratorStatsTab({super.key});

  @override
  State<ModeratorStatsTab> createState() => AttendeeEventsScreenState();
}

class AttendeeEventsScreenState extends State<ModeratorStatsTab> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Eventos'),
      body: Center(
        child: Col(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LucideIconWidget(icon: LucideIcons.chartArea, size: 64),
            Text('Características estadísticas en desarrollo...'),
          ],
        ),
      ),
    );
  }
}
