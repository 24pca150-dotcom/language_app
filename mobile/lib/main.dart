import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await AuthService.isLoggedIn();
  runApp(LangNestMobileApp(initialLoggedIn: loggedIn));
}

class LangNestMobileApp extends StatelessWidget {
  final bool initialLoggedIn;

  const LangNestMobileApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LangNest Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
