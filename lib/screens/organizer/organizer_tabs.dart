import 'package:flutter/material.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/organizer/distribution_list/distribution_list_tab.dart';
import 'package:qrmark/screens/organizer/events/events_tab.dart';
import 'package:qrmark/screens/organizer/invitations/invitations_tab.dart';
import 'package:qrmark/screens/organizer/moderators/moderator_tab.dart';

class OrganizerTabs extends StatelessWidget {
  final String path = '/organizer';

  const OrganizerTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return TabContainer(
      screens: [
        OrganizerEventsTab(),
        OrganizerModeratorsTab(),
        OrganizerInvitationsTab(),
        OrganizerDistributionListTab(),
      ],
    );
  }
}
