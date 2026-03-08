import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Commons/Widgets/DesignSystem/DSColors.dart';
import 'Sources/PreferencesManager.dart';
import 'Scenes/Splash/SplashPage.dart';
import 'Scenes/Login/LoginPage.dart';
import 'Scenes/DashboardTenant/DashboardTenantPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferencesManager.instance.init();
  runApp(const SaasManApp());
}

class SaasManApp extends StatelessWidget {
  const SaasManApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    return MaterialApp(
      title: 'SaaS CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colors.primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: colors.scaffoldBackground,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardTenantPage(),
      },
    );
  }
}
