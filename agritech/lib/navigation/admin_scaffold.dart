import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
/// Scaffold principal du module Administrateur avec BottomNavigationBar (4 onglets)
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: Colors.white,
        indicatorColor: _adminPrimary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _adminPrimary),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: _adminPrimary),
            label: 'Utilisateurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined),
            selectedIcon: Icon(Icons.assignment_ind, color: _adminPrimary),
            label: 'Assignation',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: _adminPrimary),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
