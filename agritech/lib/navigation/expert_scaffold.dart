import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/expert/presentation/providers/expert_provider.dart';
import '../shared/widgets/widgets.dart';
import 'expert_router.dart';

/// Coquille de navigation de l'expert agronome.
///
/// Quatre onglets : À valider, Champs, Conseils, Profil.
///
/// **La file de validation passe en premier.** Elle était déclarée hors de la
/// coquille : elle n'appartenait à aucun onglet, et l'ouvrir faisait
/// disparaître la barre de navigation. C'est pourtant la tâche première du
/// rôle, et c'était la fonction la moins accessible de l'application. Elle
/// occupe maintenant le premier onglet, celui que l'on atteint sans réfléchir.
///
/// **Le nombre de recommandations en attente est affiché en permanence.** Il
/// était enfermé dans une carte du tableau de bord, qu'il fallait ouvrir pour
/// voir qu'il y avait du travail. En pastille sur l'onglet, il se voit depuis
/// n'importe quel écran du module.
///
/// L'ancien tableau de bord reste accessible en plein écran depuis le profil.
/// Son contenu se résumait à trois indicateurs et aux trois premières
/// parcelles supervisées, que l'onglet Champs montre déjà en entier.
class ExpertScaffold extends ConsumerWidget {
  const ExpertScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _ouvrir(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lecture seule d'un provider existant : la pastille suit le même état que
    // la liste, sans second appel au serveur.
    final enAttente = ref.watch(recommandationsExpertProvider).maybeWhen(
          data: (etat) => etat.nombreEnAttente,
          orElse: () => 0,
        );

    final destinations = [
      DestinationNavigation(
        libelle: 'À valider',
        icone: Icons.fact_check_outlined,
        iconeActive: Icons.fact_check_rounded,
        compteur: enAttente,
        etiquette: 'Recommandations à valider',
      ),
      const DestinationNavigation(
        libelle: 'Champs',
        icone: Icons.terrain_outlined,
        iconeActive: Icons.terrain_rounded,
        etiquette: 'Champs supervisés',
      ),
      const DestinationNavigation(
        libelle: 'Conseils',
        icone: Icons.chat_bubble_outline,
        iconeActive: Icons.chat_bubble_rounded,
      ),
      const DestinationNavigation(
        libelle: 'Profil',
        icone: Icons.person_outline,
        iconeActive: Icons.person_rounded,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          const BandeauHorsConnexion(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BarreNavigation(
        destinations: destinations,
        indexActif: navigationShell.currentIndex,
        onChange: _ouvrir,
      ),
    );
  }
}

/// Raccourcis de navigation du module Expert.
extension ExpertNavigationExt on BuildContext {
  void goToExpertValidation() => go(ExpertRoutes.expertRecommandations);
  void goToExpertChamps() => go(ExpertRoutes.expertChamps);
  void goToExpertConseils() => go(ExpertRoutes.expertConseils);
  void goToExpertProfil() => go(ExpertRoutes.expertProfil);
  void ouvrirTableauDeBordExpert() => push(ExpertRoutes.expertDashboard);
}
