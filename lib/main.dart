import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Commons/Widgets/DesignSystem/DSColors.dart';
import 'Commons/Widgets/DesignSystem/DSTextStyle.dart';
import 'Commons/Widgets/DesignSystem/DSSpacing.dart';
import 'Sources/PreferencesManager.dart';
import 'Scenes/Splash/SplashPage.dart';
import 'Scenes/Login/LoginPage.dart';
import 'Scenes/DashboardTenant/DashboardTenantPage.dart';
import 'Scenes/Products/ProductsListPage.dart';
import 'Scenes/Products/ProductFormPage.dart';

import 'Scenes/Customers/CustomersListPage.dart';
import 'Scenes/Customers/CustomerFormPage.dart';

import 'Scenes/Sales/SalesListPage.dart';
import 'Scenes/Sales/SaleFormPage.dart';
import 'Scenes/Sales/SaleDetailPage.dart';
import 'Scenes/Orders/OrdersKanbanPage.dart';
import 'Scenes/Escalations/EscalationsPage.dart';
import 'Scenes/StockAlerts/StockAlertsPage.dart';
import 'Scenes/DashboardSuperAdmin/SuperAdminDashboardPage.dart';
import 'Scenes/ManageTenants/TenantsListPage.dart';
import 'Scenes/ManageTenants/TenantFormPage.dart';
import 'Scenes/ManageTenants/TenantDetailPage.dart';
import 'Scenes/TenantSettings/TenantSettingsPage.dart';
import 'Scenes/TeamManagement/TeamManagementPage.dart';
import 'Scenes/TeamManagement/AddMemberPage.dart';
import 'Scenes/UpgradePlan/UpgradePlanPage.dart';
import 'Commons/Utils/DSPageRoute.dart';

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
    final textStyles = DSTextStyle();

    return MaterialApp(
      title: 'SaaS CRM',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'DM Sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: colors.primaryColor,
          primary: colors.primaryColor,
          secondary: colors.secundaryColor,
          surface: colors.surfaceColor,
          error: colors.red,
          onPrimary: colors.textOnPrimary,
          onSecondary: colors.textOnSecondary,
          onSurface: colors.textPrimary,
        ),
        scaffoldBackgroundColor: colors.scaffoldBackground,
        dividerColor: colors.divider,
        appBarTheme: AppBarTheme(
          backgroundColor: colors.surfaceColor,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: textStyles.headline3,
        ),
        cardTheme: CardThemeData(
          color: colors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            side: BorderSide(color: colors.divider, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            borderSide: BorderSide(color: colors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            borderSide: BorderSide(color: colors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            borderSide: BorderSide(color: colors.inputBorderFocused, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            borderSide: BorderSide(color: colors.inputError),
          ),
          labelStyle: textStyles.textFieldLabel,
          hintStyle: textStyles.textFieldHint,
          errorStyle: textStyles.textFieldError,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            ),
            textStyle: textStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primaryColor,
            side: BorderSide(color: colors.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            ),
            textStyle: textStyles.button,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          ),
          titleTextStyle: textStyles.headline3,
          contentTextStyle: textStyles.bodyMedium,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colors.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: colors.divider,
          thickness: 1,
          space: 1,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const DashboardTenantPage(),
          '/products': (context) => const ProductsListPage(),
          '/products/new': (context) => const ProductFormPage(),
          '/products/edit': (context) => const ProductFormPage(),
          '/customers': (context) => const CustomersListPage(),
          '/customers/new': (context) => const CustomerFormPage(),
          '/customers/edit': (context) => const CustomerFormPage(),
          '/sales': (context) => const SalesListPage(),
          '/sales/new': (context) => const SaleFormPage(),
          '/sales/detail': (context) => const SaleDetailPage(),
          '/orders': (context) => const OrdersKanbanPage(),
          '/escalations': (context) => const EscalationsPage(),
          '/stock-alerts': (context) => const StockAlertsPage(),
          '/admin/dashboard': (context) => const SuperAdminDashboardPage(),
          '/admin/tenants': (context) => const TenantsListPage(),
          '/admin/tenants/new': (context) => const TenantFormPage(),
          '/admin/tenants/edit': (context) => const TenantFormPage(),
          '/admin/tenants/detail': (context) => const TenantDetailPage(),
          '/settings': (context) => const TenantSettingsPage(),
          '/upgrade': (context) => const UpgradePlanPage(),
          '/team': (context) => const TeamManagementPage(),
          '/team/add': (context) => const AddMemberPage(),
        };
        final builder = routes[settings.name];
        if (builder == null) return null;
        return DSPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
