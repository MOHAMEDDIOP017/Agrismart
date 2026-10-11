import 'package:flutter/material.dart';

/// Durées d'animation d'AgriSmart.
///
/// Aucune ne dépasse [plafond]. L'audit avait relevé deux dépassements nets :
/// la barre d'aptitude et le cercle de score de la carte de culture
/// s'animaient sur 1 200 ms, et le carrousel du tableau de bord sur 700 ms.
/// Au-delà d'environ 400 ms, une animation cesse d'accompagner le geste et se
/// met à le retarder.
///
/// Le test `test/theme_mouvement_test.dart` vérifie ce plafond à chaque
/// exécution.
class AppDurees {
  AppDurees._();

  /// Plafond que toute animation de l'application doit respecter.
  static const Duration plafond = Duration(milliseconds: 400);

  /// 120 ms — enfoncement d'un bouton sous le doigt. Assez court pour être
  /// perçu comme une réaction et non comme une transition.
  static const Duration appui = Duration(milliseconds: 120);

  /// 200 ms — apparition d'un élément, bascule d'un interrupteur.
  static const Duration courte = Duration(milliseconds: 200);

  /// 260 ms — transition entre deux pages.
  static const Duration page = Duration(milliseconds: 260);

  /// 300 ms — remplissage d'une barre de progression, ouverture d'un panneau.
  static const Duration moyenne = Duration(milliseconds: 300);

  /// 350 ms — transition Hero, qui déplace un élément sur une plus grande
  /// distance et a donc besoin d'un peu plus de temps pour rester lisible.
  static const Duration hero = Duration(milliseconds: 350);

  /// 100 ms — décalage entre deux éléments d'une cascade.
  ///
  /// L'audit avait relevé trois conventions concurrentes : 150 ms sur la carte
  /// de culture, 80 ms sur la liste des champs, et des délais fixes de 300,
  /// 500 puis 700 ms sur le tableau de bord.
  static const Duration cascade = Duration(milliseconds: 100);

  /// Période du cycle de l'indicateur de saisie de l'assistant.
  ///
  /// Comme [squelette], c'est une boucle d'attente et non une transition :
  /// elle n'empêche aucune interaction et n'est donc pas soumise au plafond.
  static const Duration saisie = Duration(milliseconds: 1200);

  /// Période de balayage d'un squelette de chargement. Plus lente que les
  /// autres parce qu'elle se répète : un balayage rapide attire l'œil au lieu
  /// de signaler une attente.
  static const Duration squelette = Duration(milliseconds: 1400);

  /// Toutes les durées de transition déclarées ici, pour le test de plafond.
  /// [squelette] en est exclue : c'est une boucle d'attente, pas une
  /// transition, et elle n'empêche aucune interaction.
  static const List<Duration> transitions = [
    appui,
    courte,
    page,
    moyenne,
    hero,
    cascade,
  ];
}

/// Courbes d'animation d'AgriSmart.
class AppCourbes {
  AppCourbes._();

  /// Courbe par défaut : départ rapide, arrivée amortie. Un élément qui entre
  /// ou une valeur qui se remplit paraissent ainsi arriver à destination
  /// plutôt que s'arrêter net.
  static const Curve sortie = Curves.easeOutCubic;

  /// Pour un élément qui quitte l'écran.
  static const Curve entree = Curves.easeInCubic;

  /// Pour un déplacement qui part et revient dans le champ de vision, comme
  /// une transition Hero.
  static const Curve douce = Curves.easeInOutCubic;
}

/// Arbitrage des animations selon le réglage d'accessibilité du téléphone.
///
/// Android et iOS exposent une préférence de réduction des animations, que
/// Flutter relaie par `MediaQuery.disableAnimations`. L'audit n'en avait
/// trouvé aucune utilisation : le réglage était sans effet dans
/// l'application.
///
/// Toute animation non essentielle passe par [duree] ou [decalage]. Quand la
/// réduction est active, la durée renvoyée est nulle : l'élément atteint
/// directement son état final, sans disparaître ni changer de place. Rien
/// n'est perdu, seul le mouvement l'est.
///
/// Les animations qui portent une information restent actives, car les
/// supprimer retirerait du sens. L'indicateur de saisie de l'assistant en est
/// un exemple : il dit que l'agent est en train de répondre.
class AppMouvement {
  AppMouvement._();

  /// Vrai quand l'utilisateur a demandé moins d'animations.
  static bool reduit(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Durée à appliquer pour une animation décorative.
  static Duration duree(BuildContext context, Duration voulue) =>
      reduit(context) ? Duration.zero : voulue;

  /// Délai d'un élément de rang [index] dans une cascade.
  ///
  /// Le décalage est plafonné à [rangMax] : sur une liste de trente champs,
  /// une cascade non bornée ferait attendre le dernier élément trois secondes.
  /// Au-delà du sixième rang, les éléments apparaissent donc ensemble, ce qui
  /// est sans conséquence puisqu'ils sont hors de l'écran.
  static Duration decalage(
    BuildContext context,
    int index, {
    int rangMax = 6,
    Duration pas = AppDurees.cascade,
  }) {
    if (reduit(context)) return Duration.zero;
    final rang = index.clamp(0, rangMax);
    return pas * rang;
  }

  /// Courbe à appliquer, neutralisée quand la réduction est active pour éviter
  /// qu'un `AnimatedContainer` de durée nulle ne sursaute.
  static Curve courbe(BuildContext context,
          [Curve voulue = AppCourbes.sortie]) =>
      reduit(context) ? Curves.linear : voulue;
}
