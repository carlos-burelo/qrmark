import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';

class OrganizerInvitationsTab extends ScreenWithState {
  final IconData icon = LucideIcons.mailOpen;
  final String label = 'Invitaciones';
  final String path = '/organizer/invitations';

  const OrganizerInvitationsTab({super.key});

  @override
  State<OrganizerInvitationsTab> createState() => OrganizerInvitationsScreenState();
}

class OrganizerInvitationsScreenState extends State<OrganizerInvitationsTab> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Invitaciones'),
      body: SearchableAsyncList(
        wait: service.invitation.getMyInvitations,
        enablePullToRefresh: true,
        enableSearch: true,
        emptyBuilder: const Center(child: Text('No tienes invitaciones a eventos')),
        searchFilter: (query, item) {
          final queryLower = query.toLowerCase();
          return item.event!.title.toLowerCase().contains(queryLower);
        },
        builder: (context, item, index) {
          return ListTile(
            title: Text(item.event!.title),
            subtitle: Text(item.event!.formattedDate),
            onTap: () {},
          );
        },
      ),
    );
  }
}
