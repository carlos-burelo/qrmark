import 'package:flutter/material.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/moderator/events/events_tab.dart';
import 'package:qrmark/screens/moderator/stats/stats_tab.dart';

class ModeratorTabs extends StatelessWidget {
  final String path = '/moderator';

  const ModeratorTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return TabContainer(screens: [ModeratorEventsTab(), ModeratorStatsTab()]);
  }
}
