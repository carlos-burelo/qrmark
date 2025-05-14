import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';

Future<bool?> showConfirm(
  BuildContext ctx, {
  String title = 'Confirmar',
  String content = '¿Estás seguro de continuar?',
  String cancelText = 'Cancelar',
  String confirmText = 'Confirmar',
}) async {
  return await showDialog<bool>(
    context: ctx,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(confirmText),
            ),
          ],
        ),
  );
}
