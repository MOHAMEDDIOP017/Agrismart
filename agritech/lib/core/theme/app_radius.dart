import 'package:flutter/widgets.dart';

/// Rayons d'arrondi d'AgriSmart.
///
/// L'audit avait relevé 14 valeurs distinctes, de 2 à 50. Trois suffisent, et
/// chacune porte un sens : plus l'élément invite à l'action, plus il est
/// arrondi. Un champ reste anguleux parce qu'il contient, un bouton est
/// franchement arrondi parce qu'il se touche.
class AppRayons {
  AppRayons._();

  /// 8 — champs de saisie, listes déroulantes, cases à cocher.
  static const double champ = 8;

  /// 12 — cartes, panneaux, feuilles modales.
  static const double carte = 12;

  /// 24 — boutons principaux et secondaires.
  static const double bouton = 24;

  /// Arrondi complet, pour les pastilles et les avatars. La valeur est très
  /// supérieure à toute hauteur réelle, ce qui produit une capsule quelle que
  /// soit la taille du texte, y compris à 130 %.
  static const double pastille = 999;

  static const BorderRadius brChamp = BorderRadius.all(Radius.circular(champ));
  static const BorderRadius brCarte = BorderRadius.all(Radius.circular(carte));
  static const BorderRadius brBouton =
      BorderRadius.all(Radius.circular(bouton));
  static const BorderRadius brPastille =
      BorderRadius.all(Radius.circular(pastille));

  /// Haut arrondi seulement, pour une feuille qui monte depuis le bas.
  static const BorderRadius brFeuille = BorderRadius.vertical(
    top: Radius.circular(carte),
  );
}
