import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/widgets.dart';
import 'admin_router.dart';

/// Coquille de navigation de l'administrateur.
///
/// Le découpage en quatre onglets convenait déjà. Deux choses changent.
///
/// La barre est la même que celle des deux autres rôles. L'administration
/// utilisait `NavigationBar` de Material 3 quand l'agriculteur et l'expert
/// utilisaient `BottomNavigationBar`, avec deux rendus différents de l'onglet
/// actif dans la même application.
///
/// « Tableau de bord » devient « Accueil ». Le libellé le plus long tenait à
/// peine à 360 dp, et débordait dès que l'utilisateur agrandissait la taille
/// de texte de son téléphone.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    DestinationNavigation(
      libelle: 'Accueil',
      icone: Icons.dashboard_outlined,
      iconeActive: Icons.dashboard_rounded,
      etiquette: 'Tableau de bord',
    ),
    DestinationNavigation(
      libelle: 'Comptes',
      icone: Icons.people_outline,
      iconeActive: Icons.people_rounded,
      etiquette: 'Gestion des utilisateurs',
    ),
    DestinationNavigation(
      libelle: 'Experts',
      icone: Icons.assignment_ind_outlined,
      iconeActive: Icons.assignment_ind,
      etiquette: 'Assignation des experts',
    ),
    DestinationNavigation(
      libelle: 'Chiffres',
      icone: Icons.bar_chart_outlined,
      iconeActive: Icons.bar_chart_rounded,
      etiquette: 'Statistiques',
    ),
  ];

  void _ouvrir(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BandeauHorsConnexion(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BarreNavigation(
        destinations: _destinations,
        indexActif: navigationShell.currentIndex,
        onChange: _ouvrir,
      ),
    );
  }
}

/// Raccourcis de navigation du module Administrateur.
extension AdminNavigationExt on BuildContext {
  void goToAdminAccueil() => go(AdminRoutes.adminDashboard);
  void goToAdminUtilisateurs() => go(AdminRoutes.adminUtilisateurs);
  void goToAdminAssignation() => go(AdminRoutes.adminAssignation);
  void goToAdminStatistiques() => go(AdminRoutes.adminStatistiques);
}
