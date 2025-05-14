import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/models/invitation.dart';
import 'package:qrmark/core/utils/date.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/badge.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/attendee/invitations/details/widgets/event_main_info.dart';
import 'package:qrmark/screens/attendee/invitations/qr/qr_screen.dart';

class AttendeeInvitationDetails extends StatefulWidget {
  static const String path = '/attendee/invitations/details';
  final int invitationId;
  final int eventId;
  const AttendeeInvitationDetails({super.key, required this.eventId, required this.invitationId});
  @override
  State<AttendeeInvitationDetails> createState() => _AttendeeInvitationDetailsState();
}

class _AttendeeInvitationDetailsState extends State<AttendeeInvitationDetails> {
  // ignore: avoid_init_to_null
  Invitation? invitation = null;

  Future<Map<String, dynamic>> _loadEventDetails() async {
    final eventPromise = service.event.getEventById(widget.eventId);
    final invitationPromise = service.invitation.getInvitationById(widget.invitationId);
    return await Future.wait([eventPromise, invitationPromise]).then((value) {
      setState(() {
        invitation = value[1] as Invitation;
      });
      return {'event': value[0], 'invitation': invitation};
    });
  }

  Future<void> _acceptInvitation() async {
    if (invitation == null) return;
    final response = await service.invitation.acceptInvitation(invitation!.id);
    if (!response) {
      Sonner.error('Error al aceptar la invitación');
      return;
    }
    Sonner.success('La invitacion ha sido aceptada correctamente');
    Navigate.to(AttendeeQRScreen.path, arguments: {'eventId': widget.eventId});
  }

  Future<void> _rejectInvitation() async {
    if (invitation == null) return;
    final response = await service.invitation.declineInvitation(invitation!.id);
    if (!response) {
      Sonner.error('Error al rechazar la invitación');
      return;
    }
    Sonner.success('La invitacion ha sido rechazada correctamente');
    Navigate.back(true);
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBar(title: const Text('Detalles de la invitación')),
      body: Async(
        wait: _loadEventDetails,
        builder: (ctx, data) {
          final event = data['event'] as Event;
          final invitation = data['invitation'] as Invitation;
          return Col(
            children: [
              Row(
                children: [
                  StatusBadge(status: invitation.status.displayName, color: AppColors.warningColor),
                  const Spacer(),
                  Text(DateTimeFmt.date(event.startTime), style: const TextStyle(fontSize: 14.0)),
                ],
              ),
              Text(
                event.title,
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),

              Text(event.description, style: const TextStyle(fontSize: 16.0)),
              AttendeEventMainInfo(event: event),
            ],
          );
        },
      ),
      bottomNavigationBar:
          invitation?.status == InvitationStatus.accepted
              ? ElevatedButton.icon(
                onPressed: () {
                  Navigate.to(AttendeeQRScreen.path, arguments: {'eventId': widget.eventId});
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Ver QR'),
              )
              : Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
                        onPressed:
                            invitation?.status != InvitationStatus.pending
                                ? null
                                : _rejectInvitation,
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10, right: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.successColor),
                        onPressed:
                            invitation?.status != InvitationStatus.pending
                                ? null
                                : _acceptInvitation,
                        child: const Text('Aceptar'),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
