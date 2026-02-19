// =============================================
// MAIN APP ENTRY POINT
// Waste Management System - Ghana
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/collector/collector_home_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const WasteManagementApp());
}

class WasteManagementApp extends StatelessWidget {
  const WasteManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Waste Management Ghana',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.green,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.light(
            primary: AppColors.green,
            secondary: AppColors.gold,
            error: AppColors.red,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              textStyle: AppTextStyles.button,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.green, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              borderSide: const BorderSide(color: AppColors.red),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated) {
      final role = authProvider.userRole;
      if (role == UserRole.client) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        );
      } else if (role == UserRole.collector) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CollectorHomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.recycling,
              size: 100,
              color: AppColors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Waste Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ghana 🇬🇭',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
