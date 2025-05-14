import 'package:flutter/material.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/attendee/events/events_tab.dart';
import 'package:qrmark/screens/attendee/invitations/invitations_tab.dart';

class AttendeeTabs extends StatelessWidget {
  final String path = '/asistente';

  const AttendeeTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return TabContainer(screens: [AttendeeInvitationsTab(), AttendeeEventsTab()]);
  }
}
