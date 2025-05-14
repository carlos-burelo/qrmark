import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qrmark/core/config/theme.dart';

class QRDisplay extends StatelessWidget {
  final String data;
  final String image;

  const QRDisplay({super.key, required this.data, this.image = 'assets/cheems.webp'});

  @override
  Widget build(BuildContext context) {
    return PrettyQrView.data(
      data: data,
      decoration: PrettyQrDecoration(
        shape: const PrettyQrSmoothSymbol(color: AppColors.foregroundColor),
        image: PrettyQrDecorationImage(
          colorFilter: ColorFilter.mode(AppColors.foregroundColor, BlendMode.srcATop),
          image: AssetImage(image),
        ),
      ),
    );
  }
}
