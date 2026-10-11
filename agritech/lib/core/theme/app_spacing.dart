import 'package:flutter/widgets.dart';

/// Échelle d'espacement d'AgriSmart, sur une base de 4.
///
/// L'audit avait relevé 22 valeurs distinctes de `SizedBox(height:)` et 13
/// d'`EdgeInsets.all`, dont 6, 7, 10 et 14, qui ne sont pas des multiples de
/// 4. Une échelle fermée à sept crans supprime l'arbitrage au cas par cas :
/// quand aucune valeur ne convient, c'est la composition qu'il faut revoir,
/// pas le nombre.
///
/// Les noms sont volontairement courts : ils apparaissent des centaines de
/// fois et doivent rester lisibles au milieu d'un arbre de widgets.
class AppEspaces {
  AppEspaces._();

  /// 4 — écart entre une icône et son libellé, interligne d'une pastille.
  static const double xxs = 4;

  /// 8 — écart entre deux lignes d'une même information.
  static const double xs = 8;

  /// 12 — écart entre deux éléments liés d'un bloc.
  static const double sm = 12;

  /// 16 — marge intérieure d'une carte, gouttière latérale d'un écran.
  static const double md = 16;

  /// 24 — écart entre deux blocs d'un même écran.
  static const double lg = 24;

  /// 32 — écart entre deux sections.
  static const double xl = 32;

  /// 48 — respiration d'un état vide, haut d'un écran d'accueil.
  static const double xxl = 48;

  // ── Compositions prêtes à l'emploi ────────────────────────────────────────

  /// Gouttière latérale d'un écran. 16 de chaque côté : à 360 dp de large, il
  /// reste 328 dp de contenu, assez pour deux colonnes de cartes.
  static const EdgeInsets ecran = EdgeInsets.symmetric(horizontal: md);

  /// Marge intérieure d'une carte.
  static const EdgeInsets carte = EdgeInsets.all(md);

  /// Marge intérieure d'une pastille ou d'un badge.
  static const EdgeInsets pastille =
      EdgeInsets.symmetric(horizontal: sm, vertical: xxs);

  /// Marge d'une liste : gouttière latérale, et un bas assez généreux pour que
  /// le dernier élément ne passe pas sous la barre de navigation ou un bouton
  /// flottant.
  static const EdgeInsets liste = EdgeInsets.fromLTRB(md, xs, md, xxl + md);

  /// Espace vertical entre deux éléments d'une liste.
  static const double entreCartes = sm;
}
