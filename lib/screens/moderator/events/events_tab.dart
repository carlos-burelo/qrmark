import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/event_card.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/moderator/events/scan/scan_qr.dart';

class ModeratorEventsTab extends ScreenWithState {
  final IconData icon = LucideIcons.calendarRange;
  final String label = 'Eventos';
  final String path = '/moderator/events';

  const ModeratorEventsTab({super.key});

  @override
  State<ModeratorEventsTab> createState() => AttendeeEventsScreenState();
}

class AttendeeEventsScreenState extends State<ModeratorEventsTab> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Eventos'),
      body: SearchableAsyncList(
        enablePullToRefresh: true,
        enableSearch: true,
        wait: () => service.event.getUserEvents(),
        builder: (context, event, index) {
          return EventCard(
            event: event,
            onTap: () {
              Navigate.to(ModeratorScanQrScreen.path, arguments: {'eventId': event.id});
            },
          );
        },
      ),
    );
  }
}
