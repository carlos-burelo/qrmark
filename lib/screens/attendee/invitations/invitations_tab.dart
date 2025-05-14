import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/invitation.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/invitation_card.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/attendee/invitations/details/invitation_details.dart';

class AttendeeInvitationsTab extends ScreenWithState {
  final IconData icon = LucideIcons.mailOpen;
  final String label = 'Invitaciones';
  final String path = '/attendee/invitations';

  const AttendeeInvitationsTab({super.key});

  @override
  State<AttendeeInvitationsTab> createState() => AttendeeInvitationsScreenState();
}

class AttendeeInvitationsScreenState extends State<AttendeeInvitationsTab> {
  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Invitaciones'),
      body: SearchableAsyncList<Invitation>(
        enablePullToRefresh: true,
        enableSearch: true,
        wait: service.invitation.getMyInvitations,
        emptyBuilder: const Center(child: Text('No tienes invitaciones pendientes.')),
        builder: (context, invitation, index) {
          return InvitationCard(
            invitation: invitation,
            onTap: () async {
              final result = await Navigate.to(
                AttendeeInvitationDetails.path,
                arguments: {'eventId': invitation.eventId, 'invitationId': invitation.id},
              );
              if (result == true) {
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}
