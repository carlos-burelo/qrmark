import 'package:flutter/material.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/screens/router.dart';

class SplashScreen extends StatefulWidget {
  static const String path = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isLoggedIn = await service.auth.isLoggedIn();

    if (isLoggedIn) {
      final userRole = await service.auth.getCurrentUserRole();

      if (userRole != null) {
        final initialRoute = AppRouter.getRouter(userRole);
        Navigate.replace(initialRoute, arguments: null);
      } else {
        Navigate.replace(AppRouter.loginPath, arguments: null);
      }
    } else {
      Navigate.replace(AppRouter.loginPath, arguments: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner tu logo o un indicador de carga
            Image.asset('assets/logo.png', width: 150, height: 150),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
