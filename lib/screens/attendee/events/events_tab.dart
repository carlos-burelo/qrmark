import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/event_card.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';

class AttendeeEventsTab extends ScreenWithState {
  final IconData icon = LucideIcons.calendarRange;
  final String label = 'Eventos';
  final String path = '/attendee/events';

  const AttendeeEventsTab({super.key});

  @override
  State<AttendeeEventsTab> createState() => AttendeeEventsScreenState();
}

class AttendeeEventsScreenState extends State<AttendeeEventsTab> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Eventos'),
      body: SearchableAsyncList(
        enablePullToRefresh: true,
        enableSearch: true,
        wait: service.event.getUpcomingEvents,
        builder: (context, event, index) {
          return EventCard(event: event, onTap: () {});
        },
      ),
    );
  }
}
