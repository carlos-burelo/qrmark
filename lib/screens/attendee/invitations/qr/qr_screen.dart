import 'package:flutter/material.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/qr_display.dart';
import 'package:qrmark/core/widgets/scaffold.dart';

class AttendeeQRScreen extends StatefulWidget {
  static const String path = '/attendee/invitations/qr';

  final int eventId;

  @override
  AttendeeQRScreenState createState() => AttendeeQRScreenState();

  const AttendeeQRScreen({super.key, required this.eventId});
}

class AttendeeQRScreenState extends State<AttendeeQRScreen> {
  Future<String> generateQRCode() async {
    final token = await service.attendance.generateCheckinQR(widget.eventId);
    return token;
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBar(title: Text('Ticket de entrada')),
      body: Async(
        wait: generateQRCode,
        builder: (ctx, data) {
          return Center(child: QRDisplay(data: data));
        },
      ),
    );
  }
}
