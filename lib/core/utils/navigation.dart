import 'package:flutter/material.dart';

class Navigate {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<Object?> to(String routeName, {Object? arguments}) async {
    return await navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void back<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }

  static Future<Object?> replace(String routeName, {Object? arguments}) async {
    return await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<Object?> replaceTop(String routeName, {Object? arguments}) async {
    return await navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<Object?> backTo(String routeName, {Object? arguments}) async {
    return await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static bool get canGoBack =>
      navigatorKey.currentState != null && navigatorKey.currentState!.canPop();
}
