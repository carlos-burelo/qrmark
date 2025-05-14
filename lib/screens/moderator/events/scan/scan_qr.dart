import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:sound_library/sound_library.dart';

class ModeratorScanQrScreen extends StatefulWidget {
  static const String path = '/moderator/event/scan';

  final int eventId;

  @override
  ModeratorScanQrScreenState createState() => ModeratorScanQrScreenState();

  const ModeratorScanQrScreen({super.key, required this.eventId});
}

class ModeratorScanQrScreenState extends State<ModeratorScanQrScreen> {
  Future<Event> generateQRCode() async {
    final event = await service.event.getEventById(widget.eventId);
    return event;
  }

  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: true,
    cameraResolution: Size(1000, 1000),
    useNewCameraSelector: true,
    detectionTimeoutMs: 1000,
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Barcode? _barcode = null;

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        SoundPlayer.playFromAssetPath('assets/check.wav', volume: 1);
        Sonner.info('Asistencia confirmada!');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBar(title: Text('Escanear QR')),
      body: Async(
        wait: generateQRCode,
        builder: (ctx, event) {
          return Col(
            children: [
              SizedBox(
                height: 400,
                width: double.infinity,
                child: MobileScanner(
                  placeholderBuilder:
                      (context, cameraController) =>
                          const Center(child: CircularProgressIndicator()),
                  controller: cameraController,
                  onDetect: _handleBarcode,
                ),
              ),
              Text(event.title, style: AppTheme.titleStyle),
              const SizedBox(height: 20),
              Text(
                'Escanea el código QR del asistente para verificar su asistencia.',
                style: AppTheme.contentStyle,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
