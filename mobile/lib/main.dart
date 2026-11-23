import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.onSessionExpired = () {
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };
  await AppTheme.loadThemePreference();
  final loggedIn = await AuthService.isLoggedIn();
  runApp(LangNestMobileApp(initialLoggedIn: loggedIn));
}

class LangNestMobileApp extends StatefulWidget {
  final bool initialLoggedIn;

  const LangNestMobileApp({super.key, required this.initialLoggedIn});

  @override
  State<LangNestMobileApp> createState() => _LangNestMobileAppState();
}

class _LangNestMobileAppState extends State<LangNestMobileApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.isDarkNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppTheme.isDarkNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    // Screens read AppTheme colors directly (not via Theme.of), so const
    // widgets would not repaint on their own. Mark every element dirty —
    // navigation stack and widget state are preserved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'LangNest Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.currentTheme,
      themeAnimationDuration: Duration.zero,
      home: widget.initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
