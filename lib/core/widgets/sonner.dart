import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';

enum SonnerType { success, info, warning, error }

class Sonner {
  static final Sonner _instance = Sonner._internal();
  static BuildContext? _ctx;

  factory Sonner() => _instance;

  Sonner._internal();

  static void initialize(BuildContext context) {
    _ctx = context;
  }

  static void updateContext(BuildContext context) {
    _ctx = context;
  }

  static const Duration defaultDuration = Duration(seconds: 3);

  static void success(String message, {Duration? duration = defaultDuration}) {
    _show(type: SonnerType.success, title: "Success", message: message, duration: duration);
  }

  static void error(String message, {Duration? duration = defaultDuration}) {
    _show(type: SonnerType.error, title: "Error", message: message, duration: duration);
  }

  static void warning(String message, {Duration? duration = defaultDuration}) {
    _show(type: SonnerType.warning, title: "Warning", message: message, duration: duration);
  }

  static void info(String message, {Duration? duration = defaultDuration}) {
    _show(type: SonnerType.info, title: "Info", message: message, duration: duration);
  }

  static void _show({
    required SonnerType type,
    required String title,
    required String message,
    Duration? duration,
  }) {
    if (_ctx == null) {
      throw Exception(
        'Sonner context is not initialized. Please call Sonner.initialize(context) in your main method.',
      );
    }

    ScaffoldMessenger.of(_ctx!).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message.replaceFirst('Exception:', '')),
        duration: duration ?? defaultDuration,
        backgroundColor: _getColor(type),
        showCloseIcon: true,
        closeIconColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      ),
    );
  }

  static Color _getColor(SonnerType type) {
    switch (type) {
      case SonnerType.success:
        return AppColors.successColor;
      case SonnerType.info:
        return AppColors.infoColor;
      case SonnerType.warning:
        return AppColors.warningColor;
      case SonnerType.error:
        return AppColors.errorColor;
    }
  }

  static void dispose() {
    _ctx = null;
  }
}
