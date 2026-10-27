import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'games_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onTabChange: _onTabTapped),
      LearnScreen(isActive: _currentIndex == 1),
      const GamesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_rounded),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
