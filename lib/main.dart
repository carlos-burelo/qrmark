import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/background.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRMark',
      navigatorKey: Navigate.navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      themeMode: ThemeMode.dark,
      theme: AppTheme.build(),
      routes: AppRouter.router(),
      initialRoute: AppRouter.splashPath,
      builder: (BuildContext context, Widget? child) {
        Sonner.initialize(context);
        return Background(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeServices();
  runApp(const App());
}
