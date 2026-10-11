import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_motion.dart';

/// Transitions de pages de l'application.
///
/// Deux mouvements, et chacun dit quelque chose de différent.
///
/// Le **glissement latéral** sert à descendre d'un niveau : ouvrir une
/// parcelle depuis la liste, une recommandation depuis la file. La page arrive
/// par la droite, ce qui annonce que le bouton retour la fera repartir par où
/// elle est venue.
///
/// Le **fondu** sert aux changements qui ne sont pas une descente : passer
/// d'un onglet à l'autre, ou remplacer l'écran d'accueil par la connexion. Il
/// n'y a rien à remonter, donc aucune direction à suggérer.
///
/// L'audit avait trouvé un fondu de 300 ms appliqué partout, y compris à la
/// navigation en profondeur, qui perdait ainsi le seul indice disant qu'on
/// s'enfonçait dans l'application.
///
/// Quand la réduction des animations est active, les deux transitions
/// deviennent instantanées.
CustomTransitionPage<void> pageFondu(GoRouterState etat, Widget enfant) {
  return CustomTransitionPage<void>(
    key: etat.pageKey,
    child: enfant,
    transitionDuration: AppDurees.page,
    reverseTransitionDuration: AppDurees.page,
    transitionsBuilder: (context, animation, _, enfant) {
      if (AppMouvement.reduit(context)) return enfant;
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCourbes.sortie),
        child: enfant,
      );
    },
  );
}

CustomTransitionPage<void> pageGlissement(GoRouterState etat, Widget enfant) {
  return CustomTransitionPage<void>(
    key: etat.pageKey,
    child: enfant,
    transitionDuration: AppDurees.page,
    reverseTransitionDuration: AppDurees.page,
    transitionsBuilder: (context, animation, _, enfant) {
      if (AppMouvement.reduit(context)) return enfant;

      // Le glissement est court, d'un quart de largeur et non d'une largeur
      // entière : la page paraît arriver plutôt que défiler, ce qui tient dans
      // le budget de 260 ms sans donner une impression de lenteur.
      final glissement = Tween<Offset>(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: AppCourbes.sortie),
      );

      return SlideTransition(
        position: glissement,
        child: FadeTransition(opacity: animation, child: enfant),
      );
    },
  );
}

/// Empile les onglets et passe de l'un à l'autre en fondu.
///
/// Remplace l'`IndexedStack` de `StatefulShellRoute.indexedStack`, qui bascule
/// d'un onglet à l'autre sans transition. Tous les onglets restent construits,
/// donc chacun garde sa position de défilement et ses données.
///
/// Les onglets masqués sont rendus insensibles au toucher et leurs animations
/// sont suspendues : sans cela, un indicateur de chargement continuerait de
/// tourner dans un onglet invisible, pour rien.
class ConteneurOnglets extends StatelessWidget {
  const ConteneurOnglets({
    super.key,
    required this.navigationShell,
    required this.onglets,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> onglets;

  @override
  Widget build(BuildContext context) {
    final duree = AppMouvement.duree(context, AppDurees.courte);

    return Stack(
      children: [
        for (var i = 0; i < onglets.length; i++)
          _Onglet(
            actif: i == navigationShell.currentIndex,
            duree: duree,
            child: onglets[i],
          ),
      ],
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.actif,
    required this.duree,
    required this.child,
  });

  final bool actif;
  final Duration duree;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: actif ? 1 : 0,
      duration: duree,
      curve: AppCourbes.sortie,
      child: IgnorePointer(
        ignoring: !actif,
        child: TickerMode(
          enabled: actif,
          child: child,
        ),
      ),
    );
  }
}
