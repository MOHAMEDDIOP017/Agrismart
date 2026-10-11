import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/widgets.dart';
import 'app_router.dart';

/// Coquille de navigation de l'agriculteur.
///
/// Quatre onglets : Accueil, Champs, Assistant, Profil.
///
/// Deux changements par rapport à la version précédente, et chacun répond à un
/// constat de l'audit.
///
/// **L'assistant entre dans la barre.** Il vivait à `/home/dashboard/assistant`,
/// deux niveaux sous l'accueil, et ne s'atteignait que par une carte placée en
/// bas du tableau de bord, après le carrousel, les statistiques, la dernière
/// recommandation, trois cartes de fonctionnalités et une autre carte d'accès
/// rapide. C'est pourtant la fonction qui demande le moins de lecture et qui
/// accepte le wolof : elle devait être à un geste.
///
/// **Les alertes quittent la barre pour la cloche.** L'onglet « Alertes » et
/// l'icône de notification de l'accueil interrogeaient le même point d'entrée
/// du serveur, `/notifications/utilisateur/{id}`, avec les mêmes paramètres.
/// Un onglet sur quatre était donc occupé par le double de la cloche. Les
/// alertes restent accessibles en plein écran, depuis la cloche de l'accueil,
/// et leur place sert maintenant à l'assistant.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Les libellés sont courts à dessein : à 360 dp et quatre onglets, chacun
  /// dispose d'environ 80 points, et devra encore tenir une fois traduit.
  static const _destinations = [
    DestinationNavigation(
      libelle: 'Accueil',
      icone: Icons.home_outlined,
      iconeActive: Icons.home_rounded,
    ),
    DestinationNavigation(
      libelle: 'Champs',
      icone: Icons.terrain_outlined,
      iconeActive: Icons.terrain_rounded,
      etiquette: 'Mes champs',
    ),
    DestinationNavigation(
      libelle: 'Assistant',
      icone: Icons.forum_outlined,
      iconeActive: Icons.forum_rounded,
      etiquette: 'Assistant AgriSmart',
    ),
    DestinationNavigation(
      libelle: 'Profil',
      icone: Icons.person_outline,
      iconeActive: Icons.person_rounded,
    ),
  ];

  void _ouvrir(int index) {
    navigationShell.goBranch(
      index,
      // Appuyer sur l'onglet déjà ouvert ramène à sa racine. C'est la sortie
      // de secours quand on s'est perdu dans une sous-page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Le bandeau est posé dans le corps et non en haut du Scaffold :
          // ainsi il se glisse sous la barre de titre de chaque onglet, au
          // lieu de recouvrir la zone système.
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

/// Raccourcis de navigation vers les écrans principaux.
extension NavigationExt on BuildContext {
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToChamps() => go(AppRoutes.champs);
  void goToAssistant() => go(AppRoutes.assistant);
  void goToProfil() => go(AppRoutes.profil);
  void goToLogin() => go(AppRoutes.login);

  /// Les alertes ne sont plus un onglet : elles s'empilent par-dessus l'écran
  /// courant, et le bouton retour y ramène.
  void ouvrirAlertes() => push(AppRoutes.alertes);
}
