import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Commons/Widgets/DesignSystem/DSColors.dart';
import 'Sources/PreferencesManager.dart';
import 'Scenes/Splash/SplashPage.dart';
import 'Scenes/Login/LoginPage.dart';
import 'Scenes/DashboardTenant/DashboardTenantPage.dart';
import 'Scenes/Products/ProductsListPage.dart';
import 'Scenes/Products/ProductFormPage.dart';
import 'Scenes/Products/ProductDetailPage.dart';
import 'Scenes/Customers/CustomersListPage.dart';
import 'Scenes/Customers/CustomerFormPage.dart';
import 'Scenes/Customers/CustomerDetailPage.dart';
import 'Scenes/Sales/SalesListPage.dart';
import 'Scenes/Sales/SaleFormPage.dart';
import 'Scenes/Sales/SaleDetailPage.dart';
import 'Scenes/DashboardSuperAdmin/SuperAdminDashboardPage.dart';

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
        '/products': (context) => const ProductsListPage(),
        '/products/new': (context) => const ProductFormPage(),
        '/products/edit': (context) => const ProductFormPage(),
        '/products/detail': (context) => const ProductDetailPage(),
        '/customers': (context) => const CustomersListPage(),
        '/customers/new': (context) => const CustomerFormPage(),
        '/customers/edit': (context) => const CustomerFormPage(),
        '/customers/detail': (context) => const CustomerDetailPage(),
        '/sales': (context) => const SalesListPage(),
        '/sales/new': (context) => const SaleFormPage(),
        '/sales/detail': (context) => const SaleDetailPage(),
        '/admin/dashboard': (context) => const SuperAdminDashboardPage(),
      },
    );
  }
}
