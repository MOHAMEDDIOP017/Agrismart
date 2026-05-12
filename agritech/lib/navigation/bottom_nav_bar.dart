import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import 'app_router.dart';

/// Scaffold principal avec BottomNavigationBar 5 onglets
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.terrain_outlined),
      activeIcon: Icon(Icons.terrain),
      label: 'Champs',
    ),
    // Onglet 2 — Module Détection IA
    BottomNavigationBarItem(
      icon: Icon(Icons.document_scanner_outlined),
      activeIcon: Icon(Icons.document_scanner),
      label: 'Détection',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Alertes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          items: _items,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
        ),
      ),
    );
  }
}

/// Extensions de navigation vers les routes principales
extension NavigationExt on BuildContext {
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToChamps() => go(AppRoutes.champs);
  void goToDetection() => go(AppRoutes.detection);
  void goToAlertes() => go(AppRoutes.alertes);
  void goToProfil() => go(AppRoutes.profil);
  void goToLogin() => go(AppRoutes.login);
}
